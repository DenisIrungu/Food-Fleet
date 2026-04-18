import 'package:flutter/material.dart';
import 'package:foodfleet/screens/customers/screens/payments/checkout/checkout_controller.dart';
import 'package:foodfleet/screens/customers/screens/payments/checkout/checkout_widget.dart';

// ─────────────────────────────────────────────
// ADDRESS SECTION
// (Building type, access point, floor/unit,
//  instructions, preview, proceed button)
// ─────────────────────────────────────────────
class CheckoutAddressSection extends StatelessWidget {
  final String buildingType;
  final ValueChanged<String> onBuildingTypeChanged;
  final TextEditingController accessPointController;
  final TextEditingController floorUnitController;
  final TextEditingController instructionsController;
  final CheckoutController controller;
  final TextEditingController landmarkController;
  final VoidCallback onProceed;
  final Widget Function({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines,
  }) fieldBuilder;

  const CheckoutAddressSection({
    super.key,
    required this.buildingType,
    required this.onBuildingTypeChanged,
    required this.accessPointController,
    required this.floorUnitController,
    required this.instructionsController,
    required this.controller,
    required this.landmarkController,
    required this.onProceed,
    required this.fieldBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── BUILDING TYPE ──
        const CheckoutSectionLabel(label: '🏠 Building Type', required: true),
        const SizedBox(height: 6),
        BuildingTypeSelector(
          selected: buildingType,
          onChanged: onBuildingTypeChanged,
        ),
        const SizedBox(height: 16),

        // ── ACCESS POINT ──
        const CheckoutSectionLabel(
            label: '🚪 Access Point (Gate/Entrance)', required: true),
        const SizedBox(height: 6),
        fieldBuilder(
          controller: accessPointController,
          label: 'e.g. Blue gate, Gate 3, Main entrance',
          hint: 'What should the rider look for?',
          icon: Icons.door_front_door_outlined,
          validator: (v) =>
              v == null || v.isEmpty ? 'Access point is required' : null,
        ),

        // ── FLOOR/UNIT (apartments only) ──
        if (buildingType == 'apartment') ...[
          const SizedBox(height: 16),
          const CheckoutSectionLabel(
              label: '🏢 Floor / Unit Number', required: false),
          const SizedBox(height: 6),
          fieldBuilder(
            controller: floorUnitController,
            label: 'e.g. 3rd Floor, Apt 12B',
            hint: 'Floor and unit number',
            icon: Icons.elevator_outlined,
          ),
        ],
        const SizedBox(height: 16),

        // ── FINAL INSTRUCTIONS ──
        const CheckoutSectionLabel(
            label: '💬 Final Instructions', required: false),
        const SizedBox(height: 6),
        TextFormField(
          controller: instructionsController,
          maxLines: 2,
          maxLength: 120,
          decoration: InputDecoration(
            hintText: 'e.g. Turn at Quickmart, 2nd gate on left',
            prefixIcon:
                const Icon(Icons.notes_outlined, color: Color(0xFF0F2A12)),
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
        ),
        const SizedBox(height: 16),

        // ── DELIVERY PREVIEW ──
        if (landmarkController.text.isNotEmpty ||
            accessPointController.text.isNotEmpty)
          DeliveryPreviewCard(
            street: controller.detectedStreet,
            city: controller.detectedCity,
            landmark: landmarkController.text,
            buildingType: buildingType,
            accessPoint: accessPointController.text,
            floorUnit: floorUnitController.text,
            instructions: instructionsController.text,
          ),
        const SizedBox(height: 32),

        // ── PROCEED BUTTON ──
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onProceed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2A12),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Proceed to Payment',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
