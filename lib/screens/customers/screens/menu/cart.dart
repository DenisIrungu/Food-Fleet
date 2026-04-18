import 'package:flutter/material.dart';
import 'package:foodfleet/models/cart_models.dart';
import 'package:foodfleet/providers/cart_providers.dart';
import 'package:foodfleet/screens/customers/screens/payments/checkout/checkout_screen.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;

  const CartScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final items = cart.cartFor(restaurantId);

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F2A12),
            centerTitle: true,
            title: Column(
              children: [
                const Text(
                  'Your Cart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2A12),
                  ),
                ),
                Text(
                  restaurantName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            actions: [
              if (items.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _confirmClear(context, cart),
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 18),
                  label: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
          body: items.isEmpty
              ? _EmptyCart()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) => _CartItemTile(
                          item: items[index],
                          restaurantId: restaurantId,
                        ),
                      ),
                    ),
                    _OrderSummary(
                      cart: cart,
                      restaurantId: restaurantId,
                      restaurantName: restaurantName,
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _confirmClear(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              cart.clearCart(restaurantId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final String restaurantId;

  const _CartItemTile({required this.item, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.food.imageUrl.isNotEmpty
                ? Image.network(
                    item.food.imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.food.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2A12),
                  ),
                ),
                if (item.selectedAddonItems.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.selectedAddonItems.map((a) => a.name).join(', '),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ksh ${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2A12),
                      ),
                    ),
                    Row(
                      children: [
                        _QuantityButton(
                          icon: Icons.remove,
                          onTap: () =>
                              cart.decrementQuantity(restaurantId, item.id),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _QuantityButton(
                          icon: Icons.add,
                          onTap: () =>
                              cart.incrementQuantity(restaurantId, item.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.fastfood, color: Colors.grey),
      );
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2A12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final CartProvider cart;
  final String restaurantId;
  final String restaurantName;

  const _OrderSummary({
    required this.cart,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    final total = cart.totalPriceFor(restaurantId);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  'Ksh ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2A12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutScreen(
                        restaurantId: restaurantId,
                        restaurantName: restaurantName,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2A12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items from the menu to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
