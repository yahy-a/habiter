import 'package:flutter/material.dart';
import 'package:habiter_/providers/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  static const String themeKey = 'theme_mode';
  static const String notificationsKey = 'notifications_enabled';
  static const String notificationHourKey = 'notification_hour';
  static const String notificationMinuteKey = 'notification_minute';
  static const String twoFactorAuthenticationKey =
      'two_factor_authentication_enabled';

  late SharedPreferences _prefs;
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  TimeOfDay _notificationTime = TimeOfDay(hour: 20, minute: 0);
  bool _twoFactorAuthenticationEnabled = false;

  // Initialize
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadPreferences();
  }

  // Load all preferences
  void _loadPreferences() {
    _isDarkMode = _prefs.getBool(themeKey) ?? false;
    _notificationsEnabled = _prefs.getBool(notificationsKey) ?? true;
    _notificationTime = TimeOfDay(
      hour: _prefs.getInt(notificationHourKey) ?? 20,
      minute: _prefs.getInt(notificationMinuteKey) ?? 0,
    );
    _twoFactorAuthenticationEnabled =
        _prefs.getBool(twoFactorAuthenticationKey) ?? false;
    notifyListeners();
  }

  // Theme
  bool get isDarkMode => _isDarkMode;
  bool get twoFactorAuthenticationEnabled => _twoFactorAuthenticationEnabled;
  Future<void> setThemeMode(bool isDark) async {
    _isDarkMode = isDark;
    await _prefs.setBool(themeKey, isDark);
    notifyListeners();
  }

  Future<void> setTwoFactorAuthenticationEnabled(bool enabled) async {
    _twoFactorAuthenticationEnabled = enabled;
    await _prefs.setBool(twoFactorAuthenticationKey, enabled);
    notifyListeners();
  }

  // Notifications
  bool get notificationsEnabled => _notificationsEnabled;
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _prefs.setBool(notificationsKey, enabled);
    notifyListeners();
  }

  // Notification Time
  TimeOfDay get notificationTime => _notificationTime;
  Future<void> setNotificationTime(TimeOfDay time) async {
    _notificationTime = time;
    await _prefs.setInt(notificationHourKey, time.hour);
    await _prefs.setInt(notificationMinuteKey, time.minute);
    notifyListeners();
  }

  Future<bool> setNotification(int id, String title, String body) async {
    try {
      await _notificationService.scheduleNotification(
          id: id, title: title, body: body, scheduledTime: _notificationTime);
      return true;
    } catch (e) {
      print('error setting notification:$e');
      return false;
    }
  }

  Future<bool> cancelNotification(int id) async {
    try {
      await _notificationService.cancelNotification(id);
      return true;
    } catch (e) {
      print('error in cancelling notification: $e');
      return false;
    }
  }
}
