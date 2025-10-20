import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'super_admin', 'restaurant_admin', 'rider', 'customer'
  final String? restaurantId; // For restaurant admins and riders
  final String? restaurantName; // Display name for restaurant
  final String? riderName; // For riders
  final String? customerName; // For customers
  final bool firstLogin; // Force password change on first login
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.restaurantId,
    this.restaurantName,
    this.riderName,
    this.customerName,
    required this.firstLogin,
    required this.createdAt,
  });

  // Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      restaurantId: data['restaurantId'],
      restaurantName: data['restaurantName'],
      riderName: data['riderName'],
      customerName: data['customerName'],
      firstLogin: data['firstLogin'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'riderName': riderName,
      'customerName': customerName,
      'firstLogin': firstLogin,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Get display name based on role
  String get displayName {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'restaurant_admin':
        return restaurantName ?? 'Restaurant';
      case 'rider':
        return riderName ?? 'Rider';
      case 'customer':
        return customerName ?? 'Customer';
      default:
        return 'User';
    }
  }

  // CopyWith method for updating specific fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? role,
    String? restaurantId,
    String? restaurantName,
    String? riderName,
    String? customerName,
    bool? firstLogin,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      riderName: riderName ?? this.riderName,
      customerName: customerName ?? this.customerName,
      firstLogin: firstLogin ?? this.firstLogin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
