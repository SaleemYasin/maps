import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ReferralPageState createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  User? currentUser;
  List<Map<String, dynamic>> referredFriends = [];
  double totalBonus = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
    _checkForNewReferrals(); // Check for new referrals
  }

  Future<void> _loadReferralData() async {
    setState(() => _isLoading = true);
    try {
      currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Fetch user's referral code
        DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        final generatedReferralCode = currentUserDoc['generatedReferralCode'];

        // Fetch referred friends based on sharedReferralCode
        QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('sharedReferralCode', isEqualTo: generatedReferralCode)
            .get();

        // Fetch withdrawn bonuses for the current user
        QuerySnapshot withdrawnBonusesSnapshot = await FirebaseFirestore
            .instance
            .collection('withdrawnBonuses')
            .where('userId', isEqualTo: currentUser!.uid)
            .get();

        final withdrawnBonusIds = withdrawnBonusesSnapshot.docs
            .map((doc) => doc['bonusId'] as String)
            .toList();

        // Fetch existing bonuses from referralBonuses collection
        QuerySnapshot referralBonusesSnapshot = await FirebaseFirestore.instance
            .collection('referralBonuses')
            .where('userId', isEqualTo: currentUser!.uid)
            .get();

        double calculatedBonus = 0.0;

        // Map bonuses to referred friends
        final friendsList =
            await Future.wait(referralBonusesSnapshot.docs.map((doc) async {
          final data = doc.data() as Map<String, dynamic>;
          final friendId = data['friendId'];

          // Fetch friend's details
          DocumentSnapshot friendDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(friendId)
              .get();

          final friendData = friendDoc.data() as Map<String, dynamic>;

          return {
            'name': friendData['name'] ?? 'Unknown',
            'createdAt': (friendData['createdAt'] as Timestamp).toDate(),
            'bonus': data['bonusAmount'],
            'bonusId': doc.id, // Use the bonus document ID
          };
        }).toList());

        // Filter out withdrawn bonuses
        final nonWithdrawnFriends = friendsList
            .where((friend) => !withdrawnBonusIds.contains(friend['bonusId']))
            .toList();

        // Calculate total bonus
        for (final friend in nonWithdrawnFriends) {
          calculatedBonus += friend['bonus'];
        }

        setState(() {
          referredFriends = nonWithdrawnFriends;
          totalBonus = calculatedBonus; // Update total bonus
        });
      }
    } catch (e) {
      print('Error loading referral data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createBonusForFriend(String friendId) async {
    try {
      currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Check if a bonus already exists for this friend
        QuerySnapshot existingBonusSnapshot = await FirebaseFirestore.instance
            .collection('referralBonuses')
            .where('userId', isEqualTo: currentUser!.uid)
            .where('friendId', isEqualTo: friendId)
            .get();

        if (existingBonusSnapshot.docs.isNotEmpty) {
          // Bonus already exists, skip creation
          return;
        }

        // Fetch friend's details
        DocumentSnapshot friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .get();

        final friendData = friendDoc.data() as Map<String, dynamic>;

        double friendBonus = 500; // Default bonus for joining

        // Check friend's activated packages
        QuerySnapshot packageSnapshot = await FirebaseFirestore.instance
            .collection('request-packages')
            .where('userId', isEqualTo: friendId)
            .where('isActive', isEqualTo: true)
            .get();

        if (packageSnapshot.docs.isNotEmpty) {
          final packagePrice = packageSnapshot.docs.first['packagePrice'] ?? 0;
          if (packagePrice == 10000) {
            friendBonus = 500;
          } else if (packagePrice == 25000)
            friendBonus = 1000;
          else if (packagePrice == 50000)
            friendBonus = 2000;
          else if (packagePrice == 100000)
            friendBonus = 2500;
          else if (packagePrice == 500000) friendBonus = 5000;
        }

        // Store bonus in Firestore
        await FirebaseFirestore.instance.collection('referralBonuses').add({
          'userId': currentUser!.uid,
          'friendId': friendId,
          'bonusAmount': friendBonus,
          'isWithdrawn': false,
          'createdAt': DateTime.now(),
        });
      }
    } catch (e) {
      print('Error creating bonus for friend: $e');
    }
  }

  Future<void> _onFriendReferred(String friendId) async {
    await _createBonusForFriend(friendId);
    await _loadReferralData(); // Refresh the referral data
  }

  Future<void> _checkForNewReferrals() async {
    try {
      currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Fetch user's referral code
        DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        final generatedReferralCode = currentUserDoc['generatedReferralCode'];

        // Fetch referred friends based on sharedReferralCode
        QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('sharedReferralCode', isEqualTo: generatedReferralCode)
            .get();

        // Check each friend and create a bonus if it doesn't exist
        for (final doc in friendsSnapshot.docs) {
          final friendId = doc.id;
          await _createBonusForFriend(friendId);
        }
      }
    } catch (e) {
      print('Error checking for new referrals: $e');
    }
  }

  Future<void> _requestWithdrawal(String bonusId, double amount) async {
    try {
      // Check if the bonus has already been withdrawn
      QuerySnapshot withdrawnBonusSnapshot = await FirebaseFirestore.instance
          .collection('withdrawnBonuses')
          .where('bonusId', isEqualTo: bonusId)
          .where('userId', isEqualTo: currentUser!.uid)
          .get();

      if (withdrawnBonusSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('This bonus has already been withdrawn.')),
        );
        return;
      }

      // Create a withdrawal request
      await FirebaseFirestore.instance.collection('withdrawalRequests').add({
        'userId': currentUser!.uid,
        'bonusId': bonusId,
        'amount': amount,
        'status': 'pending',
        'requestedAt': DateTime.now(),
      });

      // Mark the bonus as withdrawn
      await FirebaseFirestore.instance.collection('withdrawnBonuses').add({
        'userId': currentUser!.uid,
        'bonusId': bonusId,
        'withdrawnAt': DateTime.now(),
      });

      // Remove the bonus from the UI
      setState(() {
        referredFriends.removeWhere((friend) => friend['bonusId'] == bonusId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Withdrawal request submitted successfully.')),
      );
    } catch (e) {
      print('Error requesting withdrawal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit withdrawal request.')),
      );
    }
  }

  void _inviteFriend() async {
    DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    final generatedReferralCode = currentUserDoc['generatedReferralCode'];
    final invitationMessage =
        "MAPS\n\n میں شامل ہوں، آپ کا قابل اعتماد سرمایہ کاری کا ساتھی! صرف 6 ماہ میں 6% سے 12% تک کا منافع حاصل کریں۔ آج ہی اپنے مالی مقاصد کی جانب پہلا قدم اٹھائیں! \n\nایپ ڈاؤنلوڈ کریں: https://maps.email/\n\n میرا ریفرل کوڈ استعمال کریں: $generatedReferralCode اور شروعات کریں۔.";
    Share.share(invitationMessage);
  }

  void _showConditionsPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Referral Bonus Conditions",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          "• Rs. 500 for Rs. 10,000 package\n"
          "• Rs. 1000 for Rs. 25,000 package\n"
          "• Rs. 2000 for Rs. 50,000 package\n"
          "• Rs. 2500 for Rs. 100,000 package\n"
          "• Rs. 5000 for Rs. 500,000 package",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close", style: TextStyle(color: Colors.teal)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 123, 201, 247),
        title: const Text('Referral Friends',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Show Conditions',
            onPressed: _showConditionsPopup,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        label: const Text(
          "Invite Friend",
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(
          Icons.person_add_alt_1,
          color: Colors.white,
        ),
        onPressed: _inviteFriend,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(10),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.monetization_on,
                        color: Colors.redAccent, size: 40),
                    title: const Text("Total Bonus Earned",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text("Rs. $totalBonus",
                        style: const TextStyle(
                            fontSize: 20, color: Colors.redAccent)),
                  ),
                ),
                Container(
                  child: const ListTile(
                    title: Text(
                        "Get Rs 500 Bonus for Every Invite! More Rewards When Your Friend Activate a Packages!",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        )),
                  ),
                ),
                Expanded(
                  child: referredFriends.isEmpty
                      ? const Center(
                          child: Text("No referrals yet!",
                              style: TextStyle(fontSize: 16)))
                      : ListView.builder(
                          itemCount: referredFriends.length,
                          itemBuilder: (context, index) {
                            final friend = referredFriends[index];
                            final formattedDate = DateFormat('yyyy-MM-dd')
                                .format(friend['createdAt']);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.redAccent,
                                  child:
                                      Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(friend['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                subtitle: Text(
                                    "Joined: $formattedDate\n"
                                    "Bonus: Rs. ${friend['bonus']}",
                                    style: const TextStyle(fontSize: 14)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.money_off),
                                  onPressed: () => _requestWithdrawal(
                                      friend['bonusId'], friend['bonus']),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
