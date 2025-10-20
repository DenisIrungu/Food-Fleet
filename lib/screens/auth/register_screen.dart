import 'package:flutter/material.dart';
import 'package:foodfleet/components/my_textfield.dart';
import 'package:foodfleet/components/mybutton.dart';
import 'package:foodfleet/screens/auth/login_screen.dart';

class SignUp extends StatefulWidget {
  final VoidCallback onTap;
  const SignUp({super.key, required this.onTap});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool _isLoading = false;
  IconData iconPassword = Icons.visibility;
  IconData iconConfirmPassword = Icons.visibility;

  static const Color primaryColor = Color(0xFF0F2A12);
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  // Validators
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your name';
    if (value.trim().length < 2) return 'Name must be at least 2 characters long';
    if (value.trim().length > 50) return 'Name must be less than 50 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    if (!RegExp(emailPattern).hasMatch(value.trim())) return 'Please enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 8) return 'Password must be at least 8 characters long';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Password must contain uppercase';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Password must contain lowercase';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Password must contain a number';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  String _getErrorMessage(String error) {
    if (error.contains('email-already-in-use')) return 'An account with this email already exists.';
    if (error.contains('invalid-email')) return 'Please enter a valid email address.';
    if (error.contains('weak-password')) return 'Password is too weak.';
    if (error.contains('network-request-failed')) return 'Check your internet connection.';
    if (error.contains('too-many-requests')) return 'Too many attempts. Try later.';
    return 'An error occurred while creating your account.';
  }

  void _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creating your account...'),
          backgroundColor: primaryColor,
        ),
      );

      // TODO: Implement Firebase Auth registration here

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please check your email.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Registration Failed'),
            content: Text(_getErrorMessage(e.toString())),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double responsiveFont(double size) {
      if (screenWidth < 400) return size * 0.85;
      if (screenWidth < 600) return size;
      if (screenWidth < 900) return size * 1.1;
      return size * 1.3;
    }

    double responsivePadding() => screenWidth < 600 ? 20 : 40;
    double responsiveSpacing() => screenWidth < 600 ? 15 : 25;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _isLoading
              ? null
              : () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(responsivePadding()),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: responsiveFont(35),
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: responsiveSpacing() / 2),
                      Text(
                        'Create account and choose your favorite menu',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: responsiveFont(16),
                        ),
                      ),
                      SizedBox(height: responsiveSpacing()),

                      // Name Field
                      Text('Name',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: responsiveFont(16),
                              fontWeight: FontWeight.bold)),
                      MyTextField(
                        controller: _nameController,
                        hintText: 'Your Name',
                        obscureText: false,
                        validator: _validateName,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.name,
                      ),
                      SizedBox(height: responsiveSpacing()),

                      // Email Field
                      Text('Email',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: responsiveFont(16),
                              fontWeight: FontWeight.bold)),
                      MyTextField(
                        controller: _emailController,
                        hintText: 'Your Email',
                        obscureText: false,
                        validator: _validateEmail,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: responsiveSpacing()),

                      // Password Field
                      Text('Password',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: responsiveFont(16),
                              fontWeight: FontWeight.bold)),
                      MyTextField(
                        controller: _passwordController,
                        hintText: 'Your Password',
                        obscureText: obscurePassword,
                        validator: _validatePassword,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.visiblePassword,
                        suffixIcon: IconButton(
                          icon: Icon(iconPassword, color: primaryColor),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                    iconPassword = obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off;
                                  });
                                },
                        ),
                      ),
                      SizedBox(height: responsiveSpacing()),

                      // Confirm Password Field
                      Text('Confirm Password',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: responsiveFont(16),
                              fontWeight: FontWeight.bold)),
                      MyTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm Password',
                        obscureText: obscureConfirmPassword,
                        validator: _validateConfirmPassword,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.visiblePassword,
                        suffixIcon: IconButton(
                          icon: Icon(iconConfirmPassword, color: primaryColor),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    obscureConfirmPassword = !obscureConfirmPassword;
                                    iconConfirmPassword = obscureConfirmPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off;
                                  });
                                },
                        ),
                      ),
                      SizedBox(height: responsiveSpacing()),

                      // Register Button
                      MyButton(
                        text: 'Register',
                        onPress: _isLoading ? null : _registerUser,
                        color: primaryColor,
                        foregroundColor: Colors.white,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : null,
                      ),
                      SizedBox(height: responsiveSpacing()),

                      // Sign In Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Have an account?",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: responsiveFont(14),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: _isLoading ? () {} : widget.onTap,
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: responsiveFont(14),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsiveSpacing()),

                      // Terms & Policy
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'By clicking Register you agree to our',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: responsiveFont(12),
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Terms and Data Policy page not implemented yet'),
                                      ),
                                    );
                                  },
                            child: Text(
                              'Terms and Data Policy',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: responsiveFont(12),
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
