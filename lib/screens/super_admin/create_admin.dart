import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:foodfleet/models/restaurant_model.dart';
import 'package:foodfleet/services/auth_service.dart';
import 'package:foodfleet/utils/validators.dart';
import 'package:foodfleet/services/database_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CreateAdmin extends StatefulWidget {
  const CreateAdmin({super.key});

  @override
  State<CreateAdmin> createState() => _CreateAdminPageState();
}

class _CreateAdminPageState extends State<CreateAdmin> {
  final _formKey = GlobalKey<FormState>();

  final _restaurantNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _townController = TextEditingController();
  final _cuisineTypeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _databaseService = DatabaseService();
  final _authService = AuthService();
  final _picker = ImagePicker();

  bool _isLoading = false;
  bool _isLocating = false;
  String? _emailError;
  final bool _obscurePassword = true;
  final bool _obscureConfirmPassword = true;
  File? _selectedImage;

  double? _latitude;
  double? _longitude;

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
      _townController.text = args.town;
      _cuisineTypeController.text = args.cuisineTypes.join(', ');
      _emailController.text = args.email;
      _phoneController.text = args.phone;
      _latitude = args.latitude;
      _longitude = args.longitude;
      _whatsappController.text = args.whatsappNumber ?? '';
    }
  }

  // ── GET RESTAURANT LOCATION ──
  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permanently denied. Enable in settings.');
        if (!kIsWeb) await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Reverse geocode
      if (kIsWeb) {
        await _reverseGeocodeWeb(position.latitude, position.longitude);
      } else {
        await _reverseGeocodeMobile(position.latitude, position.longitude);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Restaurant location detected!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Could not detect location. Enter manually.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _reverseGeocodeMobile(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      setState(() {
        _addressController.text = [place.street, place.subLocality]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
        _townController.text =
            place.subAdministrativeArea ?? place.locality ?? '';
      });
    }
  }

  Future<void> _reverseGeocodeWeb(double lat, double lng) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=16&addressdetails=1');
    final response = await http.get(url, headers: {
      'Accept': 'application/json',
      'User-Agent': 'FoodFleet App',
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final address = data['address'] as Map<String, dynamic>?;
      if (address != null) {
        setState(() {
          _addressController.text = [
            address['road'] ?? '',
            address['suburb'] ?? address['neighbourhood'] ?? ''
          ].where((s) => s.isNotEmpty).join(', ');
          _townController.text = address['suburb'] ??
              address['town'] ??
              address['city_district'] ??
              address['city'] ??
              '';
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _emailError = null;
    });

    try {
      if (isEditMode) {
        await _databaseService.updateRestaurantData(
          _editingRestaurant!.id,
          {
            'name': _restaurantNameController.text.trim(),
            'address': _addressController.text.trim(),
            'town': _townController.text.trim(),
            'latitude': _latitude,
            'longitude': _longitude,
            'phone': _phoneController.text.trim(),
            'whatsappNumber': _whatsappController.text.trim().isEmpty
                ? null
                : _whatsappController.text.trim(),
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

      final restaurant = RestaurantModel(
        id: '',
        name: _restaurantNameController.text.trim(),
        adminUid: '',
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        whatsappNumber: _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
        address: _addressController.text.trim(),
        town: _townController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
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
      setState(() {
        _selectedImage = null;
        _latitude = null;
        _longitude = null;
      });
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
    _townController.dispose();
    _cuisineTypeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(isEditMode ? 'Edit Restaurant' : 'Register Restaurant Admin'),
        centerTitle: true,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _restaurantNameController,
                  label: 'Restaurant Name',
                  validator: (v) =>
                      Validators.validateRequired(v, 'Restaurant Name'),
                ),
                _buildTextField(
                  controller: _addressController,
                  label: 'Restaurant Address',
                  validator: (v) => Validators.validateRequired(v, 'Address'),
                ),

                // ── TOWN + LOCATION BUTTON ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _townController,
                        label: 'Town / Area (e.g. Kilimani, Westlands)',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Town is required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 12),
                      child: ElevatedButton.icon(
                        onPressed: _isLocating ? null : _detectLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2A12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isLocating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location,
                                color: Colors.white, size: 18),
                        label: Text(
                          _isLocating ? 'Detecting...' : 'Detect',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── COORDINATES DISPLAY ──
                if (_latitude != null && _longitude != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'GPS: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.green.shade800),
                          ),
                        ),
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 16),
                      ],
                    ),
                  ),
                ],

                _buildTextField(
                  controller: _cuisineTypeController,
                  label: 'Cuisine Type (comma separated)',
                  validator: (v) =>
                      Validators.validateRequired(v, 'Cuisine Type'),
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
                _buildTextField(
                  controller: _whatsappController,
                  label: 'WhatsApp Number (e.g. 254712345678)',
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
                    validator: (v) => v != _passwordController.text
                        ? 'Passwords do not match'
                        : null,
                    obscureText: _obscureConfirmPassword,
                  ),
                ],
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
