// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';

// class ConnectivityService {
//   static final Connectivity _connectivity = Connectivity();
//   static Stream<List<ConnectivityResult>> get connectivityStream =>
//       _connectivity.onConnectivityChanged;

//   static Future<bool> isConnected() async {
//     final result = await _connectivity.checkConnectivity();
//     return !result.contains(ConnectivityResult.none);
//   }
// }

// class NoInternetScreen extends StatelessWidget {
//   const NoInternetScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('No Internet')),
//       body: const Center(child: Text('Please check your internet connection.')),
//     );
//   }
// }
