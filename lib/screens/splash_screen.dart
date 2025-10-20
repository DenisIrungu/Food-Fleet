// import 'package:flutter/material.dart';
// import '../utils/app_theme.dart';
// import '../utils/constants.dart';
// import '../utils/routes.dart';

// class SplashScreen extends StatelessWidget {
//   const SplashScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       body: Container(
//         height: size.height,
//         width: size.width,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               AppTheme.primaryColor,
//               AppTheme.primaryColor.withOpacity(0.8),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(32.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const SizedBox(height: 60),

//                   // App Icon
//                   Container(
//                     padding: const EdgeInsets.all(24),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(24),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 20,
//                           offset: const Offset(0, 10),
//                         ),
//                       ],
//                     ),
//                     child: Icon(
//                       Icons.restaurant_menu,
//                       size: size.width * 0.18, // responsive
//                       color: AppTheme.primaryColor,
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   // App Name
//                   Text(
//                     APP_NAME,
//                     style: AppTheme.headingLarge.copyWith(
//                       color: Colors.white,
//                       fontSize: size.width * 0.08, // responsive font
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // Tagline
//                   Text(
//                     'Fast Food Delivery\nAt Your Doorstep',
//                     textAlign: TextAlign.center,
//                     style: AppTheme.bodyLarge.copyWith(
//                       color: Colors.white.withOpacity(0.9),
//                       fontSize: size.width * 0.045,
//                       height: 1.5,
//                     ),
//                   ),

//                   const SizedBox(height: 60),

//                   // Get Started Button
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.pushReplacementNamed(context, LOGIN_ROUTE);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         foregroundColor: AppTheme.primaryColor,
//                         padding: const EdgeInsets.symmetric(vertical: 18),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 0,
//                       ),
//                       child: const Text(
//                         'Get Started',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // Version
//                   Text(
//                     'Version $APP_VERSION',
//                     style: AppTheme.bodySmall.copyWith(
//                       color: Colors.white.withOpacity(0.7),
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
