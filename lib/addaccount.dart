import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAccountPage extends StatefulWidget {
  @override
  _AddAccountPageState createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? uid;
  int editAttempts = 0;
  DateTime? lastAttemptTime;

  @override
  void initState() {
    super.initState();
    uid = _auth.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              if (await _canAttemptEdit()) {
                final account = await _getAccountDetails();
                _showEditOrSwitchAccountOptions(account);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please try again later after 30 minutes'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('user-accounts')
            .where('uid', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return _buildAddAccountOptions(); // Show add options if no account
          } else {
            return _buildAccountDetail(
                snapshot.data!.docs.first); // Show account details if exists
          }
        },
      ),
    );
  }

  Future<bool> _canAttemptEdit() async {
    if (editAttempts >= 3) {
      if (lastAttemptTime == null ||
          DateTime.now().difference(lastAttemptTime!) > Duration(minutes: 30)) {
        editAttempts = 0;
      } else {
        return false;
      }
    }
    editAttempts++;
    lastAttemptTime = DateTime.now();
    return true;
  }

  Future<DocumentSnapshot?> _getAccountDetails() async {
    final snapshot = await _firestore
        .collection('user-accounts')
        .where('uid', isEqualTo: uid)
        .get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
  }

  void _showEditOrSwitchAccountOptions(DocumentSnapshot? account) {
    if (account != null) {
      String accountType = account['accountType'];
      showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Edit or Switch Account'),
            children: [
              if (accountType == 'Bank')
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                    _openBankAccountForm(account); // Edit Bank Account
                  },
                  child: const Text('Edit Bank Account'),
                ),
              if (accountType == 'Easy Paisa')
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                    _openEasyPaisaForm(account); // Edit Easy Paisa Account
                  },
                  child: const Text('Edit Easy Paisa Account'),
                ),
              if (accountType == 'Jazz Cash')
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                    _openJazzCashForm(account); // Edit Jazz Cash Account
                  },
                  child: const Text('Edit Jazz Cash Account'),
                ),
              if (accountType != 'Bank')
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                    _openBankAccountForm(); // Switch to Bank Account
                  },
                  child: const Text('Change to Bank Account'),
                ),
              if (accountType != 'Easy Paisa')
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                    _openEasyPaisaForm(); // Switch to Easy Paisa Account
                  },
                  child: const Text('Change to Easy Paisa Account'),
                ),
              if (accountType != 'Jazz Cash')
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                    _openJazzCashForm(); // Switch to Jazz Cash Account
                  },
                  child: const Text('Change to Jazz Cash Account'),
                ),
            ],
          );
        },
      );
    }
  }

  Widget _buildAddAccountOptions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _openBankAccountForm,
            child: const Text('Add Bank Account'),
          ),
          ElevatedButton(
            onPressed: _openEasyPaisaForm,
            child: const Text('Add Easy Paisa Account'),
          ),
          ElevatedButton(
            onPressed: _openJazzCashForm,
            child: const Text('Add Jazz Cash Account'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetail(DocumentSnapshot account) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${account['accountType']} Account',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Account Title: ${account['accountTitle']}',
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 5),
              Text('Account Number: ${account['accountNumber']}',
                  style: TextStyle(fontSize: 16)),
              if (account['accountType'] == 'Bank') SizedBox(height: 5),
              if (account['accountType'] == 'Bank')
                Text('Bank Name: ${account['bankName']}',
                    style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  void _openBankAccountForm([DocumentSnapshot? account]) {
    String accountTitle = account?.get('accountTitle') ?? '';
    String accountNumber = account?.get('accountNumber') ?? '';
    String selectedBank = account?.get('bankName') ?? 'Select Bank';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add/Edit Bank Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedBank,
                items: const [
                  DropdownMenuItem(
                      value: 'Select Bank', child: Text('Select Bank')),
                  DropdownMenuItem(value: 'MCB', child: Text('MCB')),
                  DropdownMenuItem(
                      value: 'Allied Bank', child: Text('Allied Bank')),
                  DropdownMenuItem(
                      value: 'Bank of Punjab', child: Text('Bank of Punjab')),
                  DropdownMenuItem(
                      value: 'Faysal Bank', child: Text('Faysal Bank')),
                  DropdownMenuItem(value: 'UBL', child: Text('UBL')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedBank = value!;
                  });
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Account Title'),
                onChanged: (value) {
                  accountTitle = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Account Number'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  accountNumber = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (accountTitle.isNotEmpty &&
                    accountNumber.isNotEmpty &&
                    selectedBank != 'Select Bank') {
                  _submitAccountData('Bank', accountTitle, accountNumber,
                      selectedBank, account);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _openEasyPaisaForm([DocumentSnapshot? account]) {
    String accountTitle = account?.get('accountTitle') ?? '';
    String accountNumber = account?.get('accountNumber') ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add/Edit Easy Paisa Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Account Title'),
                onChanged: (value) {
                  accountTitle = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Account Number'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  accountNumber = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (accountTitle.isNotEmpty && accountNumber.isNotEmpty) {
                  _submitAccountData(
                      'Easy Paisa', accountTitle, accountNumber, null, account);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _openJazzCashForm([DocumentSnapshot? account]) {
    String accountTitle = account?.get('accountTitle') ?? '';
    String accountNumber = account?.get('accountNumber') ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add/Edit Jazz Cash Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Account Title'),
                onChanged: (value) {
                  accountTitle = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Account Number'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  accountNumber = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (accountTitle.isNotEmpty && accountNumber.isNotEmpty) {
                  _submitAccountData(
                      'Jazz Cash', accountTitle, accountNumber, null, account);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _submitAccountData(String accountType, String accountTitle,
      String accountNumber, String? bankName, DocumentSnapshot? account) async {
    if (account == null) {
      await _firestore.collection('user-accounts').add({
        'uid': uid,
        'accountType': accountType,
        'accountTitle': accountTitle,
        'accountNumber': accountNumber,
        'bankName': bankName,
      });
    } else {
      await _firestore.collection('user-accounts').doc(account.id).update({
        'accountType': accountType,
        'accountTitle': accountTitle,
        'accountNumber': accountNumber,
        'bankName': bankName,
      });
    }
    Navigator.pop(context);
  }
}
