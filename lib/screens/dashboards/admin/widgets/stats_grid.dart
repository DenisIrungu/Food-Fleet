import 'package:flutter/material.dart';

class StatsGrid extends StatelessWidget {
  final double width;
  const StatsGrid({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    int count = width >= 1200 ? 4 : (width >= 800 ? 2 : 1);

    return GridView.count(
      crossAxisCount: count,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.6,
      children: const [
        StatCard('12', 'New Orders', Icons.notifications, Colors.blue),
        StatCard('5', 'Preparing', Icons.kitchen, Colors.orange),
        StatCard('3', 'Ready for Pickup', Icons.delivery_dining, Colors.green),
        StatCard('18', 'Completed Today', Icons.check_circle, Colors.black),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;

  const StatCard(this.value, this.label, this.icon, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
