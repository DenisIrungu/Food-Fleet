import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'super_admin', 'restaurant_admin', 'rider', 'customer'
  final String? restaurantId; // For restaurant admins and riders
  final String? restaurantName; // For restaurant admins & riders
  final String? fullName; // Used for rider or customer display name
  final String? phone; // New field for phone number
  final bool firstLogin; // For password reset requirement
  final DateTime createdAt;
  final String? profilePictureUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.restaurantId,
    this.restaurantName,
    this.fullName,
    this.phone,
    required this.firstLogin,
    required this.createdAt,
    this.profilePictureUrl,
  });

  // Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      restaurantId: data['restaurantId'],
      restaurantName: data['restaurantName'],
      fullName: data['fullName'],
      phone: data['phone'],
      firstLogin: data['firstLogin'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      profilePictureUrl: data['profilePictureUrl'],
    );
  }

  // Convert UserModel to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'fullName': fullName,
      'phone': phone,
      'firstLogin': firstLogin,
      'createdAt': Timestamp.fromDate(createdAt),
      'profilePictureUrl': profilePictureUrl,
    };
  }

  // Get display name based on role
  String get displayName {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'restaurant_admin':
        return restaurantName ?? 'Restaurant Admin';
      case 'rider':
        return fullName ?? 'Rider';
      case 'customer':
        return fullName ?? 'Customer';
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
    String? fullName,
    String? phone,
    bool? firstLogin,
    DateTime? createdAt,
    String? profilePictureUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      firstLogin: firstLogin ?? this.firstLogin,
      createdAt: createdAt ?? this.createdAt,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl, // Added
    );
  }
}
