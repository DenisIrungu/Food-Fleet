import 'package:flutter/material.dart';
import 'package:foodfleet/models/cart_models.dart';

// ─────────────────────────────────────────────
// ORDER SUMMARY CARD
// ─────────────────────────────────────────────
class CheckoutOrderSummaryCard extends StatelessWidget {
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;

  const CheckoutOrderSummaryCard({
    super.key,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          ...items.map((item) => CheckoutOrderItemTile(item: item)),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CheckoutSummaryRow(
                    label: 'Subtotal',
                    value: 'Ksh ${subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                CheckoutSummaryRow(
                    label: 'Delivery Fee',
                    value: deliveryFee == 0
                        ? 'Free'
                        : 'Ksh ${deliveryFee.toStringAsFixed(2)}'),
                if (discount > 0) ...[
                  const SizedBox(height: 4),
                  CheckoutSummaryRow(
                    label: 'Discount',
                    value: '- Ksh ${discount.toStringAsFixed(2)}',
                    isDiscount: true,
                  ),
                ],
                const Divider(height: 16),
                CheckoutSummaryRow(
                  label: 'Total',
                  value: 'Ksh ${total.toStringAsFixed(2)}',
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ORDER ITEM TILE
// ─────────────────────────────────────────────
class CheckoutOrderItemTile extends StatelessWidget {
  final CartItem item;
  const CheckoutOrderItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.food.imageUrl.isNotEmpty
                ? Image.network(item.food.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.food.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                if (item.selectedAddonItems.isNotEmpty)
                  Text(item.selectedAddonItems.map((a) => a.name).join(', '),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text('x${item.quantity}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text('Ksh ${item.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF0F2A12))),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 50,
        height: 50,
        color: Colors.grey.shade200,
        child: const Icon(Icons.fastfood, color: Colors.grey, size: 24),
      );
}

// ─────────────────────────────────────────────
// SUMMARY ROW
// ─────────────────────────────────────────────
class CheckoutSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isDiscount;

  const CheckoutSummaryRow(
      {super.key,
      required this.label,
      required this.value,
      this.isBold = false,
      this.isDiscount = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color:
                    isBold ? const Color(0xFF0F2A12) : Colors.grey.shade600)),
        Text(value,
            style: TextStyle(
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isDiscount ? Colors.green.shade700 : const Color(0xFF0F2A12))),
      ],
    );
  }
}
