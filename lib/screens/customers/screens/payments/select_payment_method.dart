import 'package:flutter/material.dart';
import 'package:foodfleet/models/order_model.dart';
import 'package:foodfleet/screens/customers/screens/payments/mpesa/mpesa_page.dart';

class SelectPaymentScreen extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;
  final double totalAmount;
  final OrderModel order;
  final String? discountCode;

  const SelectPaymentScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.totalAmount,
    required this.order,
    this.discountCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F2A12),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Payment Option',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2A12),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Choose your payment method',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select how you would like to pay for your order',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 20),

                // ── ORDER TOTAL ──
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2A12).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Total',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F2A12),
                        ),
                      ),
                      Text(
                        'Ksh ${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2A12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── M-PESA ──
                _PaymentOptionCard(
                  icon: Icons.phone_android,
                  iconBgColor: const Color(0xFF4CAF50),
                  title: 'M-Pesa',
                  subtitle: 'Pay with mobile money',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MpesaPaymentPage(
                          restaurantId: restaurantId,
                          restaurantName: restaurantName,
                          amount: totalAmount,
                          order: order,
                          discountCode: discountCode,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ── CREDIT CARD ──
                _PaymentOptionCard(
                  icon: Icons.credit_card,
                  iconBgColor: const Color(0xFF1565C0),
                  title: 'Credit Card',
                  subtitle: 'Pay with credit/debit card',
                  onTap: () => _showComingSoon(context, 'Credit Card'),
                ),

                const SizedBox(height: 16),

                // ── REDEEM POINTS ──
                _PaymentOptionCard(
                  icon: Icons.redeem,
                  iconBgColor: const Color(0xFFF57C00),
                  title: 'Redeem Points',
                  subtitle: 'Use your loyalty points',
                  onTap: () => _showComingSoon(context, 'Redeem Points'),
                ),

                const SizedBox(height: 16),

                // ── CRYPTO ──
                _PaymentOptionCard(
                  icon: Icons.currency_bitcoin,
                  iconBgColor: const Color(0xFFF7931A),
                  title: 'Crypto',
                  subtitle: 'Pay with cryptocurrency',
                  comingSoon: true,
                  onTap: () => _showComingSoon(context, 'Crypto'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$method payment coming soon!'),
        backgroundColor: const Color(0xFF0F2A12),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PAYMENT OPTION CARD
// ─────────────────────────────────────────────

class _PaymentOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool comingSoon;

  const _PaymentOptionCard({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── ICON ──
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBgColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconBgColor, size: 28),
            ),

            const SizedBox(width: 16),

            // ── TEXT ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2A12),
                        ),
                      ),
                      if (comingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Coming Soon',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // ── ARROW ──
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
