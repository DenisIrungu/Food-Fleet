import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodfleet/controllers/restaurant_controller.dart';
import 'package:foodfleet/models/restaurant_model.dart';
import 'package:foodfleet/models/user_model.dart'; // New import for UserModel
import 'package:foodfleet/services/database_service.dart'; // New import for fetching user data
import 'package:foodfleet/utils/routes.dart';

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
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RestaurantController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("Manage Restaurants (Admins)"),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, CREATE_ADMIN);
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Add Restaurant",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔍 Search + Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search restaurants...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (value) {
                    setState(() {
                      _filterStatus = value;
                    });
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'all', child: Text('All')),
                    PopupMenuItem(value: 'active', child: Text('Active')),
                    PopupMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// 🧩 Responsive Grid
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;

                  if (constraints.maxWidth >= 1200) {
                    crossAxisCount = 4; // Desktop
                  } else if (constraints.maxWidth >= 900) {
                    crossAxisCount = 3; // Tablet landscape
                  } else if (constraints.maxWidth >= 600) {
                    crossAxisCount = 2; // Tablet portrait
                  }

                  return StreamBuilder<List<RestaurantModel>>(
                    stream: controller.getRestaurantsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      var restaurants = snapshot.data ?? [];

                      restaurants = restaurants.where((r) {
                        final matchesSearch =
                            r.name.toLowerCase().contains(_searchQuery);
                        final matchesFilter = _filterStatus == 'all'
                            ? true
                            : r.status.toLowerCase() == _filterStatus;
                        return matchesSearch && matchesFilter;
                      }).toList();

                      if (restaurants.isEmpty) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.info_outline,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'No restaurants match your search',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        );
                      }

                      return GridView.builder(
                        itemCount: restaurants.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1.3,
                        ),
                        itemBuilder: (context, index) {
                          return _buildRestaurantCard(
                            context,
                            restaurants[index],
                            colorScheme,
                          );
                        },
                      );
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

  /// 🧱 Scroll-safe card
  Widget _buildRestaurantCard(
    BuildContext context,
    RestaurantModel restaurant,
    ColorScheme colorScheme,
  ) {
    return FutureBuilder<UserModel?>(
      future: DatabaseService().getUserData(
          restaurant.adminUid), // Fetch admin user for profile picture
      builder: (context, snapshot) {
        String? profilePictureUrl;
        String initial =
            restaurant.name.isNotEmpty ? restaurant.name[0].toUpperCase() : 'R';

        if (snapshot.hasData) {
          final user = snapshot.data;
          profilePictureUrl = user?.profilePictureUrl;
          initial = user?.restaurantName?.isNotEmpty == true
              ? user!.restaurantName![0].toUpperCase()
              : 'R';
        }

        return Card(
          color: colorScheme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              CREATE_ADMIN,
                              arguments: restaurant, // 👈 pass restaurant
                            );
                          },
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            context
                                .read<RestaurantController>()
                                .deleteRestaurant(restaurant);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: colorScheme.onSecondary.withOpacity(0.2),
                      backgroundImage: profilePictureUrl != null
                          ? NetworkImage(profilePictureUrl)
                          : null,
                      child: profilePictureUrl == null
                          ? Text(initial,
                              style: const TextStyle(
                                  fontSize: 40, color: Colors.white))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      restaurant.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.tertiary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("📍 ${restaurant.address}"),
                  Text("☎ ${restaurant.phone}"),
                  Text("✉ ${restaurant.email}"),
                  const SizedBox(height: 6),
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
          ),
        );
      },
    );
  }
}
