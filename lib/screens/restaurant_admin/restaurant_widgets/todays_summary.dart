import 'package:flutter/material.dart';

class TodaysSummary extends StatelessWidget {
  const TodaysSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Summary",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            int itemsPerRow = constraints.maxWidth >= 800 ? 3 : 1;

            return GridView.count(
              crossAxisCount: itemsPerRow,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.0,
              children: const [
                SummaryItem(
                  '💵',
                  'Today\'s Revenue',
                  'Ksh 7,500',
                ),
                SummaryItem(
                  '📦',
                  'Orders Completed',
                  '18',
                ),
                SummaryItem(
                  '🔥',
                  'Top Selling Item',
                  'Grilled Tilapia',
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class SummaryItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;

  const SummaryItem(this.emoji, this.title, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
