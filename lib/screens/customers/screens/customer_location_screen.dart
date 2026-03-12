import 'package:flutter/material.dart';
import 'package:foodfleet/screens/customers/screens/restaurants_near_me_screen.dart';

class CustomerLocationScreen extends StatelessWidget {
  const CustomerLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    /// ✅ RESPONSIVE CONTENT WIDTH
    double contentWidth = double.infinity;

    if (width > 1200) {
      contentWidth = 650;
    } else if (width > 800) {
      contentWidth = 550;
    }

    return Scaffold(
      backgroundColor: theme.surface,
      body: SafeArea(
        child: Column(
          children: [
            /// ================= TOP NAV =================
            _TopNav(),

            /// ================= BODY =================
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
                        color: theme.tertiary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const _LocationForm(),
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

//
// =====================================================
// ✅ TOP NAV (RESPONSIVE)
// =====================================================
//

class _TopNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width > 600 ? 40 : 16,
        vertical: 18,
      ),
      color: theme.secondary,
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "FoodFleet",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.person,
              color: theme.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

//
// =====================================================
// ✅ LOCATION FORM (SCROLL SAFE)
// =====================================================
//

class _LocationForm extends StatelessWidget {
  const _LocationForm();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Where should we deliver your food?",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.onSurface,
          ),
        ),

        const SizedBox(height: 28),

        /// CURRENT LOCATION
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.location_on),
            label: const Text("Use Current Location"),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: theme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        /// ADDRESS INPUT
        TextField(
          decoration: InputDecoration(
            hintText: "Enter address",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: theme.surface.withOpacity(0.4),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 28),

        Text(
          "Saved Addresses",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.onSurface,
          ),
        ),

        const SizedBox(height: 16),

        _SavedAddressCard(
          icon: Icons.home,
          title: "Home",
          subtitle: "123 Main Street, Apartment 4B",
        ),

        const SizedBox(height: 12),

        _SavedAddressCard(
          icon: Icons.work,
          title: "Work",
          subtitle: "456 Elm Street",
        ),

        const SizedBox(height: 30),

        /// CONFIRM BUTTON
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RestaurantsNearYouScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.secondary,
              foregroundColor: theme.tertiary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Confirm",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

//
// =====================================================
// ✅ SAVED ADDRESS CARD
// =====================================================
//

class _SavedAddressCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SavedAddressCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.secondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: theme.onSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
