import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodfleet/models/order_model.dart';
import 'package:foodfleet/screens/customers/screens/orders/customer_orders_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _green = Color(0xFF0F2A12);
  static const _supportNumber = '254781202091';

  bool _isDesktop(double width) => width >= 1100;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = _isDesktop(width) ? width * 0.18 : 20.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnap) {
            final userData =
                userSnap.data?.data() as Map<String, dynamic>? ?? {};
            final name = userData['displayName'] as String? ??
                user.displayName ??
                'Customer';
            final email = user.email ?? '';
            final photoUrl =
                userData['photoUrl'] as String? ?? user.photoURL;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('customerId', isEqualTo: user.uid)
                  .where('status', isEqualTo: 'delivered')
                  .snapshots(),
              builder: (context, ordersSnap) {
                final deliveredOrders = (ordersSnap.data?.docs ?? [])
                    .map((d) => OrderModel.fromFirestore(d))
                    .toList();

                final totalSpent = deliveredOrders.fold<double>(
                    0, (acc, o) => acc + o.total);
                final points = (totalSpent / 100).floor().toDouble();

                return SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _profileHeader(
                                context, name, email, photoUrl),
                            const SizedBox(height: 30),
                            _chatButton(context),
                            const SizedBox(height: 40),
                            _sectionTitle('My Account'),
                            _sectionDivider(),
                            const SizedBox(height: 14),
                            _accountCard(context),
                            const SizedBox(height: 40),
                            _sectionTitle('Loyalty Rewards'),
                            _sectionDivider(),
                            const SizedBox(height: 14),
                            _rewardsCard(context, points),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ── PROFILE HEADER ──

  Widget _profileHeader(BuildContext context, String name, String email,
      String? photoUrl) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _avatar(photoUrl, name),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome $name',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(email,
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String? photoUrl, String name) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 34,
        backgroundImage: NetworkImage(photoUrl),
        backgroundColor: _green,
      );
    }
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 34,
      backgroundColor: _green,
      child: Text(initial,
          style: const TextStyle(
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.bold)),
    );
  }

  // ── CHAT BUTTON ──

  Widget _chatButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _openSupportWhatsApp(),
        icon: const Icon(Icons.chat, color: Colors.white),
        label: const Text(
          'Chat with us',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Future<void> _openSupportWhatsApp() async {
    final message = Uri.encodeComponent(
      'Hi FoodFleet! 👋 I need help. Please reply with the number of your issue:\n\n'
      '1️⃣ Track my order\n'
      '2️⃣ Problem with my order\n'
      '3️⃣ Request a refund\n'
      '4️⃣ Payment issue\n'
      '5️⃣ Update my account details\n'
      '6️⃣ Other / General inquiry',
    );
    final uri = Uri.parse('https://wa.me/$_supportNumber?text=$message');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // ── ACCOUNT CARD ──

  Widget _accountCard(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _menuTile(
            icon: Icons.shopping_bag,
            title: 'Pending Orders',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const CustomerOrdersScreen(delivered: false),
              ),
            ),
          ),
          const Divider(height: 1),
          _menuTile(
            icon: Icons.check_circle_outline,
            title: 'Delivered Orders',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const CustomerOrdersScreen(delivered: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── REWARDS CARD ──

  Widget _rewardsCard(BuildContext context, double points) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Points: ${points.toStringAsFixed(0)} \u2B50',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Earn 1 point for every KES 100 spent.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: points < 500
                  ? null
                  : () => _showRedeemDialog(context, points),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                points < 500
                    ? 'Need ${500 - points.toInt()} more points to redeem'
                    : 'Redeem Points',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── REDEEM DIALOG ──

  void _showRedeemDialog(BuildContext context, double points) {
    const tiers = [
      {'points': 500, 'discount': 50},
      {'points': 1000, 'discount': 120},
      {'points': 2000, 'discount': 300},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Redeem Points',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your balance: ${points.toStringAsFixed(0)} points',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ...tiers
                .where((t) => points >= (t['points'] as int))
                .map((t) => _tierTile(ctx, t, points)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _tierTile(BuildContext context,
      Map<String, int> tier, double points) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _generateCode(context, tier['points']!, tier['discount']!);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: _green),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${tier['points']} points',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'KES ${tier['discount']} off',
              style: const TextStyle(
                  color: _green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateCode(
      BuildContext context, int pointsUsed, int discountAmount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final code =
        'FF-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final expiresAt =
        DateTime.now().add(const Duration(days: 30));

    try {
      await FirebaseFirestore.instance
          .collection('discounts')
          .doc(code)
          .set({
        'code': code,
        'uid': user.uid,
        'pointsUsed': pointsUsed,
        'discountAmount': discountAmount,
        'used': false,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });

      if (context.mounted) {
        _showCodeDialog(context, code, discountAmount,
            DateFormat('dd MMM yyyy').format(expiresAt));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to generate code: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showCodeDialog(BuildContext context, String code,
      int discountAmount, String expiresOn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Your Discount Code',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Apply this code at checkout:',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _green),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: _green),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: _green),
                    tooltip: 'Copy',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Code copied!'),
                            duration: Duration(seconds: 2)),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'KES $discountAmount discount · Expires $expiresOn',
              style:
                  const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: _green),
            child: const Text('Done',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── COMMON UI ──

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _green),
      ),
    );
  }

  Widget _sectionDivider() {
    return Divider(color: Colors.grey.shade300, thickness: 1);
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: _green),
      title:
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _green, width: 1),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 10),
      ],
    );
  }
}
