import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_screen.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6342E8);
    const Color lightPurple = Color(0xFFF3F0FF);
    const Color bgColor = Color(0xFFF8F9FA);

    // Read live user data from Firebase Auth
    return StreamBuilder<User?>(
      stream: _authService.userStream,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final bool isLoggedIn = user != null;

        final String? userImageUrl = user?.photoURL;
        final String userName = user?.displayName?.isNotEmpty == true
            ? user!.displayName!
            : (user?.email?.split('@').first ?? 'Guest');
        final String userEmail = user?.email ?? '';

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Profile',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Profile Image
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                      image: userImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(userImageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: userImageUrl == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  isLoggedIn ? userName : 'Guest User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (isLoggedIn && userEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
                if (!isLoggedIn) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to access your profile',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 32),

                // Stats Row — only show for logged in users
                if (isLoggedIn) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                            'Events Attended', '0', primaryPurple),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                            'Active Tickets', '0', primaryPurple),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildActionItem(
                    title: 'My Tickets',
                    icon: Icons.confirmation_number_outlined,
                    lightPurple: lightPurple,
                    primaryPurple: primaryPurple,
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildActionItem(
                    title: 'Edit Profile',
                    icon: Icons.person_outline,
                    lightPurple: lightPurple,
                    primaryPurple: primaryPurple,
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildActionItem(
                    title: 'Create Event',
                    icon: Icons.add,
                    lightPurple: lightPurple,
                    primaryPurple: primaryPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  // Logout Button
                  _buildLogoutButton(),
                ] else ...[
                  // Guest: Sign In button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                        // Trigger rebuild after returning from login
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Sign In / Sign Up',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () async {
          await _authService.signOut();
          // StreamBuilder will auto-update the UI
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Logout',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 8),
            Icon(Icons.logout, color: Colors.red, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required String title,
    required IconData icon,
    required Color lightPurple,
    required Color primaryPurple,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: lightPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryPurple, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
