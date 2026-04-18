import 'package:flutter/material.dart';
import 'package:foodfleet/providers/cart_providers.dart';
import 'package:foodfleet/screens/customers/screens/payments/checkout/checkout_address_section.dart';
import 'package:foodfleet/screens/customers/screens/payments/checkout/checkout_contact_section.dart';
import 'package:foodfleet/screens/customers/screens/payments/checkout/checkout_controller.dart';
import 'package:foodfleet/screens/customers/screens/payments/checkout/checkout_order_section.dart';
import 'package:foodfleet/screens/customers/screens/payments/checkout/checkout_widget.dart';
import 'package:foodfleet/screens/customers/screens/payments/select_payment_method.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const CheckoutScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _accessPointController = TextEditingController();
  final _floorUnitController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _landmarkFocusNode = FocusNode();

  String _buildingType = 'house';
  late CheckoutController _controller;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartProvider>();
    _controller = CheckoutController(
      restaurantId: widget.restaurantId,
      restaurantName: widget.restaurantName,
      cart: cart,
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _landmarkController.dispose();
    _accessPointController.dispose();
    _floorUnitController.dispose();
    _instructionsController.dispose();
    _landmarkFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _proceedToPayment() {
    if (!_formKey.currentState!.validate()) return;

    final order = _controller.buildOrder(
      phone: _phoneController.text.trim(),
      landmark: _landmarkController.text.trim(),
      buildingType: _buildingType,
      accessPoint: _accessPointController.text.trim(),
      floorUnit: _floorUnitController.text.trim(),
      instructions: _instructionsController.text.trim(),
    );

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SelectPaymentScreen(
            restaurantId: widget.restaurantId,
            restaurantName: widget.restaurantName,
            totalAmount: order.total,
            order: order,
            discountCode: _controller.appliedDiscountCode,
          ),
        ));
  }

  InputDecoration _inputDeco({required String label, required IconData icon}) =>
      InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0F2A12)),
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
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF0F2A12)),
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
      );

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.cartFor(widget.restaurantId);
    final subtotal = cart.totalPriceFor(widget.restaurantId);
    const deliveryFee = 0.0;
    final discount = _controller.discountAmount;
    final total = (subtotal + deliveryFee - discount).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2A12),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Checkout',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── ORDER SUMMARY ──
                  const CheckoutSectionTitle(title: 'Order Summary'),
                  const SizedBox(height: 8),
                  CheckoutOrderSummaryCard(
                      items: items,
                      subtotal: subtotal,
                      deliveryFee: deliveryFee,
                      discount: discount,
                      total: total),
                  const SizedBox(height: 16),

                  // ── DISCOUNT CODE ──
                  _DiscountCodeField(controller: _controller),
                  const SizedBox(height: 24),

                  // ── CONTACT + LOCATION ──
                  CheckoutContactSection(
                    phoneController: _phoneController,
                    inputDeco: _inputDeco,
                    fieldBuilder: _field,
                  ),
                  const SizedBox(height: 24),

                  CheckoutDeliveryLocationSection(
                    controller: _controller,
                    landmarkController: _landmarkController,
                    landmarkFocusNode: _landmarkFocusNode,
                    inputDeco: _inputDeco,
                  ),
                  const SizedBox(height: 16),

                  // ── ADDRESS + PROCEED ──
                  CheckoutAddressSection(
                    buildingType: _buildingType,
                    onBuildingTypeChanged: (val) =>
                        setState(() => _buildingType = val),
                    accessPointController: _accessPointController,
                    floorUnitController: _floorUnitController,
                    instructionsController: _instructionsController,
                    controller: _controller,
                    landmarkController: _landmarkController,
                    onProceed: _proceedToPayment,
                    fieldBuilder: _field,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── DISCOUNT CODE FIELD ──

class _DiscountCodeField extends StatefulWidget {
  final CheckoutController controller;
  const _DiscountCodeField({required this.controller});

  @override
  State<_DiscountCodeField> createState() => _DiscountCodeFieldState();
}

class _DiscountCodeFieldState extends State<_DiscountCodeField> {
  final _codeController = TextEditingController();
  static const _green = Color(0xFF0F2A12);

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final applied = ctrl.appliedDiscountCode != null;
    final msg = ctrl.discountMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                enabled: !applied,
                decoration: InputDecoration(
                  hintText: 'Discount code (e.g. FF-XXXXXXXX)',
                  prefixIcon: const Icon(Icons.local_offer, color: _green),
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
                      borderSide: const BorderSide(color: _green)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ctrl.isValidatingCode
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : applied
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Remove code',
                        onPressed: () {
                          _codeController.clear();
                          ctrl.validateDiscountCode('');
                        },
                      )
                    : ElevatedButton(
                        onPressed: () => ctrl
                            .validateDiscountCode(_codeController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        child: const Text('Apply',
                            style: TextStyle(color: Colors.white)),
                      ),
          ],
        ),
        if (msg.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              msg,
              style: TextStyle(
                fontSize: 13,
                color: applied ? Colors.green.shade700 : Colors.red.shade600,
              ),
            ),
          ),
      ],
    );
  }
}
