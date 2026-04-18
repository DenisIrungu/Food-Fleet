import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    as places_sdk;
import 'package:foodfleet/screens/customers/screens/restaurants_near_me_screen.dart';
import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;

const _kGoogleApiKey = 'AIzaSyA7OCazA6ZKzBS-79Gnd6y2Mf7mpLHj9DA';

class CustomerLocationScreen extends StatefulWidget {
  const CustomerLocationScreen({super.key});

  @override
  State<CustomerLocationScreen> createState() => _CustomerLocationScreenState();
}

class _CustomerLocationScreenState extends State<CustomerLocationScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  bool _isLocating = false;
  String _detectedTown = '';
  double? _lat;
  double? _lng;

  late places_sdk.FlutterGooglePlacesSdk _places;
  List<places_sdk.AutocompletePrediction> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _places = places_sdk.FlutterGooglePlacesSdk(_kGoogleApiKey);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ── USE CURRENT LOCATION ──
  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled. Please enable GPS.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permanently denied. Enable in settings.');
        if (!kIsWeb) await Geolocator.openAppSettings();
        return;
      }

      // ── GET POSITION WITH TIMEOUT ──
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 15));
      } catch (e) {
        // Try last known position as fallback
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        _showError('Could not get location. Please search for your area.');
        return;
      }

      setState(() {
        _lat = position!.latitude;
        _lng = position.longitude;
      });

      print('🔥 Got position: ${position.latitude}, ${position.longitude}');

      // ── REVERSE GEOCODE ──
      try {
        if (kIsWeb) {
          await _reverseGeocodeWeb(position.latitude, position.longitude);
        } else {
          await _reverseGeocodeMobile(position.latitude, position.longitude);
        }
      } catch (e) {
        print('🔥 Geocoding failed: $e');
        // Geocoding failed but we still have coordinates — proceed anyway
      }

      if (!mounted) return;

      // ── NAVIGATE — even if town detection failed, pass coordinates ──
      final town = _detectedTown.isNotEmpty ? _detectedTown : 'Near You';
      _proceedWithTown(town);
    } catch (e) {
      print('🔥 Location error: $e');
      _showError('Could not get location. Please search for your area.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _reverseGeocodeMobile(double lat, double lng) async {
    // Use Nominatim on mobile too for better detailed results
    await _reverseGeocodeNominatim(lat, lng);
  }

  Future<void> _reverseGeocodeWeb(double lat, double lng) async {
    await _reverseGeocodeNominatim(lat, lng);
  }

  // ── SHARED NOMINATIM REVERSE GEOCODING ──
  Future<void> _reverseGeocodeNominatim(double lat, double lng) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=16&addressdetails=1');
    final response = await http.get(url, headers: {
      'Accept': 'application/json',
      'User-Agent': 'FoodFleet App',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final address = data['address'] as Map<String, dynamic>?;
      print('🔥 Nominatim address: $address');

      if (address != null) {
        // Build a detailed town string combining suburb + ward + city
        final suburb = address['suburb'] ??
            address['neighbourhood'] ??
            address['quarter'] ??
            '';
        final ward = address['city_district'] ?? address['ward'] ?? '';
        final city = address['city'] ??
            address['town'] ??
            address['municipality'] ??
            address['village'] ??
            address['county'] ??
            '';

        // Combine for a detailed label e.g. "Kilimani, Nairobi"
        // or "Bungoma Township Ward, Bungoma"
        final parts = <String>[];
        if (suburb.isNotEmpty) parts.add(suburb);
        if (ward.isNotEmpty && ward != suburb) parts.add(ward);
        if (city.isNotEmpty && city != suburb) parts.add(city);

        final town = parts.isNotEmpty ? parts.join(', ') : city;

        setState(() => _detectedTown = town);
        print('🔥 Detected town: $_detectedTown');
      }
    }
  }

  // ── SEARCH AUTOCOMPLETE ──
  Future<void> _onSearchChanged(String value) async {
    if (value.length < 2) {
      setState(() => _showSuggestions = false);
      return;
    }

    try {
      final result = await _places.findAutocompletePredictions(
        value,
        countries: ['KE'],
        placeTypesFilter: [places_sdk.PlaceTypeFilter.REGIONS],
      );

      if (mounted) {
        setState(() {
          _suggestions = result.predictions;
          _showSuggestions = result.predictions.isNotEmpty;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  void _proceedWithTown(String town) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantsNearYouScreen(
          selectedTown: town,
          customerLat: _lat,
          customerLng: _lng,
        ),
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double contentWidth = double.infinity;
    if (width > 1200)
      contentWidth = 650;
    else if (width > 800) contentWidth = 550;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP NAV ──
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: width > 600 ? 40 : 16,
                vertical: 18,
              ),
              color: const Color(0xFF0F2A12),
              child: Row(
                children: [
                  const Icon(Icons.local_dining, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'FoodFleet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
            ),

            // ── BODY ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: width > 600 ? 32 : 20,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── HEADER ──
                          const Text(
                            'Where should we deliver?',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2A12),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'We\'ll show you restaurants available in your area.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── USE CURRENT LOCATION BUTTON ──
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isLocating ? null : _useCurrentLocation,
                              icon: _isLocating
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.my_location),
                              label: Text(_isLocating
                                  ? 'Detecting your location...'
                                  : 'Use Current Location'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F2A12),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── DIVIDER ──
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(color: Colors.grey.shade300)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'or search your area',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: Divider(color: Colors.grey.shade300)),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── SEARCH FIELD ──
                          Column(
                            children: [
                              TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Kilimani, Westlands, Karen',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Color(0xFF0F2A12),
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(
                                                () => _showSuggestions = false);
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF0F2A12)),
                                  ),
                                ),
                              ),

                              // ── SUGGESTIONS ──
                              if (_showSuggestions)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _suggestions.length,
                                    itemBuilder: (context, index) {
                                      final prediction = _suggestions[index];
                                      return ListTile(
                                        dense: true,
                                        leading: const Icon(
                                          Icons.location_on_outlined,
                                          color: Color(0xFF0F2A12),
                                          size: 18,
                                        ),
                                        title: Text(
                                          prediction.primaryText ?? '',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        subtitle: Text(
                                          prediction.secondaryText ?? '',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500),
                                        ),
                                        onTap: () {
                                          final town =
                                              prediction.primaryText ?? '';
                                          _searchController.text = town;
                                          setState(
                                              () => _showSuggestions = false);
                                          _searchFocusNode.unfocus();
                                          _proceedWithTown(town);
                                        },
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ── QUICK SELECT AREAS ──
                          Text(
                            'Popular areas in Nairobi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'Kilimani',
                              'Westlands',
                              'Karen',
                              'Lavington',
                              'Parklands',
                              'Kileleshwa',
                              'Upperhill',
                              'CBD',
                              'Ngong Road',
                            ]
                                .map((area) => GestureDetector(
                                      onTap: () => _proceedWithTown(area),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F2A12)
                                              .withOpacity(0.06),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFF0F2A12)
                                                .withOpacity(0.2),
                                          ),
                                        ),
                                        child: Text(
                                          area,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF0F2A12),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
