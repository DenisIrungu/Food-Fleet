import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile.dart';
import 'change_password.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notifications = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _reloadUser() async {
    debugPrint('🔄 Reloading user data...');
    await FirebaseAuth.instance.currentUser?.reload();
    _currentUser = FirebaseAuth.instance.currentUser;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 700;
    final user = _currentUser ?? FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _reloadUser,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Settings",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 30),

                  // 🧩 Profile Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ProfileAvatar(
                          //   imageUrl: user?.photoURL,
                          //   radius: 40,
                          // ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.displayName ?? "User",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? "No email available",
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.secondary,
                              foregroundColor: colorScheme.onSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () async {
  debugPrint('🟢 Navigating to EditProfilePage...');
  final updated = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const EditProfilePage()),
  );

  // Only reload if profile was updated
  if (updated == true) {
    debugPrint('🔄 Profile updated — refreshing Settings...');
    await _reloadUser();

    // Force refresh UI and fetch updated photoURL
    final refreshedUser = FirebaseAuth.instance.currentUser;
    setState(() => _currentUser = refreshedUser);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profile updated successfully!'),
        ),
      );
    }
  } else {
    debugPrint('⚠️ EditProfilePage closed without changes.');
  }
},

                            icon: const Icon(Icons.edit),
                            label: const Text("Edit Profile"),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ⚙️ Settings Grid
                  GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: isWide ? 2 : 1,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 2.3,
                    children: [
                      _buildSettingCard(
                        icon: Icons.dark_mode,
                        title: "Dark Mode",
                        subtitle: "Switch between light and dark themes",
                        trailing: Switch(
                          value: _isDarkMode,
                          activeColor: colorScheme.secondary,
                          onChanged: (v) => setState(() => _isDarkMode = v),
                        ),
                        colorScheme: colorScheme,
                      ),
                      _buildSettingCard(
                        icon: Icons.notifications_active,
                        title: "Notifications",
                        subtitle: "Enable or disable app notifications",
                        trailing: Switch(
                          value: _notifications,
                          activeColor: colorScheme.secondary,
                          onChanged: (v) => setState(() => _notifications = v),
                        ),
                        colorScheme: colorScheme,
                      ),
                      _buildSettingCard(
                        icon: Icons.lock,
                        title: "Change Password",
                        subtitle: "Update your password regularly",
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          color: colorScheme.onSurface,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                        colorScheme: colorScheme,
                      ),
                      _buildSettingCard(
                        icon: Icons.security,
                        title: "Privacy & Security",
                        subtitle: "Manage app permissions and security options",
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          color: colorScheme.onSurface,
                          onPressed: () {},
                        ),
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // 🚪 Logout
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                      ),
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.secondary.withOpacity(0.15),
              child: Icon(icon, color: colorScheme.secondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out of your account?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}

// ✅ Profile Avatar Widget
// // class ProfileAvatar extends StatelessWidget {
// //   final String? imageUrl;
// //   final double radius;

// //   const ProfileAvatar({super.key, this.imageUrl, this.radius = 40});

// //   @override
// //   Widget build(BuildContext context) {
// //     debugPrint('🟣 Building ProfileAvatar — imageUrl: $imageUrl');

// //     if (imageUrl != null && imageUrl!.isNotEmpty) {
// //       try {
// //         return CircleAvatar(
// //           radius: radius,
// //           backgroundColor: Colors.grey[200],
// //           backgroundImage: NetworkImage(imageUrl!),
// //           onBackgroundImageError: (error, stackTrace) {
// //             debugPrint('❌ Failed to load network image: $error');
// //           },
// //         );
// //       } catch (e) {
// //         debugPrint('⚠️ Error creating NetworkImage: $e');
// //       }
// //     }

// //     debugPrint('⚪ No valid image URL — using default avatar');
// //     return CircleAvatar(
// //       radius: radius,
// //       backgroundColor: Colors.grey[300],
// //       child: const Icon(Icons.person, size: 40, color: Colors.white),
// //     );
//   }
// }
