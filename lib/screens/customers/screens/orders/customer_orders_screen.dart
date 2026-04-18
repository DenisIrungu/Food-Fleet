import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodfleet/models/order_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerOrdersScreen extends StatelessWidget {
  final bool delivered;

  const CustomerOrdersScreen({super.key, required this.delivered});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final activeStatuses = ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery'];

    final query = FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: uid)
        .where('status', whereIn: delivered ? ['delivered'] : activeStatuses);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          delivered ? 'Delivered Orders' : 'Pending Orders',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    delivered
                        ? Icons.check_circle_outline
                        : Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    delivered
                        ? 'No delivered orders yet'
                        : 'No active orders',
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final orders = docs
              .map((d) => OrderModel.fromFirestore(d))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, i) =>
                _OrderCard(order: orders[i]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  static const _green = Color(0xFF0F2A12);

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.teal;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  Future<void> _openWhatsApp(String restaurantId, String orderId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();
      final data = doc.data();
      final number = data?['whatsappNumber'] as String?;

      if (number == null || number.isEmpty) return;

      final message = Uri.encodeComponent(
          'Hi, I have a question about my order #${orderId.substring(0, 8).toUpperCase()}');
      final uri = Uri.parse('https://wa.me/$number?text=$message');
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');
    final itemsSummary = order.items
        .map((i) => '${i.quantity}x ${i.foodName}')
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0F2A12), width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.restaurantName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _statusColor(order.status), width: 1),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                        fontSize: 12,
                        color: _statusColor(order.status),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── ORDER ID ──
            Text(
              'Order #${order.id.substring(0, 8).toUpperCase()}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 6),

            // ── ITEMS ──
            Text(
              itemsSummary,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── FOOTER ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KES ${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _green),
                    ),
                    Text(
                      fmt.format(order.createdAt),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () =>
                      _openWhatsApp(order.restaurantId, order.id),
                  icon: const Icon(Icons.chat, size: 16, color: _green),
                  label: const Text(
                    'Chat with Restaurant',
                    style: TextStyle(color: _green, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: _green),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
