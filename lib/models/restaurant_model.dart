import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantModel {
  final String id;
  final String name;
  final String adminUid;        // Links to the restaurant admin user
  final String email;
  final String phone;
  final String address;
  final List<String> cuisineTypes;
  final String? description;
  final String? imageUrl;
  final String status;          // 'active' or 'inactive'
  final DateTime createdAt;
  final DateTime updatedAt;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.adminUid,
    required this.email,
    required this.phone,
    required this.address,
    required this.cuisineTypes,
    this.description,
    this.imageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create RestaurantModel from Firestore document
  factory RestaurantModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return RestaurantModel(
      id: doc.id,
      name: data['name'] ?? '',
      adminUid: data['adminUid'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      cuisineTypes: List<String>.from(data['cuisineTypes'] ?? []),
      description: data['description'],
      imageUrl: data['imageUrl'],
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert RestaurantModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'adminUid': adminUid,
      'email': email,
      'phone': phone,
      'address': address,
      'cuisineTypes': cuisineTypes,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy with updated fields
  RestaurantModel copyWith({
    String? name,
    String? phone,
    String? address,
    List<String>? cuisineTypes,
    String? description,
    String? imageUrl,
    String? status,
  }) {
    return RestaurantModel(
      id: id,
      name: name ?? this.name,
      adminUid: adminUid,
      email: email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}