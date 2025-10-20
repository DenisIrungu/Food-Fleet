// import 'package:flutter/material.dart';
// import '../../services/auth_service.dart';
// import '../../utils/app_theme.dart';

// class CustomerDashboard extends StatelessWidget {
//   const CustomerDashboard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final AuthService authService = AuthService();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Customer Dashboard'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () async {
//               await authService.signOut();
//             },
//           ),
//         ],
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.restaurant_menu,
//               size: 100,
//               color: AppTheme.primaryColor,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Welcome, Customer!',
//               style: AppTheme.headingLarge,
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'Browse restaurants and order food',
//               style: AppTheme.bodyMedium,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }