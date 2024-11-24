import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:habiter_/firebase%20services/firebase_service.dart';
import 'package:habiter_/models/habit.dart';

/// HabitProvider manages the state of habits and interacts with FirebaseService for CRUD operations
class HabitProvider with ChangeNotifier {

  // SECTION: Core Properties
  /// Service layer for Firebase interactions
  final FirebaseService _firebaseService = FirebaseService();

  /// In-memory list of current habits
  final List<Habit> _habits = [];

  /// Cache to store habit completion status (key: habitId_date, value: isCompleted)
  final Map<String, bool> _completionCache = {};

  
  
  /// Loading state for async operations
  bool _isLoading = false;
  /// Stores error messages from failed operations
  String? _error;
  /// Indicates if required form fields are filled
  bool _isFilled = false;



  // SECTION: Progress Tracking Properties
  /// Total number of habits for the current period
  int _total = 0;
  /// Number of completed habits for the current period
  int _progress = 0;
  /// Completion ratio (progress/total) as a decimal
  double _progressValue = 0;


  // SECTION: Habit Form Properties
  /// Currently selected date for habit viewing/editing
  DateTime _selectedDate = DateTime.now();
  /// Selected day of week for weekly habits (1-7)
  int _selectedWeekDay = DateTime.sunday;
  /// Selected day of month for monthly habits (1-31)
  int _selectedMonthDay = 1;
  /// Name of the habit being created/edited
  String _taskName = '';
  /// Additional details about the habit
  String _taskDetails = '';
  /// Frequency of the habit (Daily, Weekly, Monthly)
  String _frequency = 'Daily';
  /// Number of days for habit tracking
  int _numberOfDays = 1;


  // SECTION: Basic Getters
  /// Current loading state
  bool get isLoading => _isLoading;
  /// Current error message, if any
  String? get error => _error;
  /// Form validation state
  bool get isFilled => _isFilled;
  /// List of current habits
  List<Habit> get habits => _habits;
  /// Completion status cache
  Map<String, bool> get completionCache => _completionCache;
  /// Currently selected date
  DateTime get selectedDate => _selectedDate;


  // SECTION: Progress Getters
  /// Total number of habits
  int get total => _total;
  /// Number of completed habits
  int get progress => _progress;
  /// Progress ratio (0.0 to 1.0)
  double get progressValue => _progressValue;


  // SECTION: Form Data Getters
  /// Name of habit being created/edited
  String get taskName => _taskName;
  /// Details of habit being created/edited
  String get taskDetails => _taskDetails;
  /// Selected frequency (Daily/Weekly/Monthly)
  String get frequency => _frequency;
  /// Number of days for tracking
  int get numberOfDays => _numberOfDays;
  /// Selected day of week (1-7)
  int get selectedWeekDay => _selectedWeekDay;
  /// Selected day of month (1-31)
  int get selectedMonthDay => _selectedMonthDay;



  // SECTION: Basic Setters
  /// Updates form validation state
  void setIsFilled(bool value) {
    _isFilled = value;
    notifyListeners();
  }

  /// Updates the selected date and triggers UI refresh
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }



  // SECTION: Form Data Setters
  /// Updates selected weekday for weekly habits
  void setSelectedWeekDay(int weekDay) {
    _selectedWeekDay = weekDay;
    notifyListeners();
  }

  /// Updates selected month day for monthly habits
  void setSelectedMonthDay(int monthDay) {
    _selectedMonthDay = monthDay;
    notifyListeners();
  }

  /// Updates habit name
  void setTaskName(String name) {
    _taskName = name;
    notifyListeners();
  }

  /// Updates habit details
  void setTaskDetails(String details) {
    _taskDetails = details;
    notifyListeners();
  }

  /// Updates habit frequency
  void setFrequency(String freq) {
    _frequency = freq;
    notifyListeners();
  }

  /// Updates number of tracking days
  void setNumberOfDays(int days) {
    _numberOfDays = days;
    notifyListeners();
  }



  // SECTION: Progress Management
  /// Updates overall progress tracking
  /// @param progress Number of completed habits
  /// @param total Total number of habits
  void setProgress(int progress, int total) {
    if (_progress != progress || _total != total) {
      _progress = progress;
      _total = total;
      _progressValue =
          total > 0 ? double.parse((progress / total).toStringAsFixed(2)) : 0.0;
      notifyListeners();
    }
  }



  // SECTION: Cache Management
  /// Initializes the completion cache for the current date
  Future<void> initializeCache() async {
    List<Habit> habits =
        await _firebaseService.getHabitsForDate(selectedDate).first;
    _initializeCache(habits);
  }

  /// Internal method to populate the completion cache
  void _initializeCache(List<Habit> habits) {
    _completionCache.clear();
    for (var habit in habits) {
      final dateKey =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
              .toString();
      final cacheKey = '${habit.id}_$dateKey';
      _completionCache[cacheKey] = habit.isCompletedForDate(_selectedDate);
    }
  }

  /// Retrieves completion status for a specific habit
  bool getCompletionStatus(String habitId) {
    final dateKey = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).toString();
    final cacheKey = '${habitId}_$dateKey';
    return _completionCache[cacheKey] ?? false;
  }



  // SECTION: Habit CRUD Operations
  /// Provides a stream of habits for the selected date
  Stream<List<Habit>> get habitsStream {
    return _firebaseService.getHabitsForDate(_selectedDate).map((habits) {
      _habits.clear();
      _habits.addAll(habits);
      _initializeCache(habits);
      return habits;
    });
  }

  /// Creates a new habit with current form data
  Future<void> addHabit() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firebaseService.addHabit(_taskName, _taskDetails, _numberOfDays,
          _frequency, _selectedWeekDay, _selectedMonthDay);

      // Reset form
      _taskName = '';
      _taskDetails = '';
      _numberOfDays = 1;
      _frequency = 'Daily';
    } catch (e) {
      _error = 'Failed to add habit: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates an existing habit's details
  Future<void> updateHabit(String habitId, String name, String detail) async {
    await _firebaseService.updateHabit(habitId, name, detail);
    notifyListeners();
  }

  /// Removes a habit from the database
  Future<void> deleteHabit(String habitId) async {
    await _firebaseService.deleteHabit(habitId);
    notifyListeners();
  }



  // SECTION: Habit Completion Management
  /// Updates the completion status of a habit and manages related state
  Future<void> updateHabitCompletion(String habitId, bool isCompleted) async {
    try {
      final dateKey =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
              .toString();
      final cacheKey = '${habitId}_$dateKey';

      final wasCompleted = _completionCache[cacheKey] ?? false;

      if (wasCompleted != isCompleted) {
        _completionCache[cacheKey] = isCompleted;
        setProgress(_progress, _total);
        notifyListeners();

        await _firebaseService.updateHabitCompletion(
            habitId, _selectedDate, isCompleted);
        await _firebaseService.updateHabitStreak(habitId);
        notifyListeners();
        await _firebaseService.updateOverAllStreak();
        await _firebaseService.updateOverallBestStreak();
        notifyListeners();
      }
    } catch (e) {
      // Rollback on error
      final dateKey =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
              .toString();
      final cacheKey = '${habitId}_$dateKey';

      _completionCache[cacheKey] = !isCompleted;
      if (isCompleted) {
        _progress--;
      } else {
        _progress++;
      }
      _progressValue = _total > 0 ? _progress / _total : 0.0;
      notifyListeners();

      print('Error updating habit completion: $e');
      rethrow;
    }
  }

  bool isHabitCompleted(String habitId, DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day).toString();
    final cacheKey = '${habitId}_$dateKey';

    if (_completionCache.containsKey(cacheKey)) {
      return _completionCache[cacheKey]!;
    }

    final habit = _habits.firstWhere((h) => h.id == habitId);
    final isCompleted = habit.entries.values.any((entry) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day)
              .toString();
      return entryDate == dateKey && entry.isCompleted;
    });

    _completionCache[cacheKey] = isCompleted;
    return isCompleted;
  }



  // SECTION: Streak Management
  Future<int> getOverallBestStreak() async {
    return await _firebaseService.getOverallBestStreak();
  }

  Future<int> getOverallStreak() async {
    return await _firebaseService.getOverAllStreak();
  }

  Future<int> getHabitBestStreak(String habitId) async {
    return await _firebaseService.getHabitBestStreak(habitId);
  }

  Future<int> getHabitStreak(String habitId) async {
    return await _firebaseService.getHabitStreak(habitId);
  }

  Future<void> updateHabitStreak(String habitId) async {
    await _firebaseService.updateHabitStreak(habitId);
    notifyListeners();
  }

  Future<void> updateOverAllStreak() async {
    await _firebaseService.updateOverAllStreak();
    notifyListeners();
  }

  Future<void> updateOverallBestStreak() async {
    await _firebaseService.updateOverallBestStreak();
    notifyListeners();
  }


  // SECTION: Authentication & Utility Methods
  /// Clears all data from the database
  Future<void> clearAllData() async {
    await _firebaseService.clearAllData();
    notifyListeners();
  }

  Future<void> logOut(BuildContext context) async {
    await _firebaseService.logOut(context);
    notifyListeners();
  }

  /// Disposes of the provider and releases resources
  @override
  void dispose() {
    super.dispose();
  }
}
