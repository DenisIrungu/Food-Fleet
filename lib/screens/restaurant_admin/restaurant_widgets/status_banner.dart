import 'package:flutter/material.dart';

class StatusBanner extends StatelessWidget {
  final ColorScheme colors;
  const StatusBanner({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: const [
          Icon(Icons.check_circle, color: Colors.green, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your restaurant is currently active and receiving orders.',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
