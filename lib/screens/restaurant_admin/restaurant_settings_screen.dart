import 'package:flutter/material.dart';
import 'package:foodfleet/models/restaurant_model.dart';
import 'package:foodfleet/services/database_service.dart';

class RestaurantSettingsScreen extends StatefulWidget {
  final RestaurantModel restaurant;

  const RestaurantSettingsScreen({super.key, required this.restaurant});

  @override
  State<RestaurantSettingsScreen> createState() =>
      _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _whatsappController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _whatsappController =
        TextEditingController(text: widget.restaurant.whatsappNumber ?? '');
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await DatabaseService().updateRestaurantData(widget.restaurant.id, {
        'whatsappNumber': _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF0F2A12);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restaurant Settings',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: green),
            ),
            const SizedBox(height: 24),

            // ── CONTACT SECTION ──
            _sectionTitle('Contact & Support'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _whatsappController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'WhatsApp Number',
                hintText: 'e.g. 254712345678',
                helperText:
                    'Customers will use this to chat with your restaurant',
                prefixIcon: const Icon(Icons.chat, color: green),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: green),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final cleaned = v.trim().replaceAll(RegExp(r'\s+'), '');
                if (!RegExp(r'^\d{10,15}$').hasMatch(cleaned)) {
                  return 'Enter a valid number with country code (e.g. 254712345678)';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Save Settings',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey),
    );
  }
}
