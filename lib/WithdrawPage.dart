// ignore: file_names
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:emailjs/emailjs.dart' as emailjs;
import 'package:fluttertoast/fluttertoast.dart';

class WithdrawPage extends StatefulWidget {
  WithdrawPage(String s);

  @override
  // ignore: library_private_types_in_public_api
  _WithdrawPageState createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  late final String userId;
  late List<Map<String, dynamic>> eligiblePackages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userId = currentUser.uid;
      _fetchEligiblePackages();
    } else {
      throw Exception('User not logged in.');
    }
  }

  Future<void> _fetchEligiblePackages() async {
    eligiblePackages = await _getEligiblePackages();
    setState(() {});
  }

  Future<List<Map<String, dynamic>>> _getEligiblePackages() async {
    setState(() {
      isLoading = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('request-packages')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final now = DateTime.now();
      final eligiblePackages = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final activatedAt = (data['activatedAt'] as Timestamp).toDate();
        final packagePrice = data['packagePrice'] ?? 0.0;
        final originalPrice = data['originalPackagePrice'] ?? packagePrice;
        final packageName = data['packageName'] ?? 'Unnamed Package';
        final packageId = doc.id;

        // Calculate available profit (current package price - original price)
        final availableProfit = packagePrice - originalPrice;

        // Check if 6 months have passed for full withdrawal
        final isEligibleForFullWithdrawal =
            now.difference(activatedAt).inDays >= 180;

        // Check withdrawal history for this package
        final withdrawRecords = await FirebaseFirestore.instance
            .collection('withdraw-requests')
            .where('userId', isEqualTo: userId)
            .where('packageId', isEqualTo: packageId)
            .get();

        // Check if user has already withdrawn the available profit
        bool hasWithdrawnProfit = withdrawRecords.docs.any((record) {
          final recordData = record.data();
          return recordData['withdrawalType'] == 'Profit Withdrawal' &&
              (recordData['status'] == 'pending' ||
                  recordData['status'] == 'approved');
        });

        // Check if user has withdrawn this month (for rate limiting)
        final hasWithdrawnThisMonth = withdrawRecords.docs.any((record) {
          final requestDate = (record['requestDate'] as Timestamp).toDate();
          return requestDate.month == now.month && requestDate.year == now.year;
        });

        if (!hasWithdrawnThisMonth) {
          // Add profit withdrawal option if available and not already withdrawn
          if (availableProfit > 0 && !hasWithdrawnProfit) {
            eligiblePackages.add({
              'packageId': packageId,
              'packageName': packageName,
              'eligibleAmount': availableProfit,
              'activatedAt': activatedAt,
              'packagePrice': packagePrice,
              'originalPrice': originalPrice,
              'withdrawalType': 'Profit Withdrawal',
            });
          }

          // Add full withdrawal option if eligible
          if (isEligibleForFullWithdrawal) {
            eligiblePackages.add({
              'packageId': packageId,
              'packageName': packageName,
              'eligibleAmount': packagePrice, // Full amount
              'activatedAt': activatedAt,
              'packagePrice': packagePrice,
              'originalPrice': originalPrice,
              'withdrawalType': 'Full Withdrawal',
            });
          }
        }
      }
      return eligiblePackages;
    } catch (e) {
      print('Error fetching packages: $e');
      return [];
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _sendWithdrawRequest(Map<String, dynamic> package) async {
    setState(() {
      isLoading = true;
    });
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) throw Exception('User not found');

      final userData = userDoc.data()!;
      final withdrawRequest = {
        'userId': userId,
        'name': userData['name'],
        'email': userData['email'],
        'phone': userData['phone'],
        'generatedReferralCode': userData['generatedReferralCode'],
        'requestedAmount': package['eligibleAmount'],
        'requestDate': DateTime.now(),
        'packageId': package['packageId'],
        'packageName': package['packageName'],
        'originalPrice': package['originalPrice'],
        'currentPackageValue': package['packagePrice'],
        'withdrawalType': package['withdrawalType'],
        'status': 'pending',
        'processedAt': null,
        'adminNotes': null,
      };

      // Add withdrawal request
      await FirebaseFirestore.instance
          .collection('withdraw-requests')
          .add(withdrawRequest);

      if (package['withdrawalType'] == 'Full Withdrawal') {
        await FirebaseFirestore.instance
            .collection('request-packages')
            .doc(package['packageId'])
            .update({'isActive': false});
      }

      Fluttertoast.showToast(msg: 'Withdrawal request submitted!');

      // Refresh the eligible packages list
      _fetchEligiblePackages();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.tealAccent[100],
        title: const Text('Withdraw'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : eligiblePackages.isEmpty
              ? const Center(child: Text('No eligible packages found.'))
              : ListView.builder(
                  itemCount: eligiblePackages.length,
                  itemBuilder: (context, index) {
                    final pkg = eligiblePackages[index];

                    return Card(
                      child: ListTile(
                        title: Text(pkg['packageName']),
                        subtitle: Text(
                          'Activated on: ${DateFormat('yyyy-MM-dd').format(pkg['activatedAt'])}\n'
                          'Eligible Amount: Rs. ${pkg['eligibleAmount']}\n'
                          'Withdrawal Type: ${pkg['withdrawalType']}',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _sendWithdrawRequest(pkg),
                          child: Text('Withdraw Rs. ${pkg['eligibleAmount']}'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
