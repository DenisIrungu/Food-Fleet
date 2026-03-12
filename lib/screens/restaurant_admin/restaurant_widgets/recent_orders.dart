import 'package:flutter/material.dart';

class RecentOrders extends StatelessWidget {
  final ColorScheme colors;
  const RecentOrders({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: colors.onSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _orderTile(colors, 'Order #1024', 'Preparing', 'Ksh 1,200'),
            _orderTile(colors, 'Order #1023', 'Ready', 'Ksh 850'),
            _orderTile(colors, 'Order #1022', 'Completed', 'Ksh 1,500'),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2A12),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {},
                child: const Text('View all orders'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTile(
      ColorScheme colors, String id, String status, String amount) {
    Color statusColor;
    if (status == 'Completed') {
      statusColor = Colors.green;
    } else if (status == 'Ready') {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.blue;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        id,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(Icons.circle, size: 10, color: statusColor),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(color: colors.onSurface.withOpacity(0.7)),
          ),
        ],
      ),
      trailing: Text(
        amount,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: colors.onSurface,
        ),
      ),
    );
  }
}
