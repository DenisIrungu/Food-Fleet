import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodfleet/models/menu_item_model.dart';
import 'package:foodfleet/models/restaurant_model.dart';
import 'package:foodfleet/screens/customers/screens/menu/Home/homepage_widget.dart';
import 'chefs_special.dart';
import 'top_of_week.dart';

class HomePage extends StatefulWidget {
  final RestaurantModel restaurant;

  const HomePage({super.key, required this.restaurant});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  Stream<List<MenuItemModel>>? _chefsSpecialStream;
  Stream<List<MenuItemModel>>? _topOfWeekStream;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  /// Fetch both category IDs in parallel, then set streams once
  Future<void> _initStreams() async {
    final results = await Future.wait([
      _getCategoryId("Chef's Special"),
      _getCategoryId('Top of the Week'),
    ]);

    if (!mounted) return;

    setState(() {
      if (results[0] != null) {
        _chefsSpecialStream = _buildItemsStream(results[0]!, limit: 1);
      }
      if (results[1] != null) {
        _topOfWeekStream = _buildItemsStream(results[1]!);
      }
    });
  }

  Future<String?> _getCategoryId(String categoryName) async {
    final snap = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(widget.restaurant.id)
        .collection('categories')
        .where('name', isEqualTo: categoryName)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Stream<List<MenuItemModel>> _buildItemsStream(String categoryId,
      {int? limit}) {
    var query = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(widget.restaurant.id)
        .collection('categories')
        .doc(categoryId)
        .collection('menu_items')
        .orderBy('position');

    if (limit != null) query = query.limit(limit);

    return query.snapshots().map(
          (snap) => snap.docs
              .map((d) => MenuItemModel.fromFirestore(d))
              .where((item) => item.isAvailable)
              .toList(),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: HomeAppBar(
        context: context,
        restaurant: widget.restaurant,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Search Bar
              HomeSearchBar(controller: _searchController),

              const SizedBox(height: 20),

              /// Restaurant Header
              RestaurantHeader(restaurant: widget.restaurant),

              const SizedBox(height: 20),

              /// Chef's Special
              _chefsSpecialStream == null
                  ? const ChefsSpecialSkeleton()
                  : ChefsSpecialSection(
                      stream: _chefsSpecialStream!,
                      restaurantId: widget.restaurant.id, // add this
                    ),

              const SizedBox(height: 25),

              /// Top of the Week Title
              const Text(
                "Top of the Week",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 15),

              /// Top of the Week
              _topOfWeekStream == null
                  ? const TopOfWeekSkeleton()
                  : TopOfWeekSection(
                      stream: _topOfWeekStream!,
                      restaurantId: widget.restaurant.id,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
