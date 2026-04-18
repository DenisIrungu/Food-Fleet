import 'package:flutter/material.dart';
import 'package:foodfleet/models/order_model.dart';
import 'package:foodfleet/screens/customers/screens/payments/mpesa/mpesa_payments_controller.dart';
import 'package:foodfleet/screens/customers/screens/payments/mpesa/mpesa_phone_input.dart';
import 'package:foodfleet/screens/customers/screens/payments/mpesa/mpesa_waiting_view.dart';

class MpesaPaymentPage extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final double amount;
  final OrderModel order;
  final String? discountCode;

  const MpesaPaymentPage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.amount,
    required this.order,
    this.discountCode,
  });

  @override
  State<MpesaPaymentPage> createState() => _MpesaPaymentPageState();
}

class _MpesaPaymentPageState extends State<MpesaPaymentPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late MpesaPaymentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MpesaPaymentController(
      restaurantId: widget.restaurantId,
      restaurantName: widget.restaurantName,
      amount: widget.amount,
      order: widget.order,
      discountCode: widget.discountCode,
    );
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _navigateToSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          restaurantName: widget.restaurantName,
          amount: widget.amount,
          orderId: widget.order.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_controller.stkSent) {
          await _controller.cancelPayment(context);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F2A12),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('M-Pesa Payment',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          leading: _controller.stkSent
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _controller.cancelPayment(context),
                )
              : null,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _controller.stkSent
                  ? MpesaWaitingView(
                      statusMessage: _controller.statusMessage,
                      pollingAttempts: _controller.pollingAttempts,
                      isLoading: _controller.isLoading,
                      onResend: () => _controller.resendPayment(context,
                          _phoneController.text.trim(), _navigateToSuccess),
                      onCancel: () => _controller.cancelPayment(context),
                    )
                  : MpesaPhoneInputView(
                      phoneController: _phoneController,
                      formKey: _formKey,
                      isLoading: _controller.isLoading,
                      statusMessage: _controller.statusMessage,
                      restaurantName: widget.restaurantName,
                      amount: widget.amount,
                      onPay: () {
                        if (_formKey.currentState!.validate()) {
                          _controller.initiatePayment(
                            context,
                            _phoneController.text.trim(),
                            _navigateToSuccess,
                          );
                        }
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
