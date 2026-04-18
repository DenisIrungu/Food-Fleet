import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// SECTION TITLE
// ─────────────────────────────────────────────
class CheckoutSectionTitle extends StatelessWidget {
  final String title;
  const CheckoutSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F2A12)),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────
class CheckoutSectionLabel extends StatelessWidget {
  final String label;
  final bool required;
  const CheckoutSectionLabel(
      {super.key, required this.label, required this.required});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F2A12)),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: Colors.red, fontSize: 14)),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// BUILDING TYPE SELECTOR
// ─────────────────────────────────────────────
class BuildingTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const BuildingTypeSelector(
      {super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final types = [
      {'value': 'house', 'label': '🏠 House', 'icon': Icons.house_outlined},
      {
        'value': 'apartment',
        'label': '🏢 Apartment',
        'icon': Icons.apartment_outlined
      },
      {
        'value': 'office',
        'label': '🏛 Office',
        'icon': Icons.business_outlined
      },
      {'value': 'other', 'label': '📍 Other', 'icon': Icons.place_outlined},
    ];

    return Row(
      children: types.map((type) {
        final isSelected = selected == type['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type['value'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F2A12) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0F2A12)
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    type['icon'] as IconData,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (type['label'] as String).split(' ').last,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// DELIVERY PREVIEW CARD
// ─────────────────────────────────────────────
class DeliveryPreviewCard extends StatelessWidget {
  final String street;
  final String city;
  final String landmark;
  final String buildingType;
  final String accessPoint;
  final String floorUnit;
  final String instructions;

  const DeliveryPreviewCard({
    super.key,
    required this.street,
    required this.city,
    required this.landmark,
    required this.buildingType,
    required this.accessPoint,
    required this.floorUnit,
    required this.instructions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A12).withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0F2A12).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Delivery Summary Preview',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2A12),
                fontSize: 13),
          ),
          const SizedBox(height: 10),
          if (street.isNotEmpty) _previewRow('📍 Area', '$street, $city'),
          if (landmark.isNotEmpty) _previewRow('🏪 Near', landmark),
          _previewRow('🏠 Type',
              buildingType[0].toUpperCase() + buildingType.substring(1)),
          if (accessPoint.isNotEmpty) _previewRow('🚪 Look for', accessPoint),
          if (floorUnit.isNotEmpty) _previewRow('🏢 Floor/Unit', floorUnit),
          if (instructions.isNotEmpty) _previewRow('💬 Note', instructions),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F2A12))),
          ),
        ],
      ),
    );
  }
}
