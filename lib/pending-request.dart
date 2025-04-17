import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class WithdrawRequestsPage extends StatefulWidget {
  @override
  _WithdrawRequestsPageState createState() => _WithdrawRequestsPageState();
}

class _WithdrawRequestsPageState extends State<WithdrawRequestsPage> {
  bool _isLoading = true;
  bool _isAdmin = false;
  User? currentUser;
  List<Map<String, dynamic>> withdrawRequests = [];
  List<Map<String, dynamic>> bonusWithdrawalRequests = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _isAdmin = await _checkAdmin();
      await _fetchWithdrawRequests();
      await _fetchBonusWithdrawalRequests();
    }
  }

  Future<bool> _checkAdmin() async {
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

  Future<void> _fetchWithdrawRequests() async {
    try {
      QuerySnapshot snapshot;
      if (_isAdmin) {
        // Admin sees all requests
        snapshot = await FirebaseFirestore.instance
            .collection('withdraw-requests')
            .get();
      } else {
        // Customer sees only their own requests
        snapshot = await FirebaseFirestore.instance
            .collection('withdraw-requests')
            .where('userId', isEqualTo: currentUser!.uid)
            .get();
      }

      // Parse the data
      List<Map<String, dynamic>> requests = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;

        // Fetch account details for each user
        Map<String, dynamic>? accountDetails =
            await _fetchUserAccountDetails(docData['userId']);

        requests.add({
          'docId': doc.id,
          'userId': docData['userId'] ?? 'Unknown',
          'email': docData['email'] ?? 'Unknown',
          'name': docData['name'] ?? 'Unknown',
          'phone': docData['phone'] ?? 'Unknown',
          'requestedAmount': docData['requestedAmount'] ?? 0,
          'status': docData['status'] ?? 'Pending',
          'requestDate': docData['requestDate']?.toDate(),
          'isActionTaken': docData['isActionTaken'] ?? false,
          'accountDetails': accountDetails,
          'type': 'withdraw-request', // To differentiate between collections
        });
      }

      setState(() {
        withdrawRequests = requests;
      });
    } catch (e) {
      print('Error fetching withdrawal requests: $e');
    }
  }

  Future<void> _fetchBonusWithdrawalRequests() async {
    try {
      QuerySnapshot snapshot;
      if (_isAdmin) {
        // Admin sees all bonus withdrawal requests
        snapshot = await FirebaseFirestore.instance
            .collection('withdrawalRequests')
            .get();
      } else {
        // Customer sees only their own bonus withdrawal requests
        snapshot = await FirebaseFirestore.instance
            .collection('withdrawalRequests')
            .where('userId', isEqualTo: currentUser!.uid)
            .get();
      }

      // Parse the data
      List<Map<String, dynamic>> requests = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;

        // Fetch user details for each request
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(docData['userId'])
            .get();

        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        requests.add({
          'docId': doc.id,
          'userId': docData['userId'] ?? 'Unknown',
          'name': userData['name'] ?? 'Unknown',
          'email': userData['email'] ?? 'Unknown',
          'amount': docData['amount'] ?? 0,
          'status': docData['status'] ?? 'Pending',
          'requestedAt': docData['requestedAt']?.toDate(),
          'bonusId': docData['bonusId'] ?? 'Unknown',
          'type': 'bonus-withdrawal', // To differentiate between collections
        });
      }

      setState(() {
        bonusWithdrawalRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching bonus withdrawal requests: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchUserAccountDetails(String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('user-accounts')
          .where('uid', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching user account details: $e');
    }
    return null;
  }

  Future<void> _updateRequestStatus(
      String docId, String status, String collectionName) async {
    try {
      DocumentSnapshot requestDoc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(docId)
          .get();

      Map<String, dynamic> requestData =
          requestDoc.data() as Map<String, dynamic>;

      // Only process if status is changing
      if (requestData['status'] != status) {
        // For approved withdrawals, update the package
        if (status == 'approved' && collectionName == 'withdraw-requests') {
          await _processApprovedWithdrawal(requestData);
        }

        // Update the request status
        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(docId)
            .update({
          'status': status,
          'isActionTaken': true,
          'processedAt': FieldValue.serverTimestamp(),
          'processedBy': _isAdmin ? currentUser?.uid : null,
        });

        // Update UI
        setState(() {
          if (collectionName == 'withdraw-requests') {
            var request =
                withdrawRequests.firstWhere((req) => req['docId'] == docId);
            request['status'] = status;
            request['isActionTaken'] = true;
          } else {
            var request = bonusWithdrawalRequests
                .firstWhere((req) => req['docId'] == docId);
            request['status'] = status;
          }
        });

        Fluttertoast.showToast(msg: "Request $status successfully");
      }
    } catch (e) {
      print('Error updating status: $e');
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

  Future<void> _processApprovedWithdrawal(
      Map<String, dynamic> requestData) async {
    final packageId = requestData['packageId'];
    final withdrawalType = requestData['withdrawalType'];
    final amount = requestData['requestedAmount'];

    final packageRef = FirebaseFirestore.instance
        .collection('request-packages')
        .doc(packageId);

    if (withdrawalType == 'Profit Withdrawal') {
      // Deduct from profit (packagePrice)
      await packageRef.update({
        'packagePrice': FieldValue.increment(-amount),
      });
    } else if (withdrawalType == 'Full Withdrawal') {
      // Mark package as inactive
      await packageRef.update({
        'isActive': false,
        'packagePrice': 0, // Zero out the balance
      });
    }
  }

  Future<void> _deleteRequest(String docId, String collectionName) async {
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(docId)
          .delete();

      setState(() {
        if (collectionName == 'withdraw-requests') {
          withdrawRequests.removeWhere((req) => req['docId'] == docId);
        } else {
          bonusWithdrawalRequests.removeWhere((req) => req['docId'] == docId);
        }
      });

      Fluttertoast.showToast(msg: "Request deleted successfully");
    } catch (e) {
      print('Error deleting request: $e');
      Fluttertoast.showToast(msg: "Error deleting request");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.tealAccent[100],
        title: const Text('Withdraw Requests'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ...withdrawRequests
                    .map((request) => _buildRequestCard(request)),
                ...bonusWithdrawalRequests
                    .map((request) => _buildRequestCard(request)),
              ],
            ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final isWithdrawRequest = request['type'] == 'withdraw-request';
    final accountDetails = request['accountDetails'];
    final requestedAt = request['requestedAt'] != null
        ? (request['requestedAt'] as DateTime).toString().substring(0, 16)
        : 'Unknown';
    final isActionTaken = request['isActionTaken'] ?? false;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.all(10),
      elevation: 5,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: ${request['name']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Email: ${request['email']}'),
            Text(
              'Amount: Rs. ${isWithdrawRequest ? request['requestedAmount'] : request['amount']}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Requested At: $requestedAt'),
            if (isWithdrawRequest &&
                accountDetails != null &&
                _isAdmin &&
                !isActionTaken) ...[
              Divider(),
              const Text('Account Details:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
              Text('Account Title: ${accountDetails['accountTitle']}'),
              Text('Account Number: ${accountDetails['accountNumber']}'),
              Text('Account Type: ${accountDetails['accountType']}'),
              if (accountDetails['accountType'] == 'Bank')
                Text('Bank Name: ${accountDetails['bankName']}'),
            ],
            Divider(),
            Text(
              'Status: ${request['status']}',
              style: TextStyle(
                color: request['status'] == 'approved'
                    ? Colors.green
                    : (request['status'] == 'declined'
                        ? Colors.red
                        : Colors.orange),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            if (_isAdmin && !isActionTaken)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Delete Button
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _showDeleteConfirmationDialog(
                        request['docId'],
                        isWithdrawRequest
                            ? 'withdraw-requests'
                            : 'withdrawalRequests',
                      );
                    },
                  ),
                  SizedBox(width: 10),
                  // Decline Button
                  ElevatedButton(
                    onPressed: () {
                      _updateRequestStatus(
                        request['docId'],
                        'declined',
                        isWithdrawRequest
                            ? 'withdraw-requests'
                            : 'withdrawalRequests',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  // Approve Button
                  ElevatedButton(
                    onPressed: () {
                      _updateRequestStatus(
                        request['docId'],
                        'approved',
                        isWithdrawRequest
                            ? 'withdraw-requests'
                            : 'withdrawalRequests',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Approve',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(String docId, String collectionName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this request?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRequest(docId, collectionName);
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
