import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantModel {
  final String id;
  final String name;
  final String adminUid;
  final String email;
  final String phone;
  final String? whatsappNumber;
  final String address;
  final String town;
  final double? latitude;
  final double? longitude;
  final List<String> cuisineTypes;
  final String? description;
  final String? imageUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.adminUid,
    required this.email,
    required this.phone,
    this.whatsappNumber,
    required this.address,
    required this.town,
    this.latitude,
    this.longitude,
    required this.cuisineTypes,
    this.description,
    this.imageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RestaurantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RestaurantModel(
      id: doc.id,
      name: data['name'] ?? '',
      adminUid: data['adminUid'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      whatsappNumber: data['whatsappNumber'],
      address: data['address'] ?? '',
      town: data['town'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      cuisineTypes: List<String>.from(data['cuisineTypes'] ?? []),
      description: data['description'],
      imageUrl: data['imageUrl'],
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'adminUid': adminUid,
      'email': email,
      'phone': phone,
      'whatsappNumber': whatsappNumber,
      'address': address,
      'town': town,
      'latitude': latitude,
      'longitude': longitude,
      'cuisineTypes': cuisineTypes,
      'description': description,
      'imageUrl': imageUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RestaurantModel copyWith({
    String? name,
    String? phone,
    String? whatsappNumber,
    String? address,
    String? town,
    double? latitude,
    double? longitude,
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
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      address: address ?? this.address,
      town: town ?? this.town,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
