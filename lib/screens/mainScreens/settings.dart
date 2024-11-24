import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habiter_/firebase%20services/firebase_auth.dart';
import 'package:habiter_/providers/habit_provider.dart';
import 'package:habiter_/providers/notification_service.dart';
import 'package:habiter_/providers/preferences_service.dart';
import 'package:habiter_/screens/signIn/change.dart';
import 'package:provider/provider.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final NotificationService _notificationService = NotificationService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
    final primaryColor = isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue;
    final backgroundColor = isDarkMode ? Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final gradientColors = isDarkMode 
      ? [Color(0xFF2A2A2A), Color(0xFF1F1F1F)]
      : [Colors.white, Colors.grey[100]!];

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(primaryColor, backgroundColor, textColor, gradientColors)),
          SliverToBoxAdapter(child: _buildSecuritySettings(primaryColor, backgroundColor, textColor, secondaryTextColor, gradientColors)),
          SliverToBoxAdapter(child: _buildGeneralSettings(primaryColor, backgroundColor, textColor, secondaryTextColor, gradientColors)),
          SliverToBoxAdapter(child: _buildNotificationSettings(primaryColor, backgroundColor, textColor, secondaryTextColor, gradientColors)),
          SliverToBoxAdapter(child: _buildDataSettings(primaryColor, backgroundColor, textColor, secondaryTextColor, gradientColors)),
        ],
      ),
    );
  }

  Widget _buildHeader(Color primaryColor, Color backgroundColor, Color textColor, List<Color> gradientColors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
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
      child: Row(
        children: [
          Icon(
            Icons.settings,
            color: primaryColor,
            size: 30,
          ),
          SizedBox(width: 16),
          Text(
            'Settings',
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings(Color primaryColor, Color backgroundColor, Color textColor, Color secondaryTextColor, List<Color> gradientColors) {
    return _buildSettingsSection(
      'Security',
      [
        _buildSettingsTile(
          icon: Icons.lock,
          title: 'Change Password',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChangePasswordScreen())),
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        _buildSettingsTile(
          icon: Icons.security,
          title: 'Two-Factor Authentication',
          trailing: Consumer<PreferencesProvider>(
            builder: (context, preferencesProvider, _) {
              return Switch(
                value: preferencesProvider.twoFactorAuthenticationEnabled,
                onChanged: (value) async {
                  await preferencesProvider.setTwoFactorAuthenticationEnabled(value);
                },
                activeColor: primaryColor,
              );
            }
          ),
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
      ],
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      gradientColors: gradientColors,
      textColor: textColor,
    );
  }

  Widget _buildGeneralSettings(Color primaryColor, Color backgroundColor, Color textColor, Color secondaryTextColor, List<Color> gradientColors) {
    return _buildSettingsSection(
      'General',
      [
        _buildSettingsTile(
          icon: Icons.dark_mode,
          title: 'Dark Mode',
          trailing: Consumer<PreferencesProvider>(
            builder: (context, preferencesProvider, _) {
              return Switch(
                value: preferencesProvider.isDarkMode,
                onChanged: (value) async {
                  await preferencesProvider.setThemeMode(value);
                },
                activeColor: primaryColor,
              );
            }
          ),
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        _buildSettingsTile(
          icon: Icons.language,
          title: 'Language',
          trailing: Text(
            'English',
            style: GoogleFonts.poppins(
              color: secondaryTextColor,
            ),
          ),
          onTap: () {
            // Implement language selection
          },
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
      ],
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      gradientColors: gradientColors,
      textColor: textColor,
    );
  }

  Widget _buildNotificationSettings(Color primaryColor, Color backgroundColor, Color textColor, Color secondaryTextColor, List<Color> gradientColors) {
    return _buildSettingsSection(
      'Notifications',
      [
        _buildSettingsTile(
          icon: Icons.notifications,
          title: 'Enable Notifications',
          trailing: Consumer<PreferencesProvider>(
            builder: (context, preferencesProvider, child) {
              return Switch(
                value: preferencesProvider.notificationsEnabled,
                onChanged: (value) async {
                  preferencesProvider.setNotificationsEnabled(value);
                  if(value){
                    bool isCompleted =  await preferencesProvider.setNotification( 1, "habit Reminder",'Don’t forget to check your habits!');
                    if(isCompleted){
                      print('succesfully created notification');
                    }else{
                      print("cant create a notification");
                    }
                  }
                  else {
                    bool isCOmpleted = await preferencesProvider.cancelNotification(1);
                    if(isCOmpleted){
                      print('succesfull cancelling');
                    }
                  }
                },
                activeColor: primaryColor,
              );
            }
          ),
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        _buildSettingsTile(
          icon: Icons.access_time,
          title: 'Reminder Time',
          trailing: Consumer<PreferencesProvider>(
            builder: (context, preferencesProvider, child) {
              return Text(
                preferencesProvider.notificationTime.format(context),
                style: GoogleFonts.poppins(
                  color: secondaryTextColor,
                ),
              );
            }
          ),
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: Provider.of<PreferencesProvider>(context, listen: false).notificationTime,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: primaryColor,
                      surface: backgroundColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              await Provider.of<PreferencesProvider>(context, listen: false).setNotificationTime(picked);
              bool isEnabled = Provider.of<PreferencesProvider>(context,listen: false).isDarkMode;
              if(isEnabled){
                bool isCompleted = await Provider.of<PreferencesProvider>(context,listen: false).setNotification(1, "habit Reminder", 'Don’t forget to check your habits!');
                if(isCompleted){
                  print('succesfully enabled notification');
                }else{
                      print("cant create a notification");
                    }
              }
            }
          },
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
      ],
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      gradientColors: gradientColors,
      textColor: textColor,
    );
  }

  Widget _buildDataSettings(Color primaryColor, Color backgroundColor, Color textColor, Color secondaryTextColor, List<Color> gradientColors) {
    return _buildSettingsSection(
      'Account Management',
      [
        _buildSettingsTile(
          icon: Icons.delete_forever,
          title: 'Clear All Data',
          titleColor: Colors.red,
          onTap: () {
            _showDeleteConfirmationDialog();
          },
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        _buildSettingsTile(
          icon: Icons.logout,
          title: 'Log Out',
          titleColor: Colors.red,
          onTap: () async {
            await Provider.of<HabitProvider>(context, listen: false).logOut(context);
          },
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
      ],
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      gradientColors: gradientColors,
      textColor: textColor,
    );
  }


  Widget _buildSettingsSection(String title, List<Widget> children, {
    required Color primaryColor,
    required Color backgroundColor,
    required List<Color> gradientColors,
    required Color textColor,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
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
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: titleColor ?? secondaryTextColor,
                size: 24,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: titleColor ?? textColor,
                    fontSize: 16,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final isDarkMode = Provider.of<PreferencesProvider>(context, listen: false).isDarkMode;
    final backgroundColor = isDarkMode ? Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.red.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Clear All Data',
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'This action will permanently delete all your habits and progress. This cannot be undone.',
            style: GoogleFonts.poppins(
              color: secondaryTextColor,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: secondaryTextColor,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Delete All',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                // Implement delete all functionality
                Provider.of<HabitProvider>(context, listen: false).clearAllData();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

}