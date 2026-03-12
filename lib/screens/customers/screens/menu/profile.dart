import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  /// ================= STATIC USER =================
  final String name = "Ann Mercy";
  final String email = "annirungu@email.com";
  final double rewardPoints = 245.50;

  /// ================= BREAKPOINTS =================
  bool _isDesktop(double width) => width >= 1100;
  bool _isTablet(double width) => width >= 700 && width < 1100;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = _isDesktop(width) ? width * 0.18 : 20.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                    /// PROFILE HEADER
                    _profileHeader(),

                    const SizedBox(height: 30),

                    /// CHAT BUTTON
                    _primaryButton("Chat with us"),

                    const SizedBox(height: 40),

                    /// ================= ACCOUNT =================
                    _sectionTitle("My Account"),
                    _sectionDivider(),
                    const SizedBox(height: 14),
                    _accountCard(context),

                    const SizedBox(height: 40),

                    /// ================= REWARDS =================
                    _sectionTitle("Loyalty Rewards"),
                    _sectionDivider(),
                    const SizedBox(height: 14),
                    _rewardsCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // PROFILE HEADER
  // =====================================================

  Widget _profileHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFF0F2A12),
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome $name",
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                email,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          )
        ],
      ),
    );
  }

  // =====================================================
  // ACCOUNT CARD
  // =====================================================

  Widget _accountCard(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _menuTile(
            icon: Icons.shopping_bag,
            title: "Pending Orders",
          ),
          const Divider(height: 1),
          _menuTile(
            icon: Icons.check_circle_outline,
            title: "Delivered Orders",
          ),
        ],
      ),
    );
  }

  // =====================================================
  // REWARDS CARD
  // =====================================================

  Widget _rewardsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Points: ${rewardPoints.toStringAsFixed(2)} 🌟",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Earn 1 point for every KES 100 spent.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 18),
          _primaryButton("Redeem Points"),
        ],
      ),
    );
  }

  // =====================================================
  // COMMON UI
  // =====================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F2A12),
        ),
      ),
    );
  }

  /// Divider between section title & cards
  Widget _sectionDivider() {
    return Divider(
      color: Colors.grey.shade300,
      thickness: 1,
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0F2A12)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  Widget _primaryButton(String text) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F2A12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// CARD STYLE WITH BORDER ✅
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: const Color(0xFF0F2A12),
        width: 1,
      ),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
        )
      ],
    );
  }
}
