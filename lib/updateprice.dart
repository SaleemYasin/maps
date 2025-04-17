import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UpdatePackagePricePage extends StatefulWidget {
  const UpdatePackagePricePage({super.key});

  @override
  State<UpdatePackagePricePage> createState() => _UpdatePackagePricePageState();
}

class _UpdatePackagePricePageState extends State<UpdatePackagePricePage> {
  final CollectionReference _packageCollection =
      FirebaseFirestore.instance.collection('request-packages');

  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Package Prices"),
        centerTitle: true,
        backgroundColor: Colors.tealAccent[100],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch only documents where isActive == true
        stream:
            _packageCollection.where('isActive', isEqualTo: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No active packages available."));
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              // Check for 'activatedAt' presence to avoid null issues
              DateTime activatedAt = data['activatedAt'] != null
                  ? (data['activatedAt'] as Timestamp).toDate()
                  : DateTime.now();
              DateTime expirationDate =
                  activatedAt.add(const Duration(days: 180));
              bool isExpired = DateTime.now().isAfter(expirationDate);

              return FutureBuilder<DocumentSnapshot>(
                future: _usersCollection.doc(data['userId']).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userData =
                      userSnapshot.data?.data() as Map<String, dynamic>?;

                  return Card(
                    color: isExpired ? Colors.grey[300] : Colors.white,
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Package Name: ${data['packageName']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (userData != null) ...[
                            Text("Customer: ${userData['name'] ?? 'N/A'}"),
                            Text("Email: ${userData['email'] ?? 'N/A'}"),
                            Text("Phone: ${userData['phone'] ?? 'N/A'}"),
                          ],
                          const SizedBox(height: 8),
                          Text("Price: Rs. ${data['packagePrice']}"),
                          Text(
                              "Activated At: ${data['activatedAt'] != null ? DateFormat.yMMMd().format(activatedAt) : 'N/A'}"),
                          Text(
                              "Expires At: ${DateFormat.yMMMd().format(expirationDate)}"),
                          const SizedBox(height: 16),
                          isExpired
                              ? const Text(
                                  "Package Expired",
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold),
                                )
                              : ElevatedButton(
                                  onPressed: () {
                                    _showUpdatePriceDialog(
                                        context, doc.id, data['packagePrice']);
                                  },
                                  child: const Text("Update Price"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orangeAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _showUpdatePriceDialog(
      BuildContext context, String packageId, double originalPrice) async {
    double? selectedProfit; // To store the selected profit percentage
    double newPrice = originalPrice; // To store the calculated new price

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Update Package Price"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown to select profit percentage
                  DropdownButton<double>(
                    value: selectedProfit,
                    hint: const Text("Select percentage"),
                    items: [
                      for (var percent = 2; percent <= 12; percent++)
                        percent.toDouble()
                    ]
                        .map((percent) => DropdownMenuItem<double>(
                              value: percent,
                              child: Text("$percent%"),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedProfit = value;
                        newPrice = originalPrice +
                            (originalPrice * selectedProfit! / 100);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Original Price: Rs. ${originalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "New Price: Rs. ${newPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: selectedProfit != null
                      ? () async {
                          // Update package with new profit percentage and total price
                          await _updatePackagePrice(
                            packageId,
                            originalPrice,
                            selectedProfit!,
                            newPrice,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Update successful!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      : null, // Disable button if no profit is selected
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updatePackagePrice(
    String packageId,
    double originalPrice,
    double profitPercentage,
    double newPrice,
  ) async {
    await _packageCollection.doc(packageId).update({
      'originalPackagePrice': originalPrice,
      'profitPercentage': profitPercentage,
      'packagePrice': newPrice,
    });
  }
}
