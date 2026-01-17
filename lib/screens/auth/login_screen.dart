import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:foodfleet/providers/restaurant_scope_provider.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/validators.dart';
import '../../utils/routes.dart';
import '../../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      UserModel? user = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null && mounted) {
        // --- Handle first login password change ---
        if (user.firstLogin) {
          Navigator.pushReplacementNamed(context, CHANGE_PASSWORD_ROUTE);
          return;
        }

        // --- SET RESTAURANT ID for restaurant admins ---
        if (user.role == ROLE_RESTAURANT_ADMIN) {
          final restaurantScope = context.read<RestaurantScope>();

          if (user.restaurantId != null && user.restaurantId!.isNotEmpty) {
            restaurantScope
                .setRestaurant(user.restaurantId!); // ✅ sets restaurant ID
          } else {
            Fluttertoast.showToast(
              msg: 'Restaurant ID not found for this admin.',
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
            return; // Stop navigation if restaurantId missing
          }
        }

        // --- Navigate based on role ---
        _navigateBasedOnRole(user.role);
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: e.toString(),
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateBasedOnRole(String role) {
    if (!mounted) return;

    String route;
    switch (role) {
      case ROLE_SUPER_ADMIN:
        route = SUPER_ADMIN_DASHBOARD_ROUTE;
        break;
      case ROLE_RESTAURANT_ADMIN:
        route = RESTAURANT_DASHBOARD_ROUTE;
        break;
      case ROLE_RIDER:
        route = RIDER_DASHBOARD_ROUTE;
        break;
      case ROLE_CUSTOMER:
        route = CUSTOMER_DASHBOARD_ROUTE;
        break;
      default:
        Fluttertoast.showToast(
          msg: 'Invalid user role',
          backgroundColor: Colors.red,
        );
        return;
    }

    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 1024;
            bool isTablet =
                constraints.maxWidth > 600 && constraints.maxWidth <= 1024;

            double maxWidth = isDesktop
                ? 500
                : isTablet
                    ? 420
                    : double.infinity;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Text(
                          "Welcome Back 👋",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Login to your account",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Email label
                        const Text(
                          "Email",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            hintText: "Your Email",
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password label
                        const Text(
                          "Password",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: Validators.validatePassword,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            hintText: "Your Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {/* TODO reset password */},
                            child: Text(
                              "Forgot your Password?",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Sign In button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    "Sign In",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sign Up link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () => Navigator.pushNamed(
                                      context, REGISTER_ROUTE),
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey[400]),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                "Or continue with",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Google Sign In
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    // TODO sign in with Google
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: ClipOval(
                              child: Image.asset(
                                'assets/google.jpg',
                                height: 24,
                                width: 24,
                                fit: BoxFit.cover,
                              ),
                            ),
                            label: const Text(
                              "Sign in with Google",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Apple Sign In
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    // TODO sign in with Apple
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: ClipOval(
                              child: Image.asset(
                                'assets/apple.jpg',
                                height: 28,
                                width: 28,
                                fit: BoxFit.cover,
                              ),
                            ),
                            label: const Text(
                              "Sign in with Apple",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
