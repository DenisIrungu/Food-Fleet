import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    as places_sdk;
import 'package:foodfleet/models/order_model.dart';
import 'package:foodfleet/providers/cart_providers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

const kGoogleApiKey = 'AIzaSyA7OCazA6ZKzBS-79Gnd6y2Mf7mpLHj9DA';

class CheckoutController extends ChangeNotifier {
  final String restaurantId;
  final String restaurantName;
  final CartProvider cart;

  CheckoutController({
    required this.restaurantId,
    required this.restaurantName,
    required this.cart,
  }) {
    _places = places_sdk.FlutterGooglePlacesSdk(kGoogleApiKey);
  }

  // ── STATE ──
  bool isLocating = false;
  double? lat;
  double? lng;
  String detectedStreet = '';
  String detectedCity = '';
  List<places_sdk.AutocompletePrediction> landmarkSuggestions = [];
  bool showSuggestions = false;

  // ── DISCOUNT ──
  String? appliedDiscountCode;
  double discountAmount = 0;
  bool isValidatingCode = false;
  String discountMessage = '';

  Future<void> validateDiscountCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) {
      appliedDiscountCode = null;
      discountAmount = 0;
      discountMessage = '';
      notifyListeners();
      return;
    }

    isValidatingCode = true;
    discountMessage = '';
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final doc = await FirebaseFirestore.instance
          .collection('discounts')
          .doc(trimmed)
          .get();

      if (!doc.exists) {
        appliedDiscountCode = null;
        discountAmount = 0;
        discountMessage = 'Invalid discount code.';
      } else {
        final data = doc.data()!;
        final isUsed = data['used'] as bool? ?? false;
        final ownerUid = data['uid'] as String? ?? '';
        final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
        final amount = (data['discountAmount'] as num?)?.toDouble() ?? 0;

        if (isUsed) {
          appliedDiscountCode = null;
          discountAmount = 0;
          discountMessage = 'This code has already been used.';
        } else if (ownerUid != uid) {
          appliedDiscountCode = null;
          discountAmount = 0;
          discountMessage = 'This code does not belong to your account.';
        } else if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
          appliedDiscountCode = null;
          discountAmount = 0;
          discountMessage = 'This code has expired.';
        } else {
          appliedDiscountCode = trimmed;
          discountAmount = amount;
          discountMessage = 'KES ${amount.toStringAsFixed(0)} discount applied!';
        }
      }
    } catch (_) {
      discountMessage = 'Could not validate code. Try again.';
    } finally {
      isValidatingCode = false;
      notifyListeners();
    }
  }

  late places_sdk.FlutterGooglePlacesSdk _places;

  // ── LOCATION ──
  Future<void> useCurrentLocation(BuildContext context) async {
    isLocating = true;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError(context, 'Location services disabled. Please enable GPS.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError(context, 'Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError(context, 'Location permanently denied. Enable in settings.');
        if (!kIsWeb) await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      lat = position.latitude;
      lng = position.longitude;
      notifyListeners();

      if (kIsWeb) {
        await _reverseGeocodeWeb(position.latitude, position.longitude);
      } else {
        await _reverseGeocodeMobile(position.latitude, position.longitude);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              const Text('📍 Location detected! Fill in remaining details.'),
          backgroundColor: const Color(0xFF0F2A12),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    } catch (e) {
      _showError(
          context, 'Could not get location. Please enter address manually.');
    } finally {
      isLocating = false;
      notifyListeners();
    }
  }

  Future<void> _reverseGeocodeMobile(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      detectedStreet = [place.street, place.subLocality]
          .where((s) => s != null && s.isNotEmpty)
          .join(', ');
      detectedCity = place.locality ?? place.administrativeArea ?? '';
      notifyListeners();
    }
  }

  Future<void> _reverseGeocodeWeb(double lat, double lng) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1');
    final response = await http.get(url,
        headers: {'Accept': 'application/json', 'User-Agent': 'FoodFleet App'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final address = data['address'] as Map<String, dynamic>?;
      if (address != null) {
        final street = address['road'] ??
            address['pedestrian'] ??
            address['path'] ??
            address['footway'] ??
            address['street'] ??
            '';
        final suburb = address['suburb'] ??
            address['neighbourhood'] ??
            address['quarter'] ??
            '';
        final city = address['city'] ??
            address['town'] ??
            address['municipality'] ??
            address['village'] ??
            address['county'] ??
            '';
        detectedStreet = [street, suburb].where((s) => s.isNotEmpty).join(', ');
        detectedCity = city;
        notifyListeners();
      }
    }
  }

  // ── LANDMARK AUTOCOMPLETE ──
  Future<void> onLandmarkChanged(String value) async {
    if (value.length < 2) {
      showSuggestions = false;
      notifyListeners();
      return;
    }
    try {
      final result = await _places.findAutocompletePredictions(
        value,
        countries: ['KE'],
        placeTypesFilter: [places_sdk.PlaceTypeFilter.ESTABLISHMENT],
        locationBias: lat != null
            ? places_sdk.LatLngBounds(
                southwest:
                    places_sdk.LatLng(lat: lat! - 0.05, lng: lng! - 0.05),
                northeast:
                    places_sdk.LatLng(lat: lat! + 0.05, lng: lng! + 0.05),
              )
            : null,
      );
      landmarkSuggestions = result.predictions;
      showSuggestions = result.predictions.isNotEmpty;
      notifyListeners();
    } catch (_) {}
  }

  void hideSuggestions() {
    showSuggestions = false;
    notifyListeners();
  }

  // ── BUILD ORDER ──
  OrderModel buildOrder({
    required String phone,
    required String landmark,
    required String buildingType,
    required String accessPoint,
    required String floorUnit,
    required String instructions,
  }) {
    final items = cart.cartFor(restaurantId);
    final subtotal = cart.totalPriceFor(restaurantId);
    const deliveryFee = 0.0;
    final total = (subtotal + deliveryFee - discountAmount).clamp(0, double.infinity).toDouble();
    final user = FirebaseAuth.instance.currentUser;
    final orderId = const Uuid().v4();

    final orderItems = items
        .map((c) => OrderItem(
              foodId: c.food.id,
              foodName: c.food.name,
              foodImage: c.food.imageUrl,
              quantity: c.quantity,
              unitPrice: c.food.price,
              addons: c.selectedAddonItems.map((a) => a.name).toList(),
              totalPrice: c.totalPrice,
            ))
        .toList();

    return OrderModel(
      id: orderId,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      customerId: user?.uid ?? '',
      customerEmail: user?.email ?? '',
      customerPhone: phone,
      deliveryAddress: DeliveryAddress(
        latitude: lat,
        longitude: lng,
        street: detectedStreet,
        city: detectedCity,
        building: buildingType,
        landmark: landmark,
        buildingType: buildingType,
        accessPoint: accessPoint,
        floorUnit: floorUnit,
        instructions: instructions,
      ),
      items: orderItems,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      paymentMethod: 'mpesa',
      paymentStatus: 'pending',
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }
}
