import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<DocumentSnapshot?> getUserData() async {
    User? user = getCurrentUser();
    if (user != null) {
      return await _firestore.collection('users').doc(user.uid).get();
    }
    return null;
  }

  Future<void> uploadProfileImage(File imageFile) async {
    User? user = getCurrentUser();
    if (user != null) {
      String filePath = 'profile_images/${user.uid}.png';
      await _storage.ref().child(filePath).putFile(imageFile);
      String downloadUrl =
          await _storage.ref().child(filePath).getDownloadURL();

      await _firestore.collection('users').doc(user.uid).update({
        'profileImage': downloadUrl,
      });
    }
  }

// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();

      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      print('User signed out successfully.');
    } catch (e) {
      print('Error during sign-out: $e');
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // String _generateReferralCode() {
  //   final random = Random();
  //   const availableChars = '0123456789';
  //   return List.generate(
  //           6, (index) => availableChars[random.nextInt(availableChars.length)])
  //       .join();
  // }

  Future<bool> isReferralCodeValid(
      String referralCode, String userEmail) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('generatedReferralCode', isEqualTo: referralCode)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false;
      }

      QuerySnapshot userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        var userData = userSnapshot.docs.first.data() as Map<String, dynamic>;

        if (userData['sharedReferralCode'] != null) {
          return false;
        }

        if (userData['generatedReferralCode'] == referralCode) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<User?> signUp(
      String email,
      String password,
      String name,
      String phone,
      String? referralCode,
      String generatedReferralCode,
      bool agreeToTerms) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (referralCode != null && referralCode.isNotEmpty) {
        bool isReferralValid = await isReferralCodeValid(referralCode, email);
        if (!isReferralValid) {
          print('Invalid or already used referral code.');
          return null;
        }
      }

      await _firestore.collection('users').doc(user?.uid).set({
        'uid': user?.uid,
        'email': email,
        'name': name,
        'phone': phone,
        'profileImage': null,
        'sharedReferralCode': referralCode,
        'generatedReferralCode': generatedReferralCode,
        'agreeToTerms': agreeToTerms,
        'createdAt': DateTime.now(),
      });

      return user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        User? user = userCredential.user;

        if (user != null) {
          DocumentSnapshot userDoc =
              await _firestore.collection('users').doc(user.uid).get();

          if (!userDoc.exists) {
            await _firestore.collection('users').doc(user.uid).set({
              'uid': user.uid,
              'email': user.email,
              'name': user.displayName,
              'phone': user.phoneNumber,
              'profileImage': user.photoURL,
              'createdAt': DateTime.now(),
            });
          }
        }
        return user;
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
