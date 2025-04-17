import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class YourPackages extends StatelessWidget {
  const YourPackages({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.tealAccent[100],
        title: const Text('Your Packages'),
      ),
      body: FutureBuilder(
        future: _isAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data == true) {
            return _buildAdminPackageList(context);
          } else {
            return _buildUserPackageList();
          }
        },
      ),
    );
  }

  Widget _buildAdminPackageList(BuildContext context) {
    return StreamBuilder(
      stream:
          FirebaseFirestore.instance.collection('request-packages').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var packages = snapshot.data!.docs;
        return ListView.builder(
          itemCount: packages.length,
          itemBuilder: (context, index) {
            var package = packages[index];
            String userId = package['userId'];

            // Fetch user details from the 'users' collection
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                return _buildPackageCard(
                  context,
                  package,
                  isAdmin: true,
                  userName: userData['name'],
                  userEmail: userData['email'],
                  userPhone: userData['phone'],
                  generatedReferralCode: userData['generatedReferralCode'],
                  receiptUrl: package['receiptUrl'],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUserPackageList() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('request-packages')
          .where('userId', isEqualTo: user?.uid)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var packages = snapshot.data!.docs;
        return ListView.builder(
          itemCount: packages.length,
          itemBuilder: (context, index) {
            var package = packages[index];
            return _buildPackageCard(context, package);
          },
        );
      },
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    QueryDocumentSnapshot package, {
    bool isAdmin = false,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? generatedReferralCode,
    String? receiptUrl,
  }) {
    final packageData = package.data() as Map<String, dynamic>;
    final DateTime? requestedAt =
        (packageData['requestedAt'] as Timestamp?)?.toDate();
    final DateTime? activatedAt =
        (packageData['activatedAt'] as Timestamp?)?.toDate();
    final bool isActive = packageData['isActive'] == true;

    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              packageData['packageName'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Price: RS ${packageData['packagePrice']}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Description: ${packageData['description']}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            if (isAdmin) ...[
              Text(
                'Requested by: ${userName ?? 'N/A'}',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              Text(
                'User Email: ${userEmail ?? 'N/A'}',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              Text(
                'User Phone: ${userPhone ?? 'N/A'}',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              Text(
                'Referral Code : ${generatedReferralCode ?? 'N/A'}',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              Text(
                'Requested At: ${requestedAt != null ? requestedAt.toString() : 'N/A'}',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              if (receiptUrl != null) ...[
                const Text(
                  'Payment Receipt:',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: Image.network(receiptUrl),
                      ),
                    );
                  },
                  child: Image.network(
                    receiptUrl,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
            if (!isAdmin && isActive && activatedAt != null) ...[
              Text(
                'Activation : ${activatedAt.toString()}',
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
              CountdownTimer(activatedAt: activatedAt),
            ],
            if (isAdmin) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isActive) ...[
                    ElevatedButton(
                      onPressed: () async {
                        await _activatePackage(package.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: const Text('Activate Package'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        bool confirmDelete = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: const Text(
                                'Are you sure you want to delete this request?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Yes'),
                              ),
                            ],
                          ),
                        );

                        if (confirmDelete == true) {
                          await _deletePackage(package.id);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: const Text(
                        'Delete Request',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _activatePackage(String packageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('request-packages')
          .doc(packageId)
          .update({
        'isActive': true,
        'activatedAt': FieldValue.serverTimestamp(),
      });
      print('Package activated successfully!');
    } catch (error) {
      print('Error activating package: $error');
    }
  }

  Future<void> _deletePackage(String packageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('request-packages')
          .doc(packageId)
          .delete();
      print('Package deleted successfully!');
    } catch (error) {
      print('Error deleting package: $error');
    }
  }
}

Future<bool> _isAdmin() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    List<String> adminUids = [
      '0gZ4vsfLGrSz9DaW1HAxsFfbCoX2',
      'nu2Vx4dmntU8xKEl9F6lDeJT8072',
    ];
    return adminUids.contains(user.uid);
  }
  return false;
}

class CountdownTimer extends StatelessWidget {
  final DateTime activatedAt;

  const CountdownTimer({required this.activatedAt, super.key});

  @override
  Widget build(BuildContext context) {
    DateTime expirationDate = activatedAt.add(const Duration(days: 180));
    Duration remainingTime = expirationDate.difference(DateTime.now());

    if (remainingTime.isNegative) {
      return const Text(
        'Package Expired',
        style: TextStyle(fontSize: 16, color: Colors.red),
      );
    }

    int months = remainingTime.inDays ~/ 30;
    int days = remainingTime.inDays % 30;

    return Text(
      'Time Left: $months months $days days',
      style: const TextStyle(fontSize: 16, color: Colors.orange),
    );
  }
}
