import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  final _databaseService = DatabaseService();
  final _authService = AuthService();
  final _picker = ImagePicker();

  bool _isLoading = false;
  String? _emailError;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _selectedImage;

  RestaurantModel? _editingRestaurant;
  bool get isEditMode => _editingRestaurant != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is RestaurantModel && _editingRestaurant == null) {
      _editingRestaurant = args;

      _restaurantNameController.text = args.name;
      _addressController.text = args.address;
      _cuisineTypeController.text = args.cuisineTypes.join(', ');
      _emailController.text = args.email;
      _phoneController.text = args.phone;
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _emailError = null;
    });

    try {
      /// ✏️ EDIT MODE
      if (isEditMode) {
        await _databaseService.updateRestaurantData(
          _editingRestaurant!.id,
          {
            'name': _restaurantNameController.text.trim(),
            'address': _addressController.text.trim(),
            'phone': _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'cuisineTypes': _cuisineTypeController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
            'updatedAt': DateTime.now(),
          },
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Restaurant updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
        return;
      }

      /// ➕ CREATE MODE (UNCHANGED)
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

      final restaurantId = await _databaseService.createRestaurant(restaurant);

      final adminUser = await _authService.createRestaurantAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        restaurantId: restaurantId,
        restaurantName: restaurant.name,
      );

      if (_selectedImage != null && adminUser != null) {
        final profileUrl = await _databaseService.updateProfilePicture(
          adminUser.uid,
          _selectedImage!,
        );
        await _databaseService.updateUser(
          adminUser.uid,
          {'profilePictureUrl': profileUrl},
        );
      }

      await _databaseService.updateRestaurantData(
        restaurantId,
        {'adminUid': adminUser!.uid},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Restaurant & Admin created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _formKey.currentState!.reset();
      setState(() => _selectedImage = null);
    } catch (e) {
      if (e.toString().toLowerCase().contains('email')) {
        _emailError = 'This email is already registered';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_emailError ?? '❌ Operation failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
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
        title:
            Text(isEditMode ? 'Edit Restaurant' : 'Register Restaurant Admin'),
        centerTitle: true,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                isWide ? _buildTwoColumnFields() : _buildSingleColumnFields(),
                const SizedBox(height: 20),
                if (!isEditMode)
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Select Image'),
                  ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submitForm,
                        child: Text(
                          isEditMode
                              ? 'Update Restaurant'
                              : 'Add Restaurant Admin',
                        ),
                      ),
              ],
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
          validator: (v) => Validators.validateRequired(v, 'Restaurant Name'),
        ),
        _buildTextField(
          controller: _addressController,
          label: 'Restaurant Address',
          validator: (v) => Validators.validateRequired(v, 'Address'),
        ),
        _buildTextField(
          controller: _cuisineTypeController,
          label: 'Cuisine Type',
          validator: (v) => Validators.validateRequired(v, 'Cuisine Type'),
        ),
        _buildTextField(
          controller: _emailController,
          label: 'Admin Email',
          validator: Validators.validateEmail,
        ),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          validator: Validators.validatePhone,
        ),
        if (!isEditMode) ...[
          _buildTextField(
            controller: _passwordController,
            label: 'Admin Password',
            validator: Validators.validatePassword,
            obscureText: _obscurePassword,
          ),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            validator: (v) =>
                v != _passwordController.text ? 'Passwords do not match' : null,
            obscureText: _obscureConfirmPassword,
          ),
        ],
      ],
    );
  }

  Widget _buildTwoColumnFields() => _buildSingleColumnFields();

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
