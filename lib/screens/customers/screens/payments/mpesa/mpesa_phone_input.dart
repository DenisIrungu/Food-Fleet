import 'package:flutter/material.dart';

class MpesaPhoneInputView extends StatelessWidget {
  final TextEditingController phoneController;
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final String statusMessage;
  final VoidCallback onPay;

  final String restaurantName;
  final double amount;

  const MpesaPhoneInputView({
    super.key,
    required this.phoneController,
    required this.formKey,
    required this.isLoading,
    required this.statusMessage,
    required this.onPay,
    required this.restaurantName,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── ICON ──
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: Colors.green.shade50, shape: BoxShape.circle),
            child:
                const Icon(Icons.phone_android, color: Colors.green, size: 40),
          ),
          const SizedBox(height: 24),

          // ── TITLE ──
          const Text('M-Pesa Payment',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2A12))),
          const SizedBox(height: 8),
          Text(restaurantName,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),

          // ── AMOUNT ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2A12).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount to Pay',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F2A12))),
                Text('Ksh ${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2A12))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── PHONE FIELD ──
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'M-Pesa Phone Number',
              hintText: 'e.g. 0712345678',
              prefixIcon: const Icon(Icons.phone, color: Color(0xFF0F2A12)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0F2A12))),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Phone number is required';
              if (!RegExp(r'^(07|01)\d{8}$').hasMatch(v.replaceAll(' ', '')))
                return 'Enter a valid Kenyan phone number e.g. 0712345678';
              return null;
            },
          ),
          const SizedBox(height: 12),

          // ── STATUS MESSAGE ──
          if (statusMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusMessage.contains('cancelled')
                    ? Colors.orange.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: statusMessage.contains('cancelled')
                      ? Colors.orange.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Row(children: [
                Icon(
                  statusMessage.contains('cancelled')
                      ? Icons.info_outline
                      : Icons.error_outline,
                  color: statusMessage.contains('cancelled')
                      ? Colors.orange.shade700
                      : Colors.red.shade700,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(statusMessage,
                      style: TextStyle(
                        color: statusMessage.contains('cancelled')
                            ? Colors.orange.shade700
                            : Colors.red.shade700,
                        fontSize: 13,
                      )),
                ),
              ]),
            ),
          const SizedBox(height: 24),

          // ── PAY BUTTON ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2A12),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Pay Now',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You will receive an STK push on your phone.\nEnter your M-Pesa PIN to complete payment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
