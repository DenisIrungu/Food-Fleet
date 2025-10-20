// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import '../../services/auth_service.dart';
// import '../../utils/app_theme.dart';
// import '../../utils/validators.dart';

// class ChangePasswordScreen extends StatefulWidget {
//   const ChangePasswordScreen({super.key});

//   @override
//   State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
// }

// class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _newPasswordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final AuthService _authService = AuthService();
  
//   bool _isLoading = false;
//   bool _obscureNewPassword = true;
//   bool _obscureConfirmPassword = true;

//   @override
//   void dispose() {
//     _newPasswordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   // Handle password change
//   Future<void> _handleChangePassword() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     try {
//       await _authService.changePassword(_newPasswordController.text);

//       Fluttertoast.showToast(
//         msg: 'Password changed successfully!',
//         backgroundColor: AppTheme.accentColor,
//         textColor: Colors.white,
//       );

//       // Navigate back to auth wrapper (will redirect to dashboard)
//       Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: e.toString(),
//         backgroundColor: AppTheme.errorColor,
//         textColor: Colors.white,
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppTheme.backgroundColor,
//       appBar: AppBar(
//         title: const Text('Change Password'),
//         automaticallyImplyLeading: false, // Prevent back navigation
//       ),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   // Icon
//                   Icon(
//                     Icons.lock_reset,
//                     size: 80,
//                     color: AppTheme.primaryColor,
//                   ),
//                   const SizedBox(height: 16),

//                   // Title
//                   Text(
//                     'First Time Login',
//                     style: AppTheme.headingMedium,
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 8),

//                   // Subtitle
//                   Text(
//                     'Please change your temporary password',
//                     style: AppTheme.bodyMedium,
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 32),

//                   // New Password field
//                   TextFormField(
//                     controller: _newPasswordController,
//                     obscureText: _obscureNewPassword,
//                     decoration: InputDecoration(
//                       labelText: 'New Password',
//                       prefixIcon: const Icon(Icons.lock_outline),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _obscureNewPassword
//                               ? Icons.visibility_outlined
//                               : Icons.visibility_off_outlined,
//                         ),
//                         onPressed: () {
//                           setState(
//                               () => _obscureNewPassword = !_obscureNewPassword);
//                         },
//                       ),
//                     ),
//                     validator: Validators.validatePassword,
//                     enabled: !_isLoading,
//                   ),
//                   const SizedBox(height: 16),

//                   // Confirm Password field
//                   TextFormField(
//                     controller: _confirmPasswordController,
//                     obscureText: _obscureConfirmPassword,
//                     decoration: InputDecoration(
//                       labelText: 'Confirm New Password',
//                       prefixIcon: const Icon(Icons.lock_outline),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _obscureConfirmPassword
//                               ? Icons.visibility_outlined
//                               : Icons.visibility_off_outlined,
//                         ),
//                         onPressed: () {
//                           setState(() =>
//                               _obscureConfirmPassword = !_obscureConfirmPassword);
//                         },
//                       ),
//                     ),
//                     validator: (value) => Validators.validateConfirmPassword(
//                       value,
//                       _newPasswordController.text,
//                     ),
//                     enabled: !_isLoading,
//                   ),
//                   const SizedBox(height: 24),

//                   // Change Password Button
//                   ElevatedButton(
//                     onPressed: _isLoading ? null : _handleChangePassword,
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                     ),
//                     child: _isLoading
//                         ? const SizedBox(
//                             height: 20,
//                             width: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor:
//                                   AlwaysStoppedAnimation<Color>(Colors.white),
//                             ),
//                           )
//                         : const Text(
//                             'Change Password',
//                             style: TextStyle(fontSize: 16),
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }