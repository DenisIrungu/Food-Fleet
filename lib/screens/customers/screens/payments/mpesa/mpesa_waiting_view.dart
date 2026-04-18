import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// WAITING VIEW
// ─────────────────────────────────────────────
class MpesaWaitingView extends StatelessWidget {
  final String statusMessage;
  final int pollingAttempts;
  final bool isLoading;
  final VoidCallback onResend;
  final VoidCallback onCancel;

  const MpesaWaitingView({
    super.key,
    required this.statusMessage,
    required this.pollingAttempts,
    required this.isLoading,
    required this.onResend,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final secondsRemaining = (24 - pollingAttempts) * 5;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── SPINNER ──
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
              color: Colors.green.shade50, shape: BoxShape.circle),
          child: const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF0F2A12), strokeWidth: 3),
          ),
        ),
        const SizedBox(height: 32),

        const Text('Waiting for payment...',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2A12))),
        const SizedBox(height: 8),
        Text(statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Text('Expires in ~${secondsRemaining}s',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        const SizedBox(height: 32),

        // ── STEPS ──
        _buildStep(
            'Check your phone for the M-Pesa prompt', Icons.phone_android),
        const SizedBox(height: 16),
        _buildStep(
            'Enter your M-Pesa PIN to confirm payment', Icons.lock_outline),
        const SizedBox(height: 16),
        _buildStep(
            'Wait here for payment confirmation', Icons.check_circle_outline),
        const SizedBox(height: 32),

        // ── RESEND BUTTON ──
        OutlinedButton.icon(
          onPressed: isLoading ? null : onResend,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Resend M-Pesa Prompt'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0F2A12),
            side: const BorderSide(color: Color(0xFF0F2A12)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),

        // ── CANCEL BUTTON ──
        TextButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.close, size: 18, color: Colors.red),
          label:
              const Text('Cancel Payment', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildStep(String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
              color: Color(0xFF0F2A12), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// PAYMENT SUCCESS SCREEN
// ─────────────────────────────────────────────
class PaymentSuccessScreen extends StatelessWidget {
  final String restaurantName;
  final double amount;
  final String orderId;

  const PaymentSuccessScreen({
    super.key,
    required this.restaurantName,
    required this.amount,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── SUCCESS ICON ──
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                      color: Colors.green.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle,
                      color: Colors.green, size: 60),
                ),
                const SizedBox(height: 24),
                const Text('Payment Successful!',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2A12))),
                const SizedBox(height: 8),
                Text('Your order has been placed and confirmed.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 32),

                // ── ORDER DETAILS ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(children: [
                    _detailRow('Restaurant', restaurantName),
                    const Divider(height: 20),
                    _detailRow(
                        'Amount Paid', 'Ksh ${amount.toStringAsFixed(2)}'),
                    const Divider(height: 20),
                    _detailRow(
                        'Order ID', orderId.substring(0, 8).toUpperCase()),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── DELIVERY NOTE ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(children: [
                    Icon(Icons.delivery_dining, color: Colors.green.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your order is being prepared. You will be notified when it\'s on the way.',
                        style: TextStyle(
                            fontSize: 13, color: Colors.green.shade700),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 32),

                // ── BACK TO HOME ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2A12),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Back to Home',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2A12))),
        ),
      ],
    );
  }
}
