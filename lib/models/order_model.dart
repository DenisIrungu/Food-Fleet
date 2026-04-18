import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// ORDER STATUS
// ─────────────────────────────────────────────
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

// ─────────────────────────────────────────────
// ORDER ITEM
// ─────────────────────────────────────────────
class OrderItem {
  final String foodId;
  final String foodName;
  final String foodImage;
  final int quantity;
  final double unitPrice;
  final List<String> addons;
  final double totalPrice;

  OrderItem({
    required this.foodId,
    required this.foodName,
    required this.foodImage,
    required this.quantity,
    required this.unitPrice,
    required this.addons,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() => {
        'foodId': foodId,
        'foodName': foodName,
        'foodImage': foodImage,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'addons': addons,
        'totalPrice': totalPrice,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        foodId: map['foodId'] ?? '',
        foodName: map['foodName'] ?? '',
        foodImage: map['foodImage'] ?? '',
        quantity: map['quantity'] ?? 1,
        unitPrice: (map['unitPrice'] as num).toDouble(),
        addons: List<String>.from(map['addons'] ?? []),
        totalPrice: (map['totalPrice'] as num).toDouble(),
      );
}

// ─────────────────────────────────────────────
// DELIVERY ADDRESS
// ─────────────────────────────────────────────
class DeliveryAddress {
  final double? latitude;
  final double? longitude;
  final String street;
  final String city;
  final String building;
  final String landmark;
  final String buildingType; // house, apartment, office, other
  final String accessPoint; // gate color/name/number
  final String floorUnit; // floor/unit (for apartments)
  final String instructions; // final short instructions

  DeliveryAddress({
    this.latitude,
    this.longitude,
    required this.street,
    required this.city,
    required this.building,
    required this.landmark,
    required this.buildingType,
    required this.accessPoint,
    required this.floorUnit,
    required this.instructions,
  });

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'street': street,
        'city': city,
        'building': building,
        'landmark': landmark,
        'buildingType': buildingType,
        'accessPoint': accessPoint,
        'floorUnit': floorUnit,
        'instructions': instructions,
      };

  factory DeliveryAddress.fromMap(Map<String, dynamic> map) => DeliveryAddress(
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        street: map['street'] ?? '',
        city: map['city'] ?? '',
        building: map['building'] ?? '',
        landmark: map['landmark'] ?? '',
        buildingType: map['buildingType'] ?? 'house',
        accessPoint: map['accessPoint'] ?? '',
        floorUnit: map['floorUnit'] ?? '',
        instructions: map['instructions'] ?? '',
      );

  String get summary {
    final parts = <String>[];
    if (landmark.isNotEmpty) parts.add('Near $landmark');
    if (accessPoint.isNotEmpty) parts.add(accessPoint);
    if (floorUnit.isNotEmpty) parts.add(floorUnit);
    if (instructions.isNotEmpty) parts.add(instructions);
    return parts.join(' · ');
  }
}

// ─────────────────────────────────────────────
// ORDER MODEL
// ─────────────────────────────────────────────
class OrderModel {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String customerId;
  final String customerEmail;
  final String customerPhone;
  final DeliveryAddress deliveryAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String? mpesaCode;
  final String? riderId;
  final String? riderName;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.customerId,
    required this.customerEmail,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    this.mpesaCode,
    this.riderId,
    this.riderName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'customerId': customerId,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'deliveryAddress': deliveryAddress.toMap(),
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'mpesaCode': mpesaCode,
        'riderId': riderId,
        'riderName': riderName,
        'status': status.value,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OrderModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      customerId: data['customerId'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      deliveryAddress: DeliveryAddress.fromMap(
          Map<String, dynamic>.from(data['deliveryAddress'] ?? {})),
      items: (data['items'] as List<dynamic>? ?? [])
          .map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i)))
          .toList(),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: data['paymentMethod'] ?? 'mpesa',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      mpesaCode: data['mpesaCode'],
      riderId: data['riderId'],
      riderName: data['riderName'],
      status: OrderStatusExtension.fromString(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
