import 'package:cloud_firestore/cloud_firestore.dart';

enum AddonSelectionType {
  single,
  multiple,
}

class AddonGroupModel {
  final String id;
  final String restaurantId;

  final String name;
  final String? description;

  final AddonSelectionType selectionType;
  final bool required;
  final int minSelections;
  final int maxSelections;

  /// References MenuItemModel IDs (isAddon = true)
  final List<String> addonItemIds;

  final int position;

  final DateTime createdAt;
  final DateTime updatedAt;

  AddonGroupModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.selectionType,
    required this.required,
    required this.minSelections,
    required this.maxSelections,
    required this.addonItemIds,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore → Model
  factory AddonGroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return AddonGroupModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      selectionType: data['selectionType'] == 'multiple'
          ? AddonSelectionType.multiple
          : AddonSelectionType.single,
      required: data['required'] ?? false,
      minSelections: data['minSelections'] ?? 0,
      maxSelections: data['maxSelections'] ?? 1,
      addonItemIds: List<String>.from(data['addonItemIds'] ?? []),
      position: data['position'] ?? 0,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'selectionType':
          selectionType == AddonSelectionType.multiple ? 'multiple' : 'single',
      'required': required,
      'minSelections': minSelections,
      'maxSelections': maxSelections,
      'addonItemIds': addonItemIds,
      'position': position,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Safe updates
  AddonGroupModel copyWith({
    String? name,
    String? description,
    AddonSelectionType? selectionType,
    bool? required,
    int? minSelections,
    int? maxSelections,
    List<String>? addonItemIds,
    int? position,
  }) {
    return AddonGroupModel(
      id: id,
      restaurantId: restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      selectionType: selectionType ?? this.selectionType,
      required: required ?? this.required,
      minSelections: minSelections ?? this.minSelections,
      maxSelections: maxSelections ?? this.maxSelections,
      addonItemIds: addonItemIds ?? this.addonItemIds,
      position: position ?? this.position,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
