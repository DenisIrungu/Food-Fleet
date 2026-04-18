import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodfleet/models/order_model.dart';
import 'package:foodfleet/providers/cart_providers.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class MpesaPaymentController extends ChangeNotifier {
  final String restaurantId;
  final String restaurantName;
  final double amount;
  final OrderModel order;
  final String? discountCode;

  MpesaPaymentController({
    required this.restaurantId,
    required this.restaurantName,
    required this.amount,
    required this.order,
    this.discountCode,
  });

  static const String _stkPushUrl =
      'https://initiatestkpush-i66m6taedq-uc.a.run.app';
  static const String _queryStatusUrl =
      'https://querystkstatus-i66m6taedq-uc.a.run.app';

  bool isLoading = false;
  bool stkSent = false;
  bool polling = false;
  String statusMessage = '';
  String? checkoutRequestId;
  int pollingAttempts = 0;
  Timer? _pollingTimer;

  // ── INITIATE PAYMENT ──
  Future<void> initiatePayment(
      BuildContext context, String phone, VoidCallback onSuccess) async {
    isLoading = true;
    statusMessage = '';
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(_stkPushUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'restaurantId': restaurantId,
          'phone': phone,
          'amount': amount,
          'orderId': order.id,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        stkSent = true;
        checkoutRequestId = data['checkoutRequestId'];
        statusMessage =
            'STK push sent! Check your phone and enter your M-Pesa PIN.';
        pollingAttempts = 0;
        notifyListeners();
        startPolling(context, onSuccess);
      } else {
        statusMessage = data['responseDescription'] ??
            data['error'] ??
            'Payment initiation failed. Please try again.';
        notifyListeners();
      }
    } catch (e) {
      statusMessage =
          'Network error. Please check your connection and try again.';
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── RESEND PAYMENT ──
  Future<void> resendPayment(
      BuildContext context, String phone, VoidCallback onSuccess) async {
    _pollingTimer?.cancel();
    isLoading = true;
    stkSent = false;
    polling = false;
    statusMessage = '';
    pollingAttempts = 0;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(_stkPushUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'restaurantId': restaurantId,
          'phone': phone,
          'amount': amount,
          'orderId': order.id,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        stkSent = true;
        checkoutRequestId = data['checkoutRequestId'];
        statusMessage =
            'STK push resent! Check your phone and enter your M-Pesa PIN.';
        pollingAttempts = 0;
        notifyListeners();
        startPolling(context, onSuccess);
      } else {
        statusMessage = data['responseDescription'] ??
            data['error'] ??
            'Failed to resend. Please try again.';
        notifyListeners();
      }
    } catch (e) {
      statusMessage =
          'Network error. Please check your connection and try again.';
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── POLLING ──
  void startPolling(BuildContext context, VoidCallback onSuccess) {
    polling = true;
    notifyListeners();

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      pollingAttempts++;

      if (pollingAttempts > 24) {
        timer.cancel();
        polling = false;
        stkSent = false;
        statusMessage =
            'Payment timed out. The M-Pesa prompt may have expired. Please try again.';
        notifyListeners();
        return;
      }

      try {
        final response = await http.post(
          Uri.parse(_queryStatusUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'checkoutRequestId': checkoutRequestId,
            'restaurantId': restaurantId,
          }),
        );

        final data = jsonDecode(response.body);
        final status = data['status'];

        if (status == 'success') {
          timer.cancel();
          polling = false;
          notifyListeners();
          await onPaymentSuccess(context);
          onSuccess(); // ← trigger navigation
        } else if (status == 'failed') {
          timer.cancel();
          polling = false;
          stkSent = false;
          statusMessage = 'Payment was cancelled or failed. Please try again.';
          notifyListeners();
        }
      } catch (_) {
        // Keep polling on error
      }
    });
  }

  // ── CANCEL PAYMENT ──
  Future<void> cancelPayment(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Payment?',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF0F2A12))),
        content: const Text('Are you sure you want to cancel this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, Keep Waiting',
                style: TextStyle(color: Color(0xFF0F2A12))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      _pollingTimer?.cancel();
      stkSent = false;
      polling = false;
      statusMessage =
          'Payment cancelled. You can try again or choose a different payment method.';
      checkoutRequestId = null;
      pollingAttempts = 0;
      notifyListeners();
    }
  }

  // ── ON PAYMENT SUCCESS ──
  Future<void> onPaymentSuccess(BuildContext context) async {
    try {
      final paymentDoc = await FirebaseFirestore.instance
          .collection('payments')
          .doc(checkoutRequestId)
          .get();

      final mpesaCode = paymentDoc.data()?['mpesaCode'] ?? '';

      await FirebaseFirestore.instance.collection('orders').doc(order.id).set({
        ...order.toMap(),
        'status': 'confirmed',
        'paymentStatus': 'paid',
        'mpesaCode': mpesaCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (discountCode != null) {
        await FirebaseFirestore.instance
            .collection('discounts')
            .doc(discountCode)
            .update({'used': true});
      }

      if (context.mounted) {
        context.read<CartProvider>().clearCart(restaurantId);
      }
    } catch (e) {
      debugPrint('Error saving order: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
