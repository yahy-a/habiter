import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:habiter_/models/habit.dart';
import 'package:habiter_/screens/signIn/login.dart';

/// FirebaseService handles all Firebase interactions for the habit tracking application.
/// This service manages authentication, Firestore operations, and provides methods
/// for CRUD operations on habits, entries, and streak tracking.
class FirebaseService {
  // SECTION: Core Firebase Instances
  /// Main Firestore database instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Firebase Authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // SECTION: Collection References
  /// Reference to the habits collection in Firestore
  CollectionReference get _habits => _firestore.collection('habits');

  /// Reference to track overall streaks across all habits
  CollectionReference get _overallStreaks =>
      _firestore.collection('overallStreaks');

  /// Reference to track best overall streaks historically
  CollectionReference get _overallBestStreaks =>
      _firestore.collection('overallBestStreaks');

  /// Gets the entries collection for a specific habit
  /// @param habitId Unique identifier for the habit
  /// @return CollectionReference to the entries subcollection
  CollectionReference _entriesCollection(String habitId) =>
      _habits.doc(habitId).collection('entries');

  /// Current authenticated user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  // SECTION: Habit CRUD Operations
  /// Creates a new habit with associated entries based on frequency
  /// @param name Name of the habit
  /// @param detail Additional details about the habit
  /// @param numberOfDays Duration for tracking
  /// @param frequency How often the habit should be performed
  /// @param selectedWeekDay Day of week for weekly habits
  /// @param selectedMonthDay Day of month for monthly habits
  Future<void> addHabit(String name, String detail, int numberOfDays,
      String frequency, int? selectedWeekDay, int? selectedMonthDay) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Validate frequency-specific parameters
    if (frequency == 'Weekly' && selectedWeekDay == null) {
      throw ArgumentError('Weekly frequency requires a selected day');
    }
    if (frequency == 'Monthly' && selectedMonthDay == null) {
      throw ArgumentError('Monthly frequency requires a selected day');
    }

    DocumentReference habitDoc;
    try {
      // Create the main habit document
      habitDoc = await _habits.add({
        'userId': currentUserId,
        'name': name,
        'detail': detail,
        'frequency': frequency,
        'bestStreak': 0,
        'currentStreak': 0,
        'numberOfDays': numberOfDays,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create associated entries
      await addEntries(
          habitId: habitDoc.id,
          numberOfDays: numberOfDays,
          frequency: frequency,
          selectedWeekDay: selectedWeekDay,
          selectedMonthDay: selectedMonthDay);

      return;
    } catch (e) {
      throw Exception('Failed to add habit: $e');
    }
  }

  /// Creates entries for a habit based on its frequency
  /// @param habitId ID of the parent habit
  /// @param numberOfDays Number of days to create entries for
  /// @param frequency How often entries should be created
  /// @param selectedWeekDay Specific day for weekly habits
  /// @param selectedMonthDay Specific day for monthly habits
  Future<void> addEntries({
    required String habitId,
    required int numberOfDays,
    required String frequency,
    int? selectedWeekDay,
    int? selectedMonthDay,
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    try {
      switch (frequency.toLowerCase()) {
        case 'daily':
          // Create an entry for every day
          for (int i = 0; i < numberOfDays; i++) {
            final date = now.add(Duration(days: i));
            _addEntryToBatch(batch, habitId, date);
          }
          break;

        case 'weekly':
          if (selectedWeekDay == null) {
            throw ArgumentError('Weekly frequency requires a day selection');
          }
          // Calculate next occurrence of selected weekday
          final daysUntilWeekDay = (selectedWeekDay - now.weekday + 7) % 7;
          final nextWeekDay = now.add(Duration(days: daysUntilWeekDay));

          // Create entries for selected weekday
          for (int i = 0; i < numberOfDays; i++) {
            final date = nextWeekDay.add(Duration(days: 7 * i));
            _addEntryToBatch(batch, habitId, date);
          }
          break;

        case 'weekdays':
          // Create entries only for Monday through Friday
          for (int i = 0; i < numberOfDays; i++) {
            final date = now.add(Duration(days: i));
            if (date.weekday >= 1 && date.weekday <= 5) {
              _addEntryToBatch(batch, habitId, date);
            }
          }
          break;

        case 'monthly':
          if (selectedMonthDay == null) {
            throw ArgumentError('Monthly frequency requires a day selection');
          }
          // Create entries for selected day of each month
          for (int i = 0; i < numberOfDays; i++) {
            final date = DateTime(now.year, now.month + i, selectedMonthDay);
            _addEntryToBatch(batch, habitId, date);
          }
          break;

        default:
          throw ArgumentError('Invalid frequency: $frequency');
      }

      await batch.commit();
    } catch (e) {
      // Cleanup if entry creation fails
      await _habits.doc(habitId).delete();
      throw Exception('Failed to create habit entries: $e');
    }
  }

  /// Helper method to add a single entry to a batch operation
  /// @param batch Current write batch
  /// @param habitId ID of the parent habit
  /// @param date Date for the entry
  void _addEntryToBatch(WriteBatch batch, String habitId, DateTime date) {
    final entryRef = _entriesCollection(habitId).doc();
    batch.set(entryRef, {
      'userId': currentUserId,
      'habitId': habitId,
      'date': date,
      'isCompleted': false,
      'streak': 0,
    });
  }

  // SECTION: Habit Retrieval
  /// Provides a stream of habits for a specific date
  /// @param date Date to retrieve habits for
  /// @return Stream of habits with their entries
  Stream<List<Habit>> getHabitsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    return _habits
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((habitSnapshot) async {
      List<Habit> habits = [];

      for (var doc in habitSnapshot.docs) {
        try {
          final habit = Habit.fromDocument(doc);

          // Query entries for the specific date
          final entryRef = await _entriesCollection(habit.id!)
              .where('date',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
              .where('date', isLessThan: Timestamp.fromDate(endOfDay))
              .get();

          if (entryRef.docs.isNotEmpty) {
            // Create entries map for the habit
            Map<String, HabitEntry> entries = {};
            for (var entryDoc in entryRef.docs) {
              final entry = HabitEntry.fromDocument(entryDoc);
              final dateKey =
                  DateTime(entry.date.year, entry.date.month, entry.date.day)
                      .toString();
              entries[dateKey] = entry;
            }

            habits.add(habit.copyWithEntries(entries));
          }
        } catch (e) {
          print('Error processing habit: $e');
        }
      }

      return habits;
    });
  }

  // SECTION: Entry Retrieval
  /// Fetches all habit entries for a specific date range
  /// @param startDate The start date of the range (inclusive)
  /// @param endDate The end date of the range (inclusive)
  /// @return List of HabitEntry objects within the date range
  Future<List<HabitEntry>> getEntriesForDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Convert dates to UTC to ensure consistent querying
      final startUtc = DateTime.utc(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      final endUtc = DateTime.utc(
        endDate.year,
        endDate.month,
        endDate.day,
        23, 59, 59  // Include the entire end day
      );

      // Query all entries collections at once using a Collection Group Query
      final QuerySnapshot entriesSnapshot = await FirebaseFirestore.instance
          .collectionGroup('entries')
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startUtc))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endUtc))
          .orderBy('date', descending: true)  // Optional: sort by date
          .get();

      // Convert snapshots to HabitEntry objects
      return entriesSnapshot.docs
          .map((doc) => HabitEntry.fromDocument(doc))
          .toList();

    } catch (e, stackTrace) {
      print('Error fetching entries for date range: $e');
      print('StackTrace: $stackTrace');
      return [];
    }
  }

  // SECTION: Habit Completion Management
  /// Updates the completion status of a habit entry for a specific date
  /// @param habitId ID of the habit to update
  /// @param date Date of the entry to update
  /// @param isCompleted New completion status
  Future<void> updateHabitCompletion(
      String habitId, DateTime date, bool isCompleted) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      print(
          'FirebaseService: Updating habit $habitId for date $startOfDay to $isCompleted');

      // Find the entry for the specific date
      final entryQuery = await _entriesCollection(habitId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      if (entryQuery.docs.isEmpty) {
        print('FirebaseService: No entry found for date $startOfDay');
        return;
      }

      // Update the entry's completion status
      final entryDoc = entryQuery.docs.first;
      print('FirebaseService: Found entry ${entryDoc.id}');

      await entryDoc.reference.update({
        'isCompleted': isCompleted,
      });
      print('FirebaseService: Successfully updated entry');
    } catch (e) {
      print('FirebaseService: Error updating habit completion: $e');
      throw Exception('Failed to update habit completion: $e');
    }
  }

  // SECTION: Streak Management
  /// Retrieves the current streak for a specific habit
  /// @param habitId ID of the habit
  /// @return Current streak count
  Future<int> getHabitStreak(String habitId) async {
    final habitDoc = await _habits.doc(habitId).get();
    final habitData = habitDoc.data() as Map<String, dynamic>;
    return habitData['currentStreak'] ?? 0;
  }

  /// Updates the current streak for a habit based on completed entries
  /// @param habitId ID of the habit to update
  Future<void> updateHabitStreak(String habitId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      // Get all entries up to today, ordered by date
      final entries = await _entriesCollection(habitId)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .orderBy('date', descending: true)
          .get();

      int streak = 0;
      // Count consecutive completed entries
      for (var doc in entries.docs) {
        final entryData = doc.data() as Map<String, dynamic>;
        if (entryData['isCompleted'] == true) {
          streak++;
        } else {
          break; // Break on first incomplete entry
        }
      }

      await _habits.doc(habitId).update({'currentStreak': streak});
    } catch (e) {
      print('Error fetching habit streak: $e');
    }
  }

  // SECTION: Overall Streak Management
  /// Gets the current overall streak across all habits
  Future<int> getOverAllStreak() async {
    final overallStreakDoc = await _overallStreaks.doc(currentUserId).get();
    final overallStreakData = overallStreakDoc.data() as Map<String, dynamic>;
    return overallStreakData['overallStreak'] ?? 0;
  }

  /// Updates the overall streak based on all habits' completion
  /// Updates the overall streak across all habits for the current user.
  ///
  /// This function performs the following steps:
  /// 1. Checks if the user is authenticated.
  /// 2. Calculates the start and end of the current day.
  /// 3. Fetches all habit entries for the current user, ordered by date descending.
  /// 4. Determines the last day when a habit was not completed (break day).
  /// 5. Calculates the overall streak based on the days since the last break.
  /// 6. Updates the overall streak in Firestore.
  ///
  /// @throws Exception if the user is not authenticated or if there's an error fetching entries or updating the streak.
  Future<void> updateOverAllStreak() async {
    try {
      // Ensure user is authenticated
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate start and end of current day
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      // Fetch all entries for the current user
      final QuerySnapshot entriesSnapshot;
      try {
        entriesSnapshot = await FirebaseFirestore.instance
            .collectionGroup('entries')
            .where('userId', isEqualTo: currentUserId)
            .where('date', isLessThanOrEqualTo: endOfDay)
            .orderBy('date', descending: true)
            .get();
      } catch (e) {
        throw Exception('Failed to fetch entries: $e');
      }

      // If no entries found, exit early
      if (entriesSnapshot.docs.isEmpty) return;

      DateTime lastBreakDay = endOfDay;
      bool foundIncomplete = false;

      // Iterate through entries to find the last break day
      if (entriesSnapshot.docs.isNotEmpty) {
        for (var entry in entriesSnapshot.docs) {
          final entryData = entry.data() as Map<String, dynamic>;
          // Validate entry data
          if (!entryData.containsKey('date') || !entryData.containsKey('isCompleted')) {
            print('Warning: Entry ${entry.id} has invalid data');
            continue;
          }
          final entryDate = (entryData['date'] as Timestamp).toDate();

          // If an incomplete entry is found, update lastBreakDay
          if (entryData['isCompleted'] == false) {
            foundIncomplete = true;
            if (entryDate.isAfter(lastBreakDay)) {
              lastBreakDay =
                  DateTime(entryDate.year, entryDate.month, entryDate.day);
            }
            break;
          }
        }

        // Handle case where all entries are complete
        if (!foundIncomplete && entriesSnapshot.docs.isNotEmpty) {
          final oldestEntry = entriesSnapshot.docs.last;
          final oldestEntryData = oldestEntry.data() as Map<String, dynamic>;
          if (!oldestEntryData.containsKey('date')) {
            throw Exception('Oldest entry has invalid data');
          }
          final oldestDate = (oldestEntryData['date'] as Timestamp).toDate();

          // Update lastBreakDay to the oldest entry date if it's earlier
          if (oldestDate.isBefore(lastBreakDay)) {
            lastBreakDay =
                DateTime(oldestDate.year, oldestDate.month, oldestDate.day);
          }
        }
      }
      // Calculate the overall streak
      final daysSinceLastBreak = endOfDay.difference(lastBreakDay).inDays;
      try {
        // Update the overall streak in Firestore
        await _overallStreaks
            .doc(currentUserId)
            .set({'overallStreak': daysSinceLastBreak});
      } catch (e) {
        throw Exception('Failed to update overall streak: $e');
      }
    } catch (e) {
      // Log any errors that occur during the process
      print('Error calculating overall streak: $e');
      // Optionally, you can rethrow the exception here if you want it to propagate
      // throw e;
    }
  }

  // SECTION: Best Streak Management
  /// Gets the best overall streak achieved
  Future<int> getOverallBestStreak() async {
    final overallStreakDoc = await _overallBestStreaks.doc(currentUserId).get();
    final overallStreakData = overallStreakDoc.data() as Map<String, dynamic>;
    return overallStreakData['overallBestStreak'] ?? 0;
  }

  /// Updates the best overall streak if current streak is higher
  Future<void> updateOverallBestStreak() async {
    final currentOverallStreak = await getOverAllStreak();
    final overallStreakDoc = await _overallBestStreaks.doc(currentUserId).get();

    int bestStreak = currentOverallStreak;

    if (overallStreakDoc.exists) {
      final overallStreakData = overallStreakDoc.data() as Map<String, dynamic>;
      int previousBestStreak = overallStreakData['overallBestStreak'] ?? 0;

      if (currentOverallStreak > previousBestStreak) {
        bestStreak = currentOverallStreak;
        await _overallBestStreaks
            .doc(currentUserId)
            .set({'overallBestStreak': bestStreak});
      }
    } else {
      await _overallBestStreaks
          .doc(currentUserId)
          .set({'overallBestStreak': bestStreak});
    }
  }

  /// Gets the best streak for a specific habit
  Future<int> getHabitBestStreak(String habitId) async {
    try {
      final habitDoc = await _habits.doc(habitId).get();
      if (!habitDoc.exists) {
        throw Exception('Habit not found');
      }

      final habitData = habitDoc.data() as Map<String, dynamic>;
      final storedBestStreak = habitData['bestStreak'] ?? 0;
      final currentStreak = await getHabitStreak(habitId);

      if (currentStreak > storedBestStreak) {
        await updateHabitBestStreak(habitId, currentStreak);
        return currentStreak;
      }

      return storedBestStreak;
    } catch (e) {
      print('Error getting habit best streak: $e');
      return 0;
    }
  }

  /// Updates the best streak for a specific habit
  Future<void> updateHabitBestStreak(String habitId, int bestStreak) async {
    try {
      await _habits.doc(habitId).update({'bestStreak': bestStreak});
    } catch (e) {
      print('Error updating habit best streak: $e');
      rethrow;
    }
  }

  // SECTION: Habit Management
  /// Updates a habit's basic information
  Future<void> updateHabit(String habitId, String name, String detail) async {
    try {
      await _habits.doc(habitId).update({'name': name, 'detail': detail});
    } catch (e) {
      print('Error updating habit: $e');
      rethrow;
    }
  }

  /// Deletes a habit and all its associated entries
  Future<void> deleteHabit(String habitId) async {
    final batch = _firestore.batch();

    try {
      // Delete all entries
      final entries = await _entriesCollection(habitId).get();
      for (var doc in entries.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete the habit document
      await _habits.doc(habitId).delete();
    } catch (e) {
      print('Error deleting habit: $e');
      throw Exception("Error deleting habit: $e");
    }
  }

  // SECTION: Analytics Methods
  // completion rate for selected timeframe(Main method)
  Future<List<double>> getCompletionRate(String timeframe) async {
    List<double> completionRate = [];
    switch (timeframe) {
      case 'Week':
        completionRate = await getWeeklyCompletionRate();
        break;
      case 'Month':
        completionRate = await getMonthlyCompletionRate();
        break;
      case '6 Months':
        completionRate = await getSixMonthCompletionRate();
        break;
      case 'Year':
        completionRate = await getYearlyCompletionRate();
        break;
      default:
        print('Invalid timeframe: $timeframe');
        return [];
    }
    return completionRate;
  }

  // completion rate for selected timeframe(sub methods)

  /// Calculates the weekly completion rate for all habits of the current user.
  /// @return A list of 7 double values representing the completion rate for each day of the week.
  /// Each value is between 0.0 (no habits completed) and 1.0 (all habits completed).
  Future<List<double>> getWeeklyCompletionRate() async {
    try {
      // Ensure user is authenticated
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      // Calculate the start of the week (Sunday)
      final startOfWeek = now.subtract(Duration(days: now.weekday));

      // Fetch all habits for the current user
      final habitRefs =
          await _habits.where('userId', isEqualTo: currentUserId).get();

      // Initialize an array to store completion rates for each day of the week
      List<double> completionRates = List.filled(7, 0.0);

      // If no habits exist, return the empty completion rates list
      if (habitRefs.docs.isEmpty) {
        return completionRates;
      }

      // Iterate through each day of the week
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        // Define the start and end of the day
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(Duration(days: 1));

        int totalEntries = 0;
        int completedEntries = 0  ;

        final listOfEntries = await getEntriesForDateRange(
            startDate: dayStart, endDate: dayEnd);

        for (var entry in listOfEntries) {
          totalEntries++;
          if (entry.isCompleted) {
            completedEntries++;
          }
        }

        // Calculate and store the completion rate for the day
        // If there are no entries, the completion rate is 0
        completionRates[i] =
            totalEntries > 0 ? completedEntries / totalEntries * 100 : 100.0;
      }

      return completionRates;
    } catch (e) {
      // Log the error and rethrow with a more specific message
      print('Error getting weekly completion rate: $e');
      throw Exception('Failed to get weekly completion rate: $e');
    }
  }

  /// Calculates the monthly completion rate for all habits of the current user.
  ///
  /// This function divides the last 30 days into 5 weeks and calculates the
  /// completion rate for each week. The completion rate is the percentage of
  /// completed entries out of total entries for the user's habits.
  ///
  /// @return A list of 5 double values representing the completion rate for each week.
  /// Each value is between 0.0 (no habits completed) and 100.0 (all habits completed).
  Future<List<double>> getMonthlyCompletionRate() async {
    try {
      // Verify that the user is authenticated
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get the current date and calculate the start date of the 30-day period
      final now = DateTime.now();
      final startOfMonth = now.subtract(Duration(days: 29));
      final exactStartOfMonth = DateTime(
        startOfMonth.year,
        startOfMonth.month,
        startOfMonth.day,
      );

      final monthDays = 30;

      // Initialize a list to store completion rates for each week (5 weeks total)
      List<double> completionRate = List.filled(5, 0.0);

      // Fetch all habits associated with the current user from the Firestore collection
      final habitRefs =
          await _habits.where('userId', isEqualTo: currentUserId).get();

      // If the user has no habits, return the default completion rates
      if (habitRefs.docs.isEmpty) return completionRate;

      // Iterate through the 30-day period in increments of 7 days to represent each week
      for (int i = 0; i < monthDays; i += 7) {
        // Calculate the start date of the current week
        final startOfWeek = exactStartOfMonth.add(Duration(days: i));
        // Calculate the end date of the current week by adding 7 days
        DateTime endOfWeek = startOfWeek.add(Duration(days: 7));

        // For the last week, adjust the end date to include the remaining 2 days

        // Initialize counters for total and completed entries within the current week
        int totalEntries = 0;
        int completedEntries = 0;

        final listOfEntries = await getEntriesForDateRange(
            startDate: startOfWeek, endDate: endOfWeek);

        for (var entry in listOfEntries) {
          totalEntries++;
          if (entry.isCompleted) {
            completedEntries++;
          }
        }
        if (i == 28) {
          final startOfLastWeek = endOfWeek;
          final endOfLastWeek = startOfLastWeek.add(Duration(days: 2));
          final listOfEntries = await getEntriesForDateRange(
              startDate: startOfLastWeek, endDate: endOfLastWeek);
          for (var entry in listOfEntries) {
            totalEntries++;
            if (entry.isCompleted) {
              completedEntries++;
            }
          }
          completionRate[4] =
              totalEntries > 0 ? (completedEntries / totalEntries) * 100 : 100.0;
        }

        // Calculate the completion rate for the current week
        // If there are no entries, assume a completion rate of 100%
        completionRate[i ~/ 7] =
            totalEntries > 0 ? (completedEntries / totalEntries) * 100 : 100.0;
      }

      // Return the list of completion rates for each week
      return completionRate;
    } catch (e) {
      // Log the error message for debugging purposes
      print('Error getting monthly completion rate: $e');

      // Return a default list of completion rates in case of an error
      return List.filled(5, 0.0);
    }
  }

  /// Calculates the completion rate for habits over the past six months.
  ///
  /// This function performs the following steps:
  /// 1. Determines the start date for the six-month period.
  /// 2. Initializes an array to store completion rates for each month.
  /// 3. Fetches all habits for the current user.
  /// 4. For each month in the six-month period:
  ///    a. Calculates the start and end dates for the month.
  ///    b. Queries all habit entries within the month.
  ///    c. Counts total entries and completed entries.
  ///    d. Calculates the completion rate for the month.
  /// 5. Returns the array of monthly completion rates.
  ///
  /// If no habits exist, it returns an array of zeros.
  /// In case of an error, it logs the error and stack trace, and returns an array of zeros.
  ///
  /// @return A Future<List<double>> containing 6 completion rates, one for each month.
  Future<List<double>> getSixMonthCompletionRate() async {
    try {
      // Ensure user is authenticated
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get current date and calculate the start of the six-month period
      final now = DateTime.now();
      final startOfSixMonths = now.subtract(Duration(days: 179));
      final exactStartOfSixMonths = DateTime(
          startOfSixMonths.year, startOfSixMonths.month, startOfSixMonths.day);

      // Initialize array to store completion rates
      List<double> completionRate = List.filled(6, 0.0);

      // Fetch all habits for the current user
      final habitRefs =
          await _habits.where('userId', isEqualTo: currentUserId).get();

      // If no habits exist, return the array of zeros
      if (habitRefs.docs.isEmpty) return completionRate;

      // Iterate through each month in the six-month period
      for (int i = 0; i < 6; i++) {
        // Calculate start and end dates for the current month
        final startOfMonth = exactStartOfSixMonths.add(Duration(days: i * 30));
        final endOfMonth = startOfMonth.add(Duration(days: 30));
        int totalEntries = 0;
        int completedEntries = 0;

        // Create a list of queries to fetch entries for each habit within the month
        final listOfEntries = await getEntriesForDateRange(
            startDate: startOfMonth, endDate: endOfMonth);

        // Count total and completed entries
        for (var entry in listOfEntries) {
          totalEntries++;
          if (entry.isCompleted) {
            completedEntries++;
          }
        }

        // Calculate completion rate for the month
        completionRate[i] =
            totalEntries > 0 ? (completedEntries / totalEntries) * 100 : 100.0;
      }

      return completionRate;
    } catch (e, stackTrace) {
      // Log error and stack trace
      print('Error getting six-month completion rate: $e');
      print('StackTrace: $stackTrace');
      // Optionally, you can log the error to an external service here
      return List.filled(6, 0.0);
    }
  }

  /// Calculates the yearly completion rate for habits over the last 365 days
  /// Returns a list of 12 double values representing monthly completion rates
  Future<List<double>> getYearlyCompletionRate() async {
    try {
      // Ensure user is authenticated
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final startOfYear = now.subtract(Duration(days: 364));
      final exactStartOfYear = DateTime(
        startOfYear.year,
        startOfYear.month,
        startOfYear.day,
      );
      List<double> completionRate = List.filled(12, 0.0);

      // Fetch all habits for the current user
      final habitRefs =
          await _habits.where('userId', isEqualTo: currentUserId).get();
      
      // If no habits exist, return the array of zeros
      if (habitRefs.docs.isEmpty) return completionRate;

      // Iterate through each month in the year
      for (int i = 0; i < 12; i++) {
        // Calculate start and end dates for the current month (30-day period)
        final startOfMonth = exactStartOfYear.add(Duration(days: i * 30));
        final endOfMonth = startOfMonth.add(Duration(days: 30));
        int totalEntries = 0;
        int completedEntries = 0;

        // Fetch entries for the current month
        final listOfEntries = await getEntriesForDateRange(
            startDate: startOfMonth, endDate: endOfMonth);

        // Count total and completed entries
        for (var entry in listOfEntries) {
          totalEntries++;
          if (entry.isCompleted) {
            completedEntries++;
          }
        }
        
        // Calculate completion rate for the month
        completionRate[i] =
            totalEntries > 0 ? (completedEntries / totalEntries) * 100 : 100.0;
      }

      return completionRate;
    } catch (e, stackTrace) {
      // Log error and stack trace
      print('Error getting yearly completion rate: $e');
      print('StackTrace: $stackTrace');
      // Optionally, you can log the error to an external service here
      return List.filled(12, 0.0);
    }
  }

  // SECTION: User Data Management
  /// Clears all data for the current user
  Future<void> clearAllData() async {
    final habits =
        await _habits.where('userId', isEqualTo: currentUserId).get();
    final batch = _firestore.batch();

    // Delete all habits and their entries
    for (var habit in habits.docs) {
      final entries = await _entriesCollection(habit.id).get();
      for (var entry in entries.docs) {
        batch.delete(entry.reference);
      }
      batch.delete(habit.reference);
    }

    // Delete streak data
    final overallStreaks = await _overallStreaks.doc(currentUserId).get();
    batch.delete(overallStreaks.reference);
    final overallBestStreaks =
        await _overallBestStreaks.doc(currentUserId).get();
    batch.delete(overallBestStreaks.reference);

    try {
      await batch.commit();
    } catch (e) {
      print('Error clearing all data: $e');
      throw Exception('Error clearing all data: $e');
    }
  }

  /// Logs out the current user and navigates to login screen
  Future<void> logOut(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()));
    } catch (e) {
      print('Error logging out: $e');
      throw Exception('Error logging out: $e');
    }
  }
}
