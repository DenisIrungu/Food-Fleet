import 'package:flutter/material.dart';

class ActiveBadge extends StatelessWidget {
  final String status;

  const ActiveBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
        bgColor = Colors.green;
        label = 'Active';
        break;
      case 'inactive':
        bgColor = Colors.red;
        label = 'Inactive';
        break;
      default:
        bgColor = Colors.grey;
        label = 'Unknown';
    }

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
