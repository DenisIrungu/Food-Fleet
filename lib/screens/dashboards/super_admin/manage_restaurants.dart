import 'package:flutter/material.dart';
import 'package:foodfleet/controllers/restaurant_controller.dart';
import 'package:foodfleet/models/restaurant_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ManageRestaurants extends StatelessWidget {
  const ManageRestaurants({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RestaurantController(),
      child: const ManageRestaurantsView(),
    );
  }
}

class ManageRestaurantsView extends StatefulWidget {
  const ManageRestaurantsView({super.key});

  @override
  State<ManageRestaurantsView> createState() => _ManageRestaurantsViewState();
}

class _ManageRestaurantsViewState extends State<ManageRestaurantsView> {
  XFile? _selectedImage;
  bool _isCreating = false;

  void _openAddRestaurantDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final cuisineController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return AnimatedPadding(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Add Restaurant (Admin)",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.tertiary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            setStateDialog(() => _selectedImage = null);
                            debugPrint("⚠️ Image picking temporarily disabled");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("⚠️ Image picking temporarily disabled"),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            child: _selectedImage == null
                                ? Icon(Icons.camera_alt,
                                    color: Theme.of(context).colorScheme.onSecondary)
                                : Icon(Icons.check_circle, color: Colors.green, size: 50),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildTextField("Restaurant Name*", nameController,
                            validator: (v) => v!.isEmpty ? 'Required' : null),
                        _buildTextField("Email*", emailController, validator: (v) {
                          if (v!.isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        }),
                        _buildTextField("Phone*", phoneController,
                            validator: (v) => v!.isEmpty ? 'Required' : null),
                        _buildTextField("Address*", addressController,
                            validator: (v) => v!.isEmpty ? 'Required' : null),
                        _buildTextField(
                          "Cuisine Types* (comma separated)",
                          cuisineController,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        _buildTextField(
                          "Admin Password*",
                          passwordController,
                          obscureText: true,
                          validator: (v) =>
                              v!.length < 6 ? 'Min 6 characters' : null,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Theme.of(context).colorScheme.onSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 25, vertical: 14),
                          ),
                          onPressed: _isCreating
                              ? null
                              : () async {
                                  print("🎯 Create button pressed");
                                  if (!formKey.currentState!.validate()) return;

                                  final controller =
                                      Provider.of<RestaurantController>(
                                    dialogContext,
                                    listen: false,
                                  );

                                  setStateDialog(() => _isCreating = true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('⏳ Creating restaurant...'),
                                    ),
                                  );

                                  print("🚀 Calling controller.createRestaurant()...");
                                  final success = await controller.createRestaurant(
                                    name: nameController.text.trim(),
                                    email: emailController.text.trim(),
                                    password: passwordController.text,
                                    phone: phoneController.text.trim(),
                                    address: addressController.text.trim(),
                                    cuisines: cuisineController.text
                                        .split(',')
                                        .map((e) => e.trim())
                                        .where((e) => e.isNotEmpty)
                                        .toList(),
                                    description: '',
                                    image: null,
                                  );
                                  print("✅ Controller returned: $success");

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  setStateDialog(() => _isCreating = false);

                                  if (success) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            '✅ Restaurant created successfully!'),
                                      ),
                                    );
                                    setStateDialog(() => _selectedImage = null);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('❌ Failed to create restaurant.'),
                                      ),
                                    );
                                  }
                                },
                          icon: _isCreating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: Text(
                            _isCreating ? "Creating..." : "Create Restaurant",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = context.watch<RestaurantController>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Manage Restaurants (Admins)",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondary,
                      ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.search, color: colorScheme.tertiary),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.filter_list, color: colorScheme.tertiary),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.tertiary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                      onPressed: _openAddRestaurantDialog,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Restaurant"),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Restaurants Grid
            Expanded(
              child: StreamBuilder<List<RestaurantModel>>(
                stream: controller.getRestaurantsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final restaurants = snapshot.data ?? [];

                  if (restaurants.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant,
                              size: 80, color: colorScheme.onSecondary),
                          const SizedBox(height: 16),
                          Text('No restaurants yet',
                              style: TextStyle(
                                  fontSize: 18, color: colorScheme.onSecondary)),
                          const SizedBox(height: 8),
                          Text('Click "Add Restaurant" to create one',
                              style: TextStyle(color: colorScheme.onSecondary)),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    itemCount: restaurants.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.4,
                    ),
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      return _buildRestaurantCard(restaurant, colorScheme);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(
      RestaurantModel restaurant, ColorScheme colorScheme) {
    return Card(
      color: colorScheme.secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // TODO: Edit functionality
                    },
                    icon: Icon(Icons.edit, color: colorScheme.onSecondary),
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(restaurant),
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: colorScheme.onSecondary.withOpacity(0.2),
                      backgroundImage: restaurant.imageUrl != null
                          ? NetworkImage(restaurant.imageUrl!)
                          : null,
                      child: restaurant.imageUrl == null
                          ? Icon(Icons.restaurant,
                              color: colorScheme.tertiary, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Text(
                      restaurant.name,
                      style: TextStyle(
                        color: colorScheme.tertiary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("📍 ${restaurant.address}",
                      style: TextStyle(color: colorScheme.onSecondary)),
                  Text("☎ ${restaurant.phone}",
                      style: TextStyle(color: colorScheme.onSecondary)),
                  Text("✉ ${restaurant.email}",
                      style: TextStyle(color: colorScheme.onSecondary)),
                  const SizedBox(height: 8),
                  Text("Cuisines: ${restaurant.cuisineTypes.join(', ')}",
                      style: TextStyle(color: colorScheme.onSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    "Status: ${restaurant.status}",
                    style: TextStyle(
                      color: restaurant.status == 'active'
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(RestaurantModel restaurant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Restaurant?'),
        content: Text('Are you sure you want to delete ${restaurant.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final controller = context.read<RestaurantController>();
      await controller.deleteRestaurant(restaurant);
    }
  }
}
