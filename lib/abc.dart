import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:emailjs/emailjs.dart' as emailjs;
// ignore: depend_on_referenced_packages
import 'package:uuid/uuid.dart'; // Import the uuid package

class PaymentDialog extends StatefulWidget {
  final String packageName;
  final double packagePrice;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String packageDescription;
  final String packageId;
  final String userCode;

  PaymentDialog({
    required this.packageName,
    required this.packagePrice,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.packageDescription,
    required this.packageId,
    required this.userCode,
  });

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  File? _receiptImage;
  final picker = ImagePicker();
  bool _isUploading = false;

  final List<Map<String, String>> accountDetails = [
    {
      'bank': 'MCB',
      'account': 'PK29MUCB0005534 771011569\nM AARIF PETROLEUM SERVICES'
    },
    {
      'bank': 'Allied Bank',
      'account': 'PK57ABPA0010084001250033\nM AARIF PETROLEUM SERVICES'
    },
    {
      'bank': 'Bank of Punjab',
      'account': '6020154943300042\nM AARIF PETROLEUM SERVICES'
    },
    {
      'bank': 'Faysal Bank',
      'account': '3372301000004962\nM AARIF PETROLEUM SERVICES'
    },
  ];

  Future<void> _pickReceiptImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _receiptImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a transaction receipt!')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      var uuid = Uuid();
      String uniquePackageId = uuid.v4();

      int activePackagesCount = await _getActivePackagesCount(widget.userId);
      if (activePackagesCount >= 3) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already have 3 active packages.'),
          ),
        );
        return;
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('payment_receipts')
          .child(
              '${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putFile(_receiptImage!);
      final receiptUrl = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('request-packages').add({
        'userId': widget.userId,
        'packageName': widget.packageName,
        'description': widget.packageDescription,
        'packagePrice': widget.packagePrice,
        'referralCode': widget.userCode,
        'packageId': uniquePackageId,
        'receiptUrl': receiptUrl,
        'requestedAt': FieldValue.serverTimestamp(),
        'isActive': false,
      });

      // Send email notification to admin
      await _sendActivationRequest(
        widget.userEmail,
        widget.userName,
        widget.userPhone,
        widget.userCode,
        widget.packageName,
        widget.packagePrice,
        widget.packageDescription,
      );

      await _showConfirmationDialog(); // Show confirmation dialog
    } catch (error) {
      print('Error uploading receipt or saving data: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error submitting request, please try again!')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<int> _getActivePackagesCount(String userId) async {
    try {
      QuerySnapshot activePackages = await FirebaseFirestore.instance
          .collection('request-packages')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();
      return activePackages.docs.length;
    } catch (error) {
      print('Error fetching active packages count: $error');
      return 0; // Fail-safe: assume no active packages
    }
  }

  Future<void> _sendActivationRequest(
      String email,
      String name,
      String phone,
      String userCode,
      String packageName,
      double packagePrice,
      String packageDescription) async {
    try {
      await emailjs.send(
        'service_aa1lzko',
        'template_90al3xv',
        {
          'to_email': 'maps3333333@gmail.com',
          'user_name': name,
          'user_email': email,
          'user_phone': phone,
          'generatedReferralCode': userCode,
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
      print('Error sending email: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Account Details for Payment',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 10),
            ...accountDetails.map((detail) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail['bank']!,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(detail['account']!,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
            SizedBox(height: 15),
            GestureDetector(
              onTap: _pickReceiptImage,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[100],
                ),
                child: _receiptImage == null
                    ? Center(child: Text('Upload Payment Receipt'))
                    : Image.file(_receiptImage!, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 20),
            _isUploading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitRequest,
                    child: Text('Submit Request'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                      backgroundColor: Colors.green,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _showConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Request Submitted!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.teal,
            ),
          ),
          content: const Text(
            'Thank you for activating your package! Your package will be activated after the admin confirms the payment. This process may take up to 3-4 business days. We appreciate your patience.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
