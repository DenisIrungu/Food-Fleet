import 'package:flutter/material.dart';
import 'customer_location_screen.dart';
import 'customer_home_screen.dart';

class CustomerEntryScreen extends StatelessWidget {
  const CustomerEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 STATIC FOR NOW
    const bool hasLocation = false;

    if (hasLocation) {
      return const CustomerHomeScreen();
    } else {
      return const CustomerLocationScreen();
    }
  }
}
