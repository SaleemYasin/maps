import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminViewUsersPage extends StatelessWidget {
  const AdminViewUsersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registered Users"),
        backgroundColor: Colors.tealAccent[100],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No registered users found.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          var adminUids = [
            '0gZ4vsfLGrSz9DaW1HAxsFfbCoX2',
            'nu2Vx4dmntU8xKEl9F6lDeJT8072',
          ];

          var users = snapshot.data!.docs.where((doc) {
            return !adminUids.contains(doc.id);
          }).toList();

          if (users.isEmpty) {
            return const Center(
              child: Text(
                "No registered users found.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index].data() as Map<String, dynamic>;
              var profileImage = user['profileImage'] ?? '';
              var name = user['name'] ?? 'N/A';
              var phone = user['phone'] ?? 'N/A';
              var email = user['email'] ?? 'N/A';
              var referralCode = user.containsKey('generatedReferralCode')
                  ? user['generatedReferralCode']
                  : 'N/A';
              var createdAt = user['createdAt'] != null
                  ? (user['createdAt'] as Timestamp).toDate().toString()
                  : 'N/A';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: profileImage.isNotEmpty
                        ? NetworkImage(profileImage)
                        : const AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                    radius: 30,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Phone: $phone"),
                      Text("Email: $email"),
                      Text("Referral Code: $referralCode"),
                      Text("Registered On: $createdAt"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      bool confirmDelete =
                          await _showConfirmationDialog(context);
                      if (confirmDelete) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(users[index].id)
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("User account deleted successfully!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text(
                "Are you sure you want to delete this user account?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }
}
