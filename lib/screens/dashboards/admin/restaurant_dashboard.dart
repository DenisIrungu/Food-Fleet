// import 'package:flutter/material.dart';
// import '../../services/auth_service.dart';
// import '../../utils/app_theme.dart';

// class RestaurantDashboard extends StatelessWidget {
//   const RestaurantDashboard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final AuthService authService = AuthService();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Restaurant Dashboard'),
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
//               Icons.restaurant,
//               size: 100,
//               color: AppTheme.primaryColor,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Welcome, Restaurant!',
//               style: AppTheme.headingLarge,
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'Manage your menu and orders here',
//               style: AppTheme.bodyMedium,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }