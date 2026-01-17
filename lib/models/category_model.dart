import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String restaurantId;
  final String name;
  final String? description;
  final int position; // order in menu
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.position,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore
  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return CategoryModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      position: data['position'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'position': position,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with updates
  CategoryModel copyWith({
    String? name,
    String? description,
    int? position,
    bool? isActive,
  }) {
    return CategoryModel(
      id: id,
      restaurantId: restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      position: position ?? this.position,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
