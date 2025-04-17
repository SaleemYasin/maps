// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emailjs/emailjs.dart' as emailjs;
import 'package:khushhali_app/abc.dart';
import 'package:khushhali_app/admin.dart';
import 'package:url_launcher/url_launcher.dart';

class PackageDisplay extends StatelessWidget {
  const PackageDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.tealAccent[100],
        title: const Text('Investment Packages'),
        actions: [
          FutureBuilder(
            future: _isAdmin(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox();
              }
              if (snapshot.data == true) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddPackageForm(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        _showDeleteConfirmationDialog(context);
                      },
                    ),
                  ],
                );
              } else {
                return const SizedBox();
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('packages')
            .orderBy('price') // Sort by price in ascending order (low to high)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var packages = snapshot.data!.docs;
          return ListView.builder(
            itemCount: packages.length + 1, // Add 1 to include the custom card
            itemBuilder: (context, index) {
              if (index < packages.length) {
                var package = packages[index];
                return _buildPackageCard(context, package);
              } else {
                // Add the custom card at the end
                return _buildCustomCard(context);
              }
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Previous Month Packages'),
          content: const Text(
              'Are you sure you want to delete all packages from the previous month? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _deletePreviousMonthPackages();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePreviousMonthPackages() async {
    try {
      DateTime now = DateTime.now();
      DateTime firstDayOfPreviousMonth = DateTime(now.year, now.month - 1, 1);
      DateTime firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);

      QuerySnapshot packages = await FirebaseFirestore.instance
          .collection('packages')
          .where('createdAt', isGreaterThanOrEqualTo: firstDayOfPreviousMonth)
          .where('createdAt', isLessThan: firstDayOfCurrentMonth)
          .get();

      for (var doc in packages.docs) {
        await FirebaseFirestore.instance
            .collection('packages')
            .doc(doc.id)
            .delete();
      }

      print('Previous month packages deleted successfully.');
    } catch (error) {
      print('Error deleting previous month packages: $error');
    }
  }

  Widget _buildCustomCard(BuildContext context) {
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
            const Text(
              "Custom Package Activation",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "If you need to activate a custom package, please contact us.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // WhatsApp Row
                Row(
                  children: [
                    const Text(
                      "WhatsApp: ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Open WhatsApp chat
                        launchUrl(Uri.parse("https://wa.me/923109517640"));
                      },
                      child: const Text(
                        "+92 310 9517640",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                // Email Row
                Row(
                  children: [
                    const Text(
                      "Email: ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Open email client
                        launchUrl(Uri(
                          scheme: 'mailto',
                          path: 'maps3333333@gmail.com',
                        ));
                      },
                      child: const Text(
                        "maps3333333@gmail.com",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(
      BuildContext context, QueryDocumentSnapshot package) {
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
              package['title'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              package['description'],
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Price: \RS ${package['price'].toString()}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .get();
                    final userName = userDoc['name'];
                    final userEmail = userDoc['email'];
                    final userPhone = userDoc['phone'];
                    final userCode = userDoc['generatedReferralCode'];
                    showDialog(
                      // ignore: use_build_context_synchronously
                      context: context,
                      builder: (BuildContext context) {
                        return PaymentDialog(
                          packageName: package['title'],
                          packagePrice: package['price'],
                          packageDescription: package['description'],
                          packageId: package['packageId'],
                          userId: user.uid,
                          userName: userName,
                          userEmail: userEmail,
                          userPhone: userPhone,
                          userCode: userCode,
                        );
                      },
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: const BorderSide(
                    color: Colors.orange,
                    width: 2.0,
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Activate',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPackageActivation(QueryDocumentSnapshot package) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String email = userDoc['email'];
      String name = userDoc['name'];
      String phone = userDoc['phone'];
      String packageName = package['title'];
      String description = package['description'];
      double packagePrice = package['price'];

      await _saveRequestDetails(
          user.uid, email, name, phone, packageName, packagePrice, description);

      await _sendActivationRequest(
          email, name, phone, packageName, packagePrice);
    }
  }

  Future<void> _saveRequestDetails(
      String userId,
      String email,
      String name,
      String phone,
      String packageName,
      double packagePrice,
      String description) async {
    try {
      await FirebaseFirestore.instance.collection('request-packages').add({
        'userId': userId,
        'userName': name,
        'userEmail': email,
        'userPhone': phone,
        'packageName': packageName,
        'packagePrice': packagePrice,
        'description': description, // Add description here
        'isActive': false, // Set isActive to false by default
        'requestedAt': FieldValue.serverTimestamp(),
      });
      print('Request saved successfully in Firestore!');
    } catch (error) {
      print('Error saving request: $error');
    }
  }

  Future<void> _sendActivationRequest(String email, String name, String phone,
      String packageName, double packagePrice) async {
    try {
      await emailjs.send(
        'service_aa1lzko',
        'template_90al3xv',
        {
          'to_email': 'maps3333333@gmail.com',
          'user_name': name,
          'user_email': email,
          'user_phone': phone,
          'package_name': packageName,
          'package_price': packagePrice.toString(),
        },
        const emailjs.Options(
          publicKey: '2MYx4VNNmY8GxfMLp',
          privateKey: 'MWHEJSshurJc1XuiV_0rr',
          limitRate: emailjs.LimitRate(id: 'app', throttle: 10000),
        ),
      );
      print('Email sent successfully!');
    } catch (error) {
      if (error is emailjs.EmailJSResponseStatus) {
        print('ERROR... $error');
      } else {
        print('Error: $error');
      }
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
