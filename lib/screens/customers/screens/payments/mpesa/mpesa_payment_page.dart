import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MpesaPaymentPage extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final double amount;
  final String orderId;

  const MpesaPaymentPage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.amount,
    required this.orderId,
  });

  @override
  State<MpesaPaymentPage> createState() => _MpesaPaymentPageState();
}

class _MpesaPaymentPageState extends State<MpesaPaymentPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _stkSent = false;
  bool _polling = false;
  String _statusMessage = '';
  String? _checkoutRequestId;
  Timer? _pollingTimer;

  // ── Cloud Function URLs ──
  static const String _stkPushUrl =
      'https://initiatestkpush-i66m6taedq-uc.a.run.app';
  static const String _queryStatusUrl =
      'https://querystkstatus-i66m6taedq-uc.a.run.app';

  @override
  void dispose() {
    _phoneController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  // ── INITIATE STK PUSH ──
  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      print('🔥 Calling STK Push...');
      final response = await http.post(
        Uri.parse(_stkPushUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'restaurantId': widget.restaurantId,
          'phone': _phoneController.text.trim(),
          'amount': widget.amount,
          'orderId': widget.orderId,
        }),
      );

      print('🔥 Response: ${response.statusCode} - ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _stkSent = true;
          _checkoutRequestId = data['checkoutRequestId'];
          _statusMessage =
              'STK push sent! Check your phone and enter your M-Pesa PIN.';
        });
        _startPolling();
      } else {
        setState(() {
          _statusMessage = data['responseDescription'] ??
              data['error'] ??
              'Payment initiation failed.';
        });
      }
    } catch (e) {
      print('🔥 Error: $e');
      setState(() {
        _statusMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── POLL FOR PAYMENT STATUS ──
  void _startPolling() {
    setState(() => _polling = true);
    int attempts = 0;

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      attempts++;

      if (attempts > 12) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _polling = false;
            _statusMessage = 'Payment timed out. Please try again.';
            _stkSent = false;
          });
        }
        return;
      }

      try {
        final response = await http.post(
          Uri.parse(_queryStatusUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'checkoutRequestId': _checkoutRequestId}),
        );

        final data = jsonDecode(response.body);
        final status = data['status'];

        if (status == 'success') {
          timer.cancel();
          if (mounted) {
            setState(() => _polling = false);
            _onPaymentSuccess();
          }
        } else if (status == 'failed') {
          timer.cancel();
          if (mounted) {
            setState(() {
              _polling = false;
              _stkSent = false;
              _statusMessage =
                  'Payment failed or was cancelled. Please try again.';
            });
          }
        }
      } catch (e) {
        // Keep polling on error
      }
    });
  }

  void _onPaymentSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _PaymentSuccessScreen(
          restaurantName: widget.restaurantName,
          amount: widget.amount,
          orderId: widget.orderId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2A12),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'M-Pesa Payment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _stkSent ? _buildWaitingView() : _buildPhoneInputView(),
        ),
      ),
    );
  }

  // ── PHONE INPUT VIEW ──
  Widget _buildPhoneInputView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_android,
              color: Colors.green,
              size: 40,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'M-Pesa Payment',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2A12),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            widget.restaurantName,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),

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
                const Text(
                  'Amount to Pay',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F2A12),
                  ),
                ),
                Text(
                  'Ksh ${widget.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2A12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── PHONE NUMBER ──
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'M-Pesa Phone Number',
              hintText: 'e.g. 0712345678',
              prefixIcon: const Icon(
                Icons.phone,
                color: Color(0xFF0F2A12),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0F2A12)),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Phone number is required';
              final cleaned = v.replaceAll(' ', '');
              if (!RegExp(r'^(07|01)\d{8}$').hasMatch(cleaned)) {
                return 'Enter a valid Kenyan phone number e.g. 0712345678';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // ── ERROR MESSAGE ──
          if (_statusMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 24),

          // ── PAY BUTTON ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _initiatePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2A12),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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

  // ── WAITING VIEW ──
  Widget _buildWaitingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          color: Color(0xFF0F2A12),
          strokeWidth: 3,
        ),
        const SizedBox(height: 32),
        const Text(
          'Waiting for payment...',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2A12),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        _buildStep('1', 'Check your phone for the M-Pesa prompt'),
        const SizedBox(height: 12),
        _buildStep('2', 'Enter your M-Pesa PIN'),
        const SizedBox(height: 12),
        _buildStep('3', 'Wait for confirmation'),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () {
            _pollingTimer?.cancel();
            setState(() {
              _stkSent = false;
              _polling = false;
              _statusMessage = '';
            });
          },
          child: const Text(
            'Did not receive prompt? Try again',
            style: TextStyle(color: Color(0xFF0F2A12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF0F2A12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// PAYMENT SUCCESS SCREEN
// ─────────────────────────────────────────────

class _PaymentSuccessScreen extends StatelessWidget {
  final String restaurantName;
  final double amount;
  final String orderId;

  const _PaymentSuccessScreen({
    required this.restaurantName,
    required this.amount,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2A12),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your order has been placed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
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
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _detailRow('Restaurant', restaurantName),
                    const Divider(height: 20),
                    _detailRow(
                        'Amount Paid', 'Ksh ${amount.toStringAsFixed(2)}'),
                    const Divider(height: 20),
                    _detailRow('Order ID', orderId),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F2A12),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
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
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2A12),
          ),
        ),
      ],
    );
  }
}
