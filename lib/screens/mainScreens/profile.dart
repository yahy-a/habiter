import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:habiter_/providers/preferences_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PreferencesProvider>(
      builder: (context, preferencesProvider, child) {
        final isDarkMode = preferencesProvider.isDarkMode;
        return SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildProfileHeader(isDarkMode)),
              SliverToBoxAdapter(child: _buildStats(isDarkMode)),
              SliverToBoxAdapter(child: _buildPreferences(isDarkMode)),
              SliverToBoxAdapter(child: _buildAccountSettings(isDarkMode)),
              SliverToBoxAdapter(child: _buildAbout(isDarkMode)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Color(0xFF2A2A2A), Color(0xFF1F1F1F)]
              : [Colors.white, Colors.grey[100]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor:
                    (isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue)
                        .withOpacity(0.2),
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: isDarkMode
                      ? Color.fromARGB(255, 187, 134, 252)
                      : Colors.blue,
                ),
              ),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Color.fromARGB(255, 187, 134, 252)
                      : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'John Doe',
            style: GoogleFonts.poppins(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'john.doe@example.com',
            style: GoogleFonts.poppins(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard(
            'Streak',
            '15 days',
            Icons.local_fire_department_rounded,
            isDarkMode,
          ),
          SizedBox(width: 12),
          _buildStatCard(
            'Total Habits',
            '12',
            Icons.list_alt_rounded,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, bool isDarkMode) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Color(0xFF2A2A2A), Color(0xFF1F1F1F)]
                : [Colors.white, Colors.grey[100]!],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isDarkMode
                  ? Color.fromARGB(255, 187, 134, 252)
                  : Colors.blue,
              size: 24,
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferences(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Color(0xFF2A2A2A), Color(0xFF1F1F1F)]
              : [Colors.white, Colors.grey[100]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferences',
            style: GoogleFonts.poppins(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          _buildPreferenceItem(
            'Dark Mode',
            Icons.dark_mode_rounded,
            isDarkMode,
            Switch(
              value: isDarkMode,
              onChanged: (value) =>
                  Provider.of<PreferencesProvider>(context, listen: false)
                      .setThemeMode(value),
              activeColor: Color.fromARGB(255, 187, 134, 252),
            ),
          ),
          _buildPreferenceItem(
            'Notifications',
            Icons.notifications_rounded,
            isDarkMode,
            Switch(
              value: true,
              onChanged: (value) {},
              activeColor: Color.fromARGB(255, 187, 134, 252),
            ),
          ),
          _buildPreferenceItem(
            'Sound Effects',
            Icons.volume_up_rounded,
            isDarkMode,
            Switch(
              value: false,
              onChanged: (value) {},
              activeColor: Color.fromARGB(255, 187, 134, 252),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Color(0xFF2A2A2A), Color(0xFF1F1F1F)]
              : [Colors.white, Colors.grey[100]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Settings',
            style: GoogleFonts.poppins(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          _buildSettingsButton(
            'Edit Profile',
            Icons.edit_rounded,
            isDarkMode,
            () {},
          ),
          _buildSettingsButton(
            'Change Password',
            Icons.lock_rounded,
            isDarkMode,
            () {},
          ),
          _buildSettingsButton(
            'Privacy Settings',
            Icons.security_rounded,
            isDarkMode,
            () {},
          ),
          _buildSettingsButton(
            'Export Data',
            Icons.download_rounded,
            isDarkMode,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAbout(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Color(0xFF2A2A2A), Color(0xFF1F1F1F)]
              : [Colors.white, Colors.grey[100]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: GoogleFonts.poppins(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          _buildAboutItem('Version', '1.0.0', isDarkMode),
          _buildAboutItem('Terms of Service', 'View', isDarkMode),
          _buildAboutItem('Privacy Policy', 'View', isDarkMode),
          _buildAboutItem('Help & Support', 'Contact Us', isDarkMode),
          SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Sign Out',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(
      String title, IconData icon, bool isDarkMode, Widget trailing) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDarkMode
                      ? Color.fromARGB(255, 187, 134, 252)
                      : Colors.blue)
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color:
                  isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSettingsButton(
      String title, IconData icon, bool isDarkMode, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDarkMode
                        ? Color.fromARGB(255, 187, 134, 252)
                        : Colors.blue)
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDarkMode
                    ? Color.fromARGB(255, 187, 134, 252)
                    : Colors.blue,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutItem(String title, String value, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: isDarkMode ? Colors.white54 : Colors.black54,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}