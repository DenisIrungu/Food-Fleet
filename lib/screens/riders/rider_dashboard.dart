// import 'package:flutter/material.dart';
// import '../../services/auth_service.dart';
// import '../../utils/app_theme.dart';

// class RiderDashboard extends StatelessWidget {
//   const RiderDashboard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final AuthService authService = AuthService();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Rider Dashboard'),
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
//               Icons.delivery_dining,
//               size: 100,
//               color: AppTheme.primaryColor,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Welcome, Rider!',
//               style: AppTheme.headingLarge,
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'Your deliveries will appear here',
//               style: AppTheme.bodyMedium,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }