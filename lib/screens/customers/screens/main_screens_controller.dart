import 'package:flutter/material.dart';
import 'package:foodfleet/components/bottomnavbar.dart';
import 'package:foodfleet/models/restaurant_model.dart';
import 'package:foodfleet/screens/customers/screens/menu/Home/homepage.dart';
import 'package:foodfleet/screens/customers/screens/menu/cart.dart';
import 'package:foodfleet/screens/customers/screens/menu/menu.dart';
import 'package:foodfleet/screens/customers/screens/menu/profile.dart';

class MainScreen extends StatefulWidget {
  final RestaurantModel restaurant;

  const MainScreen({super.key, required this.restaurant});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _goToCart() {
    setState(() => _selectedIndex = 2);
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return HomePage(restaurant: widget.restaurant);
      case 1:
        return MenuPage(
          restaurant: widget.restaurant,
          onCartTap: _goToCart,
        );
      case 2:
        return CartScreen(
          restaurantId: widget.restaurant.id,
          restaurantName: widget.restaurant.name,
        );
      case 3:
        return const ProfilePage();
      default:
        return HomePage(restaurant: widget.restaurant);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(_selectedIndex),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
