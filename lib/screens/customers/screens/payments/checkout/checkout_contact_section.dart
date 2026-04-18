import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    as places_sdk;
import 'package:foodfleet/screens/customers/screens/payments/checkout/checkout_controller.dart';
import 'package:foodfleet/screens/customers/screens/payments/checkout/checkout_widget.dart';

// ─────────────────────────────────────────────
// CONTACT SECTION
// ─────────────────────────────────────────────
class CheckoutContactSection extends StatelessWidget {
  final TextEditingController phoneController;
  final InputDecoration Function(
      {required String label, required IconData icon}) inputDeco;
  final Widget Function({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines,
  }) fieldBuilder;

  const CheckoutContactSection({
    super.key,
    required this.phoneController,
    required this.inputDeco,
    required this.fieldBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CheckoutSectionTitle(title: 'Contact'),
        const SizedBox(height: 8),
        fieldBuilder(
          controller: phoneController,
          label: 'Phone Number',
          hint: 'e.g. 0712345678',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Phone number is required';
            if (!RegExp(r'^(07|01)\d{8}$').hasMatch(v.trim()))
              return 'Enter a valid Kenyan phone number';
            return null;
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// DELIVERY LOCATION SECTION
// ─────────────────────────────────────────────
class CheckoutDeliveryLocationSection extends StatelessWidget {
  final CheckoutController controller;
  final TextEditingController landmarkController;
  final FocusNode landmarkFocusNode;
  final InputDecoration Function(
      {required String label, required IconData icon}) inputDeco;

  const CheckoutDeliveryLocationSection({
    super.key,
    required this.controller,
    required this.landmarkController,
    required this.landmarkFocusNode,
    required this.inputDeco,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── HEADER + USE MY LOCATION ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const CheckoutSectionTitle(title: 'Delivery Location'),
            TextButton.icon(
              onPressed: controller.isLocating
                  ? null
                  : () => controller.useCurrentLocation(context),
              icon: controller.isLocating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF0F2A12)))
                  : const Icon(Icons.my_location,
                      size: 16, color: Color(0xFF0F2A12)),
              label: Text(
                controller.isLocating ? 'Detecting...' : 'Use My Location',
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F2A12),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── DETECTED LOCATION CHIP ──
        if (controller.detectedStreet.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(children: [
              const Icon(Icons.location_on, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${controller.detectedStreet}, ${controller.detectedCity}',
                  style: TextStyle(fontSize: 13, color: Colors.green.shade800),
                ),
              ),
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
            ]),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),

        // ── NEAREST LANDMARK ──
        const CheckoutSectionLabel(
            label: '📍 Nearest Landmark', required: true),
        const SizedBox(height: 6),
        TextFormField(
          controller: landmarkController,
          focusNode: landmarkFocusNode,
          onChanged: controller.onLandmarkChanged,
          decoration: inputDeco(
            label: 'e.g. Quickmart Kilimani, KCA University',
            icon: Icons.store_outlined,
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'Nearest landmark is required' : null,
        ),

        // ── LANDMARK SUGGESTIONS ──
        if (controller.showSuggestions)
          _LandmarkSuggestions(
            suggestions: controller.landmarkSuggestions,
            onSelect: (text) {
              landmarkController.text = text;
              controller.hideSuggestions();
              landmarkFocusNode.unfocus();
            },
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// LANDMARK SUGGESTIONS LIST
// ─────────────────────────────────────────────
class _LandmarkSuggestions extends StatelessWidget {
  final List<places_sdk.AutocompletePrediction> suggestions;
  final ValueChanged<String> onSelect;

  const _LandmarkSuggestions(
      {required this.suggestions, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestions.length,
        itemBuilder: (_, index) {
          final p = suggestions[index];
          return GestureDetector(
            onTapDown: (_) =>
                onSelect('${p.primaryText ?? ''}, ${p.secondaryText ?? ''}'),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.place_outlined,
                  color: Color(0xFF0F2A12), size: 18),
              title: Text(p.primaryText ?? '',
                  style: const TextStyle(fontSize: 14)),
              subtitle: Text(p.secondaryText ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ),
          );
        },
      ),
    );
  }
}
