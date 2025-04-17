// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false; // To toggle between view and edit modes
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  File? _selectedImage;

  // Fetch user data from Firestore
  Future<DocumentSnapshot> getUserData() async {
    var user = auth.currentUser;
    return firestore.collection('users').doc(user!.uid).get();
  }

  // Pick an image from the gallery or camera
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Upload image to Firebase Storage and get URL
  Future<String?> _uploadImage(String userId) async {
    if (_selectedImage == null) return null;

    try {
      final storageRef = storage.ref().child('profile_images/$userId.jpg');
      await storageRef.putFile(_selectedImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.tealAccent[100],
        title: const Text('Profile Page'),
        centerTitle: true, // Center the app bar title
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            var profileImage =
                userData['profileImage'] ?? 'assets/default_avatar.png';

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return RotationTransition(turns: animation, child: child);
                    },
                    child: isEditing
                        ? _buildEditForm(userData, profileImage)
                        : _buildProfileView(userData, profileImage),
                  ),
                ),
              ),
            );
          } else {
            return Center(child: Text('No user data found.'));
          }
        },
      ),
    );
  }

  // Profile view UI
  Widget _buildProfileView(Map<String, dynamic> userData, String profileImage) {
    return Column(
      key: ValueKey(1),
      mainAxisAlignment:
          MainAxisAlignment.center, // Align everything in the center
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: profileImage != null
              ? NetworkImage(profileImage)
              : AssetImage('assets/default_avatar.png') as ImageProvider,
        ),
        SizedBox(height: 20),
        Text(
          userData['name'] ?? 'No Name',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 10),
        Text(
          userData['email'] ?? 'No Email',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 10),
        Text(
          userData['phone'] ?? 'No Phone',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            setState(() {
              isEditing = true; // Switch to edit mode
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            'Edit Profile',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ),
      ],
    );
  }

  // Edit form UI
  Widget _buildEditForm(Map<String, dynamic> userData, String profileImage) {
    final _nameController = TextEditingController(text: userData['name']);
    final _phoneController = TextEditingController(text: userData['phone']);

    return Column(
      key: ValueKey(2),
      mainAxisAlignment:
          MainAxisAlignment.center, // Align everything in the center
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 60,
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : (profileImage != null
                    ? NetworkImage(profileImage)
                    : AssetImage('assets/default_avatar.png')) as ImageProvider,
            child: Icon(Icons.edit, size: 30, color: Colors.white),
          ),
        ),
        SizedBox(height: 20),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(labelText: 'Name'),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(labelText: 'Phone'),
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 30),
        ElevatedButton(
          onPressed: () async {
            String? uploadedImageUrl =
                await _uploadImage(auth.currentUser!.uid);

            // Update Firestore with new values
            await firestore
                .collection('users')
                .doc(auth.currentUser!.uid)
                .update({
              'name': _nameController.text,
              'phone': _phoneController.text,
              if (uploadedImageUrl != null) 'profileImage': uploadedImageUrl,
            });

            setState(() {
              isEditing = false; // Switch back to view mode
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Save Changes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            setState(() {
              isEditing = false; // Cancel editing
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
