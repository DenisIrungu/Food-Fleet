import 'dart:math';

class DeliveryFeeService {
  // ── FEE STRUCTURE ──
  static const double _baseFee = 50.0; // Covers first 3km
  static const double _baseKm = 3.0; // Free km included in base
  static const double _perKmRate = 20.0; // Per km after base
  static const double _maxFee = 300.0; // Maximum delivery fee
  static const double _freeDeliveryThreshold =
      1500.0; // Free above this order amount

  /// Calculate delivery fee based on distance
  static double calculateFee({
    required double orderAmount,
    required double distanceKm,
  }) {
    // Free delivery for large orders
    if (orderAmount >= _freeDeliveryThreshold) return 0.0;

    if (distanceKm <= _baseKm) {
      return _baseFee;
    }

    final extraKm = distanceKm - _baseKm;
    final fee = _baseFee + (extraKm * _perKmRate);
    return fee.clamp(0, _maxFee);
  }

  /// Calculate straight-line distance between two GPS points (Haversine formula)
  static double calculateDistanceKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const earthRadiusKm = 6371.0;

    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  /// Get fee breakdown for display
  static Map<String, dynamic> getFeeBreakdown({
    required double orderAmount,
    required double distanceKm,
  }) {
    final fee = calculateFee(orderAmount: orderAmount, distanceKm: distanceKm);
    final isFree = orderAmount >= _freeDeliveryThreshold;
    final amountToFreeDelivery = _freeDeliveryThreshold - orderAmount;

    return {
      'fee': fee,
      'distanceKm': distanceKm,
      'isFree': isFree,
      'amountToFreeDelivery':
          amountToFreeDelivery > 0 ? amountToFreeDelivery : 0,
      'freeDeliveryThreshold': _freeDeliveryThreshold,
    };
  }
}
