import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:khushhali_app/AuthService%20.dart';
import 'package:khushhali_app/Profile.dart';
import 'package:khushhali_app/VideoPlayerWidget.dart';
import 'package:khushhali_app/WithdrawPage.dart';
import 'package:khushhali_app/addaccount.dart';
import 'package:khushhali_app/admin-ads.dart';
import 'package:khushhali_app/all-users.dart';
import 'package:khushhali_app/packages.dart';
import 'package:khushhali_app/pending-request.dart';
import 'package:khushhali_app/reference.dart';
import 'package:khushhali_app/updateprice.dart';
import 'package:khushhali_app/yourPackages.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 123, 201, 247),
        appBar: AppBar(
          title: const Text(
            'MAPS',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: () async {
                      try {
                        await AuthService().signOut();
                        if (context.mounted) {
                          Navigator.of(context)
                              .pushReplacementNamed('/LoginPage');
                        }
                      } catch (e) {
                        print('Error logging out: $e');
                      }
                    },
                    tooltip: 'Logout',
                  ),
                ],
              ),
            ),
          ],
          backgroundColor: const Color.fromARGB(255, 123, 201, 247),
          elevation: 0,
        ),
        body: SingleChildScrollView(
            child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          color: const Color.fromARGB(255, 123, 201, 247),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FutureBuilder<bool>(
                future: _isAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final isAdmin = snapshot.data ?? false;

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        if (isAdmin)
                          const Text(
                            'Welcome Admin',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          )
                        else
                          Column(
                            children: [
                              _buildUserInfoCard(context),
                              const SizedBox(height: 10),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
              _buildAdsSection(context),
              const SizedBox(height: 10),
              SizedBox(
                height: 500,
                child: FutureBuilder<bool>(
                  future: _isAdmin(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final isAdmin = snapshot.data ?? false;

                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        // Admin & Customer option with renamed title for admin
                        _buildGridItem(
                          title: isAdmin ? 'Add Packages' : 'Start Investment',
                          subtitle: 'Earn Profit',
                          icon: Icons.show_chart,
                          context: context,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PackageDisplay(),
                              ),
                            );
                          },
                        ),

                        // Admin & Customer option with renamed title for admin
                        _buildGridItem(
                          title:
                              isAdmin ? 'Activate Packages' : 'Your Packages',
                          subtitle: 'Package',
                          icon: Icons.list_alt_outlined,
                          context: context,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const YourPackages(),
                              ),
                            );
                          },
                        ),

                        if (!isAdmin)
                          _buildGridItem(
                            title: 'Withdraw',
                            subtitle: 'Request',
                            icon: Icons.money_off,
                            context: context,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => WithdrawPage(
                                        FirebaseAuth
                                            .instance.currentUser!.uid)),
                              );
                            },
                          ),

                        _buildGridItem(
                          title: isAdmin
                              ? 'Withdrawal Requests'
                              : 'Withdrawal History',
                          subtitle: isAdmin ? 'Requests' : 'History',
                          icon: Icons.history,
                          context: context,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WithdrawRequestsPage(),
                              ),
                            );
                          },
                        ),

                        // Options hidden from admin
                        if (!isAdmin) ...[
                          _buildGridItem(
                            title: 'Profile',
                            subtitle: 'Dashboard',
                            icon: Icons.person,
                            context: context,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const ProfilePage()),
                              );
                            },
                          ),
                          _buildGridItem(
                            title: 'Referral',
                            subtitle: 'Commission',
                            icon: Icons.people_outline,
                            context: context,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ReferralPage()),
                              );
                            },
                          ),
                          _buildGridItem(
                            title: 'Add Account',
                            subtitle: 'Link Account',
                            icon: Icons.account_balance_wallet_outlined,
                            context: context,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AddAccountPage()),
                              );
                            },
                          ),
                        ],

                        // Admin-specific option
                        if (isAdmin)
                          _buildGridItem(
                            title: 'Update Payment',
                            subtitle: 'Add Profit',
                            icon: Icons.payment_outlined,
                            context: context,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const UpdatePackagePricePage()),
                              );
                            },
                          ),
                        if (isAdmin)
                          _buildGridItem(
                            title: 'Advertisement',
                            subtitle: 'Add Adds',
                            icon: Icons.payment_outlined,
                            context: context,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AdminAdsPage()),
                              );
                            },
                          ),
                        if (isAdmin)
                          _buildGridItem(
                            title: 'All User',
                            subtitle: 'Accounts',
                            icon: Icons.supervised_user_circle,
                            context: context,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AdminViewUsersPage()),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        )));
  }

  // Method to fetch balance for the active packages
  Future<double> _fetchUserBalance() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot activePackages = await FirebaseFirestore.instance
        .collection('request-packages')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    double totalBalance = 0;
    for (var doc in activePackages.docs) {
      totalBalance += doc['packagePrice'] ?? 0;
    }

    return totalBalance;
  }

  Widget _buildUserInfoCard(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Wellcome Admin"));
        }
        var userData = snapshot.data!.data() as Map<String, dynamic>;

        return Container(
          height: 260,
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userData['name'] ?? 'User Name',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userData['email'] ?? 'Email',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                userData['phone'] ?? '+1234567890',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 5),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!, width: 1),
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: FutureBuilder<double>(
                  future: _fetchUserBalance(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        'Rs. 0',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      );
                    }
                    return Text(
                      'Rs. ${snapshot.data?.toStringAsFixed(2) ?? '0'}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Code: ${userData['generatedReferralCode'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.orange),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: userData['generatedReferralCode'] ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Referral code copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.orangeAccent),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdsSection(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('ads').doc('current').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("No ads available"));
        }

        var adsData = snapshot.data!.data() as Map<String, dynamic>;
        List<dynamic> sliderUrls = adsData['sliderUrls'] ?? [];
        String? videoUrl = adsData['videoUrl'];
        double petrolPrice = adsData['petrolPrice']?.toDouble() ?? 00.0;
        double dieselPrice = adsData['dieselPrice']?.toDouble() ?? 00.0;
        double lubricantPrice = adsData['lubricantPrice']?.toDouble() ?? 00.0;

        return Column(
          children: [
            _buildVideoSliderSection(videoUrl, sliderUrls),
            const SizedBox(height: 16),
            _buildPetroleumSection(petrolPrice, dieselPrice, lubricantPrice),
          ],
        );
      },
    );
  }

  Widget _buildVideoSliderSection(String? videoUrl, List<dynamic> sliderUrls) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: videoUrl != null
            ? _buildVideoPlayer(videoUrl)
            : _buildImageSlider(sliderUrls),
      ),
    );
  }

  Widget _buildPetroleumSection(
      double petrolPrice, double dieselPrice, double lubricantPrice) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade100, Colors.orange.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Petroleum Prices',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildPetroleumPriceRow('Petrol', petrolPrice),
          const SizedBox(height: 8),
          _buildPetroleumPriceRow('Diesel', dieselPrice),
          const SizedBox(height: 8),
          _buildPetroleumPriceRow('Lubricant', lubricantPrice),
        ],
      ),
    );
  }

  Widget _buildPetroleumPriceRow(String type, double price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          type,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        Text(
          'Rs. ${price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSlider(List<dynamic> sliderUrls) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 220,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 1.0,
      ),
      items: sliderUrls.map((url) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVideoPlayer(String videoUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: VideoPlayerWidget(videoUrl: videoUrl),
    );
  }
}
