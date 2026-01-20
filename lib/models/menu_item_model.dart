import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemModel {
  final String id;

  /// Still stored for reference & analytics
  final String restaurantId;
  final String categoryId;

  final String name;
  final String? description;

  /// Image may be uploaded AFTER creation
  final String imageUrl;

  final double price;
  final bool isAvailable;
  final bool isAddon;

  /// References to addon groups (empty if none)
  final List<String> addonGroupIds;

  final int position;

  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItemModel({
    required this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.name,
    this.description,
    this.imageUrl = '', // ✅ SAFE DEFAULT
    required this.price,
    this.isAvailable = true,
    this.isAddon = false,
    this.addonGroupIds = const [],
    this.position = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ======================================================
  // Firestore → Model
  // ======================================================
  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return MenuItemModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      isAddon: data['isAddon'] ?? false,
      addonGroupIds: List<String>.from(data['addonGroupIds'] ?? []),
      position: data['position'] ?? 0,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // ======================================================
  // Model → Firestore
  // ======================================================
  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'isAvailable': isAvailable,
      'isAddon': isAddon,
      'addonGroupIds': addonGroupIds,
      'position': position,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ======================================================
  // CopyWith (SAFE UPDATES)
  // ======================================================
  MenuItemModel copyWith({
    String? id,
    String? restaurantId,
    String? categoryId,
    String? name,
    String? description,
    String? imageUrl,
    double? price,
    bool? isAvailable,
    bool? isAddon,
    List<String>? addonGroupIds,
    int? position,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      isAddon: isAddon ?? this.isAddon,
      addonGroupIds: addonGroupIds ?? this.addonGroupIds,
      position: position ?? this.position,
      createdAt: createdAt,
      updatedAt: DateTime.now(), 
    );
  }
}
