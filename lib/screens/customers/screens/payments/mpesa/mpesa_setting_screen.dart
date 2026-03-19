import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodfleet/models/restaurant_model.dart';

class MpesaSettingsScreen extends StatefulWidget {
  final RestaurantModel restaurant;

  const MpesaSettingsScreen({super.key, required this.restaurant});

  @override
  State<MpesaSettingsScreen> createState() => _MpesaSettingsScreenState();
}

class _MpesaSettingsScreenState extends State<MpesaSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _shortcodeController = TextEditingController();
  final _passkeyController = TextEditingController();
  final _consumerKeyController = TextEditingController();
  final _consumerSecretController = TextEditingController();

  String _shortcodeType = 'paybill';
  bool _isLoading = false;
  bool _isFetching = true;
  bool _obscurePasskey = true;
  bool _obscureConsumerSecret = true;

  @override
  void initState() {
    super.initState();
    _loadExistingSettings();
  }

  Future<void> _loadExistingSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurant.id)
          .collection('paymentSettings')
          .doc('mpesa')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _shortcodeController.text = data['shortcode'] ?? '';
        _passkeyController.text = data['passkey'] ?? '';
        _consumerKeyController.text = data['consumerKey'] ?? '';
        _consumerSecretController.text = data['consumerSecret'] ?? '';
        setState(() => _shortcodeType = data['type'] ?? 'paybill');
      }
    } catch (e) {
      // No existing settings — form starts empty
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurant.id)
          .collection('paymentSettings')
          .doc('mpesa')
          .set({
        'shortcode': _shortcodeController.text.trim(),
        'passkey': _passkeyController.text.trim(),
        'consumerKey': _consumerKeyController.text.trim(),
        'consumerSecret': _consumerSecretController.text.trim(),
        'type': _shortcodeType,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ M-Pesa settings saved successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to save settings: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _shortcodeController.dispose();
    _passkeyController.dispose();
    _consumerKeyController.dispose();
    _consumerSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2A12),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'M-Pesa Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              widget.restaurant.name,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── INFO BANNER ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2A12).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0F2A12).withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFF0F2A12), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'These credentials are stored securely and used to process M-Pesa payments for ${widget.restaurant.name}.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── SHORTCODE TYPE ──
                    const Text(
                      'Shortcode Type',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F2A12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeOption(
                            label: 'Paybill',
                            icon: Icons.business,
                            selected: _shortcodeType == 'paybill',
                            onTap: () =>
                                setState(() => _shortcodeType = 'paybill'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TypeOption(
                            label: 'Till Number',
                            icon: Icons.point_of_sale,
                            selected: _shortcodeType == 'till',
                            onTap: () =>
                                setState(() => _shortcodeType = 'till'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── SHORTCODE ──
                    _buildField(
                      controller: _shortcodeController,
                      label: _shortcodeType == 'paybill'
                          ? 'Paybill Number'
                          : 'Till Number',
                      hint: _shortcodeType == 'paybill'
                          ? 'e.g. 174379'
                          : 'e.g. 123456',
                      icon: Icons.tag,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Shortcode is required'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // ── PASSKEY ──
                    _buildField(
                      controller: _passkeyController,
                      label: 'Passkey',
                      hint: 'Lipa Na M-Pesa passkey',
                      icon: Icons.vpn_key_outlined,
                      obscureText: _obscurePasskey,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePasskey
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscurePasskey = !_obscurePasskey),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Passkey is required' : null,
                    ),

                    const SizedBox(height: 16),

                    // ── CONSUMER KEY ──
                    _buildField(
                      controller: _consumerKeyController,
                      label: 'Consumer Key',
                      hint: 'Daraja API consumer key',
                      icon: Icons.key,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Consumer Key is required'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // ── CONSUMER SECRET ──
                    _buildField(
                      controller: _consumerSecretController,
                      label: 'Consumer Secret',
                      hint: 'Daraja API consumer secret',
                      icon: Icons.lock_outline,
                      obscureText: _obscureConsumerSecret,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConsumerSecret
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(() =>
                            _obscureConsumerSecret = !_obscureConsumerSecret),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Consumer Secret is required'
                          : null,
                    ),

                    const SizedBox(height: 32),

                    // ── SAVE BUTTON ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2A12),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save M-Pesa Settings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF0F2A12)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F2A12)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TYPE OPTION WIDGET
// ─────────────────────────────────────────────

class _TypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F2A12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF0F2A12) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
