import 'dart:math';
import 'package:flutter/material.dart';
import 'package:foodfleet/models/restaurant_model.dart';
import 'package:foodfleet/services/auth_service.dart';
import 'package:foodfleet/utils/validators.dart';
import 'package:foodfleet/services/database_service.dart';

class CreateAdmin extends StatefulWidget {
  const CreateAdmin({super.key});

  @override
  State<CreateAdmin> createState() => _CreateAdminPageState();
}

class _CreateAdminPageState extends State<CreateAdmin> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cuisineTypeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  final _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  String? _emailError;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _emailError = null;
    });

    try {
      // 1️⃣ Create restaurant FIRST (without adminUid)
      final restaurant = RestaurantModel(
        id: '',
        name: _restaurantNameController.text.trim(),
        adminUid: '',
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        cuisineTypes: _cuisineTypeController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save restaurant and get its ID
      final restaurantId = await _databaseService.createRestaurant(restaurant);

      // 2️⃣ Create restaurant admin (Auth + Firestore)
      final adminUser = await _authService.createRestaurantAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        restaurantId: restaurantId,
        restaurantName: restaurant.name,
      );

      // 3️⃣ Update restaurant with admin UID
      await _databaseService.updateRestaurantData(
        restaurantId,
        {
          'adminUid': adminUser!.uid,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Restaurant & Admin created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _formKey.currentState!.reset();
    } catch (e) {
      if (e.toString().toLowerCase().contains('email')) {
        setState(() {
          _emailError = 'This email is already registered';
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_emailError ?? '❌ Failed to create restaurant'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _addressController.dispose();
    _cuisineTypeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Restaurant Admin'),
        centerTitle: true,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= 800;
        final horizontalPadding = width >= 1200 ? 64.0 : (isWide ? 40.0 : 16.0);
        final contentMaxWidth = min(width, 1000.0);

        return Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                'Create Restaurant & Admin',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            if (isWide)
                              Padding(
                                padding: const EdgeInsets.only(left: 12.0),
                                child: Text(
                                  'Step 1 of 1',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        isWide
                            ? _buildTwoColumnFields()
                            : _buildSingleColumnFields(),
                        const SizedBox(height: 20),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Row(
                                children: [
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed:
                                          _isLoading ? null : _submitForm,
                                      icon: const Icon(Icons.add,
                                          color: Colors.white),
                                      label: const Text(
                                        'Add Restaurant Admin',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      style: TextButton.styleFrom(
                                        backgroundColor: _isLoading
                                            ? Colors.grey
                                            : colorScheme.secondary,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSingleColumnFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _restaurantNameController,
          label: 'Restaurant Name',
          hint: 'e.g. The Tasty Spoon',
          validator: (v) => Validators.validateRequired(v, 'Restaurant Name'),
          prefix: const Icon(Icons.restaurant),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _addressController,
          label: 'Restaurant Address',
          hint: 'Street, City, Country',
          validator: (v) => Validators.validateRequired(v, 'Address'),
          prefix: const Icon(Icons.location_on),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _cuisineTypeController,
          label: 'Cuisine Type',
          hint: 'e.g. Italian, African, Chinese',
          validator: (v) => Validators.validateRequired(v, 'Cuisine Type'),
          prefix: const Icon(Icons.fastfood),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _emailController,
          label: 'Admin Email',
          validator: (v) => _emailError ?? Validators.validateEmail(v),
          keyboardType: TextInputType.emailAddress,
          prefix: const Icon(Icons.email),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _passwordController,
          label: 'Admin Password',
          hint: 'Minimum 6 characters',
          validator: Validators.validatePassword,
          keyboardType: TextInputType.visiblePassword,
          prefix: const Icon(Icons.lock),
          obscureText: _obscurePassword,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          validator: (v) {
            if (v != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
          keyboardType: TextInputType.visiblePassword,
          prefix: const Icon(Icons.lock_outline),
          obscureText: _obscureConfirmPassword,
          suffix: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          validator: Validators.validatePhone,
          keyboardType: TextInputType.phone,
          prefix: const Icon(Icons.phone),
        ),
      ],
    );
  }

  Widget _buildTwoColumnFields() {
    return LayoutBuilder(builder: (context, constraints) {
      final gap = 16.0;
      final columnWidth = (constraints.maxWidth - gap) / 2;

      Widget leftColumn = SizedBox(
        width: columnWidth,
        child: Column(
          children: [
            _buildTextField(
              controller: _restaurantNameController,
              label: 'Restaurant Name',
              validator: (v) =>
                  Validators.validateRequired(v, 'Restaurant Name'),
              prefix: const Icon(Icons.restaurant),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _cuisineTypeController,
              label: 'Cuisine Type',
              validator: (v) => Validators.validateRequired(v, 'Cuisine Type'),
              prefix: const Icon(Icons.fastfood),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              validator: Validators.validatePhone,
              keyboardType: TextInputType.phone,
              prefix: const Icon(Icons.phone),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _passwordController,
              label: 'Admin Password',
              validator: Validators.validatePassword,
              keyboardType: TextInputType.visiblePassword,
              prefix: const Icon(Icons.lock),
              obscureText: _obscurePassword,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ],
        ),
      );

      Widget rightColumn = SizedBox(
        width: columnWidth,
        child: Column(
          children: [
            _buildTextField(
              controller: _addressController,
              label: 'Restaurant Address',
              validator: (v) => Validators.validateRequired(v, 'Address'),
              prefix: const Icon(Icons.location_on),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emailController,
              label: 'Admin Email',
              validator: Validators.validateEmail,
              keyboardType: TextInputType.emailAddress,
              prefix: const Icon(Icons.email),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              validator: (v) {
                if (v != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              keyboardType: TextInputType.visiblePassword,
              prefix: const Icon(Icons.lock_outline),
              obscureText: _obscureConfirmPassword,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
          ],
        ),
      );

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftColumn,
          SizedBox(width: gap),
          rightColumn,
        ],
      );
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefix,
    Widget? suffix,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
