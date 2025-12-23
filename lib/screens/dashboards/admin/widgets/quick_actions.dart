import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            int buttonsPerRow = constraints.maxWidth >= 800 ? 4 : 2;

            return GridView.count(
              crossAxisCount: buttonsPerRow,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: const [
                ActionBtn(Icons.add, 'Add Menu Item'),
                ActionBtn(Icons.receipt, 'View Orders'),
                ActionBtn(Icons.menu_book, 'Manage Menu'),
                ActionBtn(Icons.store, 'Edit Restaurant Info'),
              ],
            );
          },
        ),
      ],
    );
  }
}

class ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  const ActionBtn(this.icon, this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F2A12),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
