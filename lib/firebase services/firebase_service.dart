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
        'completionRate': 0.0,
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

  /// Provides a stream of all habits for the current user
  /// @throws Exception if user is not authenticated
  /// @return Stream of habits without their entries
  Stream<List<Habit>> getHabitsStream() {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return _habits
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((habitSnapshot) async {
      try {
        final habits = habitSnapshot.docs.map((doc) {
          try {
            return Habit.fromDocument(doc);
          } catch (e) {
            print('Error parsing habit document ${doc.id}: $e');
            return null;
          }
        })
        .whereType<Habit>() // Filter out null values
        .toList();

        return habits;
      } catch (e) {
        print('Error processing habits snapshot: $e');
        return <Habit>[];
      }
    })
    .handleError((error) {
      print('Error in habits stream: $error');
      return <Habit>[];
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

      // Query all entries collections at once using a Collection Group Query
      final QuerySnapshot entriesSnapshot = await FirebaseFirestore.instance
          .collectionGroup('entries')
          .where('userId', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
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


  /// Updates the current streak count for all habits belonging to the current user
  /// 
  /// This function performs the following steps:
  /// 1. Verifies user authentication
  /// 2. Retrieves all habits for the current user
  /// 3. Gets all habit entries ordered by most recent
  /// 4. For each habit:
  ///    - Counts consecutive completed entries to calculate streak
  ///    - Stops counting at first incomplete entry
  /// 5. Uses batch update to efficiently update all habit streaks at once
  ///
  /// The streak calculation looks at entries in reverse chronological order,
  /// incrementing the streak counter for each completed entry until finding
  /// an incomplete one.
  ///
  /// @throws Exception if user is not authenticated or if batch update fails
  Future<void> updateAllHabitStreaks() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final habits = await _habits.where('userId', isEqualTo: currentUserId).get();
      if (habits.docs.isEmpty) {
        print('No habits found for user');
        return;
      }

      final entriesList = await _firestore
          .collectionGroup('entries')
          .where('userId', isEqualTo: currentUserId)
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .orderBy('date', descending: true)
          .get();

      final batch = _firestore.batch();
      for (var habit in habits.docs) {
        int streak = 0;
        for (var entry in entriesList.docs) {
          final entryData = entry.data();
          if (entryData['habitId'] == habit.id) {
            if (entryData['isCompleted'] == true) {
              streak++;
            } else {
              break;
            }
          }
        }
        batch.update(_habits.doc(habit.id), {'currentStreak': streak});
      }

      try {
        await batch.commit();
        print('Successfully updated all habit streaks');
      } catch (e) {
        print('Error committing batch update: $e');
        throw Exception('Failed to commit batch update: $e');
      }

    } catch (e) {
      print('Error updating all habit streaks: $e');
      throw Exception('Failed to update all habit streaks: $e');
    }
  }

  // SECTION: Overall Streak Management
  /// Gets the current overall streak across all habits
  Future<int> getOverAllStreak() async {
    final overallStreakDoc = await _overallStreaks.doc(currentUserId).get();
    final overallStreakData = overallStreakDoc.data() as Map<String, dynamic>;
    return overallStreakData['overallStreak'] ?? 0;
  }



  /// Updates the overall streak for the current user
  /// 
  /// This function calculates the current streak based on completed habits
  /// and updates it in the Firestore database. The streak is defined as the
  /// number of consecutive days where all habits were completed. It checks
  /// from the current day backwards, stopping at the first day where not all
  /// habits were completed or when there are no entries.
  /// 
  /// The function performs the following steps:
  /// 1. Checks if the user is authenticated
  /// 2. Retrieves entries for today
  /// 3. If today's entries are all completed, starts the streak count
  /// 4. Checks previous days, incrementing the streak for each day all habits were completed
  /// 5. Stops checking when it finds a day with incomplete habits or no entries
  /// 6. Updates the streak count in Firestore
  ///
  /// @throws Exception if the user is not authenticated or if there's an error updating the streak
  Future<void> updateOverAllStreak() async {
    try {
      print('FirebaseService: Starting overall streak update');
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      int streak = 0;
      bool foundIncompleteEntry = false;

      // Check entries for today
      final todayEntries = await getEntriesForDateRange(startDate: startOfDay, endDate: endOfDay);
      if (todayEntries.isEmpty) {
        print('FirebaseService: No entries found for overall streak update');
        await _overallStreaks.doc(currentUserId).set({'overallStreak': streak});
        return;
      }
      print('FirebaseService: Found entries of today for overall streak update');

      // Check if all habits are completed for today
      for (var entry in todayEntries) {
        if (entry.isCompleted == false) {
          foundIncompleteEntry = true;
          break;
        }
      }
      
      // If all habits are completed for today, start the streak
      if (!foundIncompleteEntry) {
        streak++;
      } else {
        // If not all habits are completed today, no need to check previous days
        await _overallStreaks.doc(currentUserId).set({'overallStreak': streak});
        return;
      }

      // Check previous days
      DateTime checkDay = startOfDay;
      while (true) {
        checkDay = checkDay.subtract(Duration(days: 1));
        final entries = await getEntriesForDateRange(startDate: checkDay, endDate: checkDay.add(Duration(days: 1)));
        
        // Break if no entries found for a day (end of habit history)
        if (entries.isEmpty) {
          break;
        }
        
        // Check if all habits were completed for the day
        foundIncompleteEntry = false;
        for (var entry in entries) {
          if (entry.isCompleted == false) {
            foundIncompleteEntry = true;
            break;
          }
        }
        
        // Break the streak if an incomplete entry is found
        if (foundIncompleteEntry) {
          break;
        } else {
          // Increment streak if all habits were completed
          streak++;
        }
      }

      // Update the overall streak in Firestore
      try {
        await _overallStreaks.doc(currentUserId).set({'overallStreak': streak});
        print('FirebaseService: Overall streak updated successfully to $streak days');
      } catch (e) {
        print('Error setting overall streak: $e');
        throw Exception('Failed to set overall streak: $e');
      }
    } catch (e) {
      print('Error updating overall streak: $e');
      throw Exception('Failed to update overall streak: $e');
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
      return habitData['bestStreak'] ?? 0;
    } catch (e) {
      print('Error getting habit best streak: $e');
      return 0;
    }
  }

  /// Updates the best streak for a specific habit
  Future<void> updateHabitBestStreak(String habitId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (habitId.isEmpty) {
        throw ArgumentError('Habit ID cannot be empty');
      }

      final currentStreak = await getHabitStreak(habitId);
      final currentBestStreak = await getHabitBestStreak(habitId);

      if (currentStreak > currentBestStreak) {
        await _habits.doc(habitId).update({'bestStreak': currentStreak});
      }
    } catch (e) {
      print('Error updating habit best streak: $e');
      throw Exception('Failed to update habit best streak: $e');
    }
  }

  // SECTION: Habit Management
  /// Updates a habit's basic information

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

  /// Updates the name and details of a specific habit
  /// @param habitId The unique identifier of the habit to update
  /// @param name The new name for the habit
  /// @param detail The new details/description for the habit
  /// @throws Exception if user is not authenticated or update fails
  Future<void> updateHabit(String habitId, String name, String detail) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      print('FirebaseService: Updating habit $habitId details');
      await _habits.doc(habitId).update({
        'name': name,
        'detail': detail,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('FirebaseService: Successfully updated habit details');
    } catch (e) {
      print('Error updating habit details: $e');
      throw Exception('Failed to update habit details: $e');
    }
  }


  // SECTION: Analytics Methods

  // sub-section: Completion Rate Retrieval

  /// Retrieves the completion rate for a specified timeframe
  /// @param timeframe The timeframe for which to get the completion rate ('Week', 'Month', or '6 Months')
  /// @return A List<double> containing the completion rates for each day/week/month in the specified timeframe
  /// @throws Exception if an invalid timeframe is provided
  Future<List<double>> getCompletionRate(String timeframe) async {
    switch (timeframe) {
      case 'Week':
        return await getWeeklyCompletionRate();
      case 'Month':
        return await getMonthlyCompletionRate();
      case '6 Months':
        return await getSixMonthCompletionRate();
      default:
        print('Invalid timeframe: $timeframe');
        return [];
    }
  }

  /// Retrieves the weekly completion rate for the current user
  /// @return A List<double> of 7 elements, each representing the completion rate for a day of the week
  /// @throws Exception if the user is not authenticated
  Future<List<double>> getWeeklyCompletionRate() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _firestore.collection('weeklyCompletionRates').doc(currentUserId).get();
    if (!doc.exists) {
      return List.filled(7, 0.0);  // Return a list of zeros if no data exists
    }
    
    return List<double>.from(doc.data()?['rates'] ?? List.filled(7, 0.0));
  }

  /// Retrieves the monthly completion rate for the current user
  /// @return A List<double> of 30 elements, each representing the completion rate for a day of the month
  /// @throws Exception if the user is not authenticated
  Future<List<double>> getMonthlyCompletionRate() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _firestore.collection('monthlyCompletionRates').doc(currentUserId).get();
    if (!doc.exists) {
      return List.filled(30, 0.0);  // Return a list of zeros if no data exists
    }

    return List<double>.from(doc.data()?['rates'] ?? List.filled(30, 0.0));
  }

  /// Retrieves the six-month completion rate for the current user
  /// @return A List<double> of 180 elements, each representing the completion rate for a day over six months
  /// @throws Exception if the user is not authenticated
  Future<List<double>> getSixMonthCompletionRate() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _firestore.collection('sixMonthCompletionRates').doc(currentUserId).get();
    if (!doc.exists) {
      return List.filled(180, 0.0);  // Return a list of zeros if no data exists
    }

    return List<double>.from(doc.data()?['rates'] ?? List.filled(180, 0.0));
  }

  /// Retrieves the overall completion rate for all habits over the past year
  /// 
  /// @return A double representing the completion rate as a percentage (0-100)
  /// @throws Exception if the user is not authenticated
  Future<double> getOverallCompletionRate() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final userStatsDoc = await _firestore
          .collection('userStats')
          .doc(currentUserId)
          .get();

      if (!userStatsDoc.exists) {
        return 0.0;
      }

      final userData = userStatsDoc.data() as Map<String, dynamic>;
      return userData['overallCompletionRate'] ?? 0.0;
    } catch (e) {
      print('Error getting overall completion rate: $e');
      throw Exception('Failed to get overall completion rate: $e');
    }
  }

  /// Retrieves the total number of habits for the current user
  /// 
  /// @return An integer representing the total number of habits
  /// @throws Exception if the user is not authenticated
  Future<int> getNumberOfTotalHabits() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final userStatsDoc = await _firestore
          .collection('userStats')
          .doc(currentUserId)
          .get();

      if (!userStatsDoc.exists) {
        return 0;
      }

      final userData = userStatsDoc.data() as Map<String, dynamic>;
      return userData['numberOfHabits'] ?? 0;
    } catch (e) {
      print('Error getting number of habits: $e');
      throw Exception('Failed to get number of habits: $e');
    }
  }

  Future<Map<String, double>> getCompletionRateForTopHabits() async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final topHabitsDoc = await _firestore.collection('topHabits').doc(currentUserId).get();
      if (!topHabitsDoc.exists) return {};

      if (topHabitsDoc.data() == null){
        print('FirebaseService: No top habits data found for user $currentUserId');
        return {};
      }

      return Map<String, double>.from(topHabitsDoc.data()!['topHabits'] ?? {});
    } catch (e) {
      print('Error getting completion rate for top habits: $e');
      throw Exception('Failed to get completion rate for top habits: $e');
    }
  }

  // sub-section: Completion Rate Updates

  /// Updates the completion rates for all timeframes (weekly, monthly, and six-month)
  /// This method should be called whenever habit data is updated to keep analytics current
  Future<void> updateAllCompletionRate() async {
    await updateWeeklyCompletionRate();
    await updateMonthlyCompletionRate();
    await updateSixMonthCompletionRate();
    await updateOverallCompletionRate();
    await updatePerformanceOfHabitsAndTopHabits();
  }

  /// Updates the weekly completion rate for the current user
  /// 
  /// This function calculates completion rates for the past 7 days and stores them in Firestore.
  /// The rates are stored as percentages (0-100) in an array where:
  /// - index 0 represents 6 days ago
  /// - index 6 represents today
  /// 
  /// The calculation process:
  /// 1. Verifies user authentication
  /// 2. Gets all habit entries for each day of the week
  /// 3. Calculates completion rate as: (completed entries / total entries) * 100
  /// 4. Stores results in Firestore under 'weeklyCompletionRates' collection
  Future<void> updateWeeklyCompletionRate() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      // Start from 6 days ago to include today (7 days total)
      final startOfWeek = now.subtract(Duration(days: 6));

      // Get all habits for validation
      final habitRefs = await _habits.where('userId', isEqualTo: currentUserId).get();

      // Array to store daily completion rates (7 days)
      List<double> completionRates = List.filled(7, 0.0);

      // Early return if user has no habits
      if (habitRefs.docs.isEmpty) {
        await _firestore.collection('weeklyCompletionRates').doc(currentUserId).set({
          'rates': completionRates,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      // Calculate completion rate for each day
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        // Get entries between start and end of the specific day
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(Duration(days: 1));

        int totalEntries = 0;
        int completedEntries = 0;

        // Get all entries for this day
        final listOfEntries = await getEntriesForDateRange(
          startDate: dayStart, 
          endDate: dayEnd
        );

        // Count completed vs total entries
        for (var entry in listOfEntries) {
          totalEntries++;
          if (entry.isCompleted) completedEntries++;
        }

        // Calculate completion rate as percentage
        completionRates[i] = totalEntries > 0 
          ? completedEntries / totalEntries * 100 
          : 0.0;
      }

      // Store results in Firestore
      await _firestore.collection('weeklyCompletionRates').doc(currentUserId).set({
        'rates': completionRates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating weekly completion rate: $e');
      throw Exception('Failed to update weekly completion rate: $e');
    }
  }

  /// Updates the monthly completion rate for the current user
  /// 
  /// This function calculates completion rates for the past 30 days, divided into 5 weeks.
  /// The rates are stored as percentages (0-100) in an array where:
  /// - index 0 represents the first week
  /// - index 4 represents the current week (might be partial)
  /// 
  /// The calculation process:
  /// 1. Verifies user authentication
  /// 2. Gets all habit entries for the 30-day period
  /// 3. Divides entries into 5 weekly chunks
  /// 4. Calculates completion rate for each week
  /// 5. Stores results in Firestore under 'monthlyCompletionRates' collection
  Future<void> updateMonthlyCompletionRate() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate the 30-day period
      final now = DateTime.now();
      final startOfMonth = now.subtract(Duration(days: 29));
      final exactStartOfMonth = DateTime(
        startOfMonth.year,
        startOfMonth.month,
        startOfMonth.day,
      );
      final endOfMonth = exactStartOfMonth.add(Duration(days: 30));

      // Initialize array for 5 weeks of data
      List<double> completionRate = List.filled(5, 0.0);

      // Validate user has habits
      final habitRefs = await _habits.where('userId', isEqualTo: currentUserId).get();
      if (habitRefs.docs.isEmpty) {
        await _firestore.collection('monthlyCompletionRates').doc(currentUserId).set({
          'rates': completionRate,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      // Get all entries for the entire period at once
      final listOfEntries = await getEntriesForDateRange(
        startDate: exactStartOfMonth, 
        endDate: endOfMonth
      );

      // Process each week
      for (int i = 0; i < 5; i++) {
        int totalEntries = 0;
        int completedEntries = 0;

        // Calculate week boundaries
        DateTime startOfWeek = exactStartOfMonth.add(Duration(days: i * 7));
        DateTime endOfWeek = startOfWeek.add(Duration(days: 7));
        // Adjust last week to end exactly at 30 days
        if(i == 4) endOfWeek = endOfMonth;

        // Filter entries for current week
        final entriesForWeek = listOfEntries.where(
          (entry) => entry.date.isAfter(startOfWeek) && entry.date.isBefore(endOfWeek)
        ).toList();

        // Count completed vs total entries
        for (var entry in entriesForWeek) {
          totalEntries++;
          if (entry.isCompleted) completedEntries++;
        }

        // Calculate completion rate as percentage
        completionRate[i] = totalEntries > 0 
          ? completedEntries / totalEntries * 100 
          : 0.0;
      }

      // Store results in Firestore
      await _firestore.collection('monthlyCompletionRates').doc(currentUserId).set({
        'rates': completionRate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating monthly completion rate: $e');
      throw Exception('Failed to update monthly completion rate: $e');
    }
  }

  /// Updates the six-month completion rate for the current user
  /// 
  /// This function calculates completion rates for the past 180 days, divided into 6 months.
  /// The rates are stored as percentages (0-100) in an array where:
  /// - index 0 represents the earliest month
  /// - index 5 represents the current month
  /// 
  /// The calculation process:
  /// 1. Verifies user authentication
  /// 2. Gets all habit entries for the 180-day period
  /// 3. Divides entries into 6 monthly chunks (30 days each)
  /// 4. Calculates completion rate for each month
  /// 5. Stores results in Firestore under 'sixMonthCompletionRates' collection
  Future<void> updateSixMonthCompletionRate() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate the 180-day period
      final now = DateTime.now();
      final startOfSixMonths = now.subtract(Duration(days: 179));
      final exactStartOfSixMonths = DateTime(
        startOfSixMonths.year, 
        startOfSixMonths.month, 
        startOfSixMonths.day
      );
      final endOfSixMonths = exactStartOfSixMonths.add(Duration(days: 180));

      // Initialize array for 6 months of data
      List<double> completionRate = List.filled(6, 0.0);

      // Validate user has habits
      final habitRefs = await _habits.where('userId', isEqualTo: currentUserId).get();
      if (habitRefs.docs.isEmpty) {
        await _firestore.collection('sixMonthCompletionRates').doc(currentUserId).set({
          'rates': completionRate,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      // Get all entries for the entire period at once
      final listOfEntries = await getEntriesForDateRange(
        startDate: exactStartOfSixMonths, 
        endDate: endOfSixMonths
      );

      // Process each month (30-day periods)
      for (int i = 0; i < 6; i++) {
        int totalEntries = 0;
        int completedEntries = 0;

        // Calculate month boundaries
        DateTime startOfMonth = exactStartOfSixMonths.add(Duration(days: i * 30));
        DateTime endOfMonth = startOfMonth.add(Duration(days: 30));

        // Filter entries for current month
        final entriesForMonth = listOfEntries.where(
          (entry) => entry.date.isAfter(startOfMonth) && entry.date.isBefore(endOfMonth)
        ).toList();

        // Count completed vs total entries
        for (var entry in entriesForMonth) {
          totalEntries++;
          if (entry.isCompleted) completedEntries++;
        }

        // Calculate completion rate as percentage
        completionRate[i] = totalEntries > 0 
          ? completedEntries / totalEntries * 100 
          : 0.0;
      }

      // Store results in Firestore
      await _firestore.collection('sixMonthCompletionRates').doc(currentUserId).set({
        'rates': completionRate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      print('Error updating six-month completion rate: $e');
      print('StackTrace: $stackTrace');
      throw Exception('Failed to update six-month completion rate: $e');
    }
  }

  /// This function calculates the overall completion rate for all habits over the past year (365 days).
  /// The rate is stored as a percentage (0-100) in Firestore.
  /// 
  /// The calculation process:
  /// 1. Verifies user authentication
  /// 2. Gets all habit entries for the past year
  /// 3. Calculates completion rate as: (completed entries / total entries) * 100
  /// 4. Stores result in Firestore under 'userStats' collection
  /// 
  /// Additionally, this function updates the number of habits for the user.
  /// 
  /// @throws Exception if the user is not authenticated or if the update fails
  Future<void> updateOverallCompletionRate() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      final firstDate = startOfDay.subtract(Duration(days: 365));

      final habits = await _habits.where('userId', isEqualTo: currentUserId).get();
      if (habits.docs.isEmpty) {
        await _firestore.collection('userStats').doc(currentUserId).set({
          'numberOfHabits': 0,
          'overallCompletionRate': 0.0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      } else {
        // Update number of habits in userStats
        await _firestore.collection('userStats').doc(currentUserId).set({
          'numberOfHabits': habits.docs.length,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
        final entriesList = await getEntriesForDateRange(
          startDate: firstDate, 
        endDate: endOfDay
      );
      int totalEntries = 0;
      int completedEntries = 0;
      for (var entry in entriesList) {
        totalEntries++;
        if (entry.isCompleted) completedEntries++;
      }
      final overallCompletionRate = totalEntries > 0 
        ? completedEntries / totalEntries * 100 
        : 0.0;
      await _firestore.collection('userStats').doc(currentUserId).set({
        'overallCompletionRate': overallCompletionRate,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating overall completion rate: $e');
      throw Exception('Failed to update overall completion rate: $e');
    }
  }

  /// This function performs the following tasks:
  /// 1. Verifies user authentication
  /// 2. Calculates completion rates for each habit over the past year
  /// 3. Updates the completion rate for each habit in Firestore
  /// 4. Maintains a list of top performing habits
  /// 5. Updates the 'topHabits' document in Firestore
  ///
  /// The function uses batch writes for efficient updates and handles potential errors.
  ///
  /// @throws Exception if the user is not authenticated or if any update operation fails.
  Future<void> updatePerformanceOfHabitsAndTopHabits() async {
    try {
      // Verify user authentication
      if (currentUserId == null) throw Exception('User not authenticated');

      // Set up date range for the past year
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      final firstDate = startOfDay.subtract(Duration(days: 365));

      // Fetch all habits for the current user
      final habits = await _habits.where('userId', isEqualTo: currentUserId).get();
      if (habits.docs.isEmpty) {
        print('User has no habits');
        await _firestore.collection('topHabits').doc(currentUserId).set({
          'topHabits': {},
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return; // Exit early if user has no habits
      }

      // Initialize a batch write for efficient updates
      final batch = _firestore.batch();

      // Fetch all entries for the past year
      final entries = await getEntriesForDateRange(startDate: firstDate, endDate: endOfDay);

      // Map to store top performing habits
      Map<String, double> topHabitsCompletionRates = {};

      // Calculate and update completion rate for each habit
      for (var habit in habits.docs) {
        int totalEntries = 0;
        int completedEntries = 0;
        final entriesForHabit = entries.where((entry) => entry.habitId == habit.id).toList();
        for (var entry in entriesForHabit) {
          totalEntries++;
          if (entry.isCompleted) completedEntries++;
        }
        final completionRate = totalEntries > 0 
          ? completedEntries / totalEntries * 100 
          : 0.0;
        final habitData = habit.data() as Map<String, dynamic>;
        final habitName = habitData['name'];
        updateTopHabitsMap(habitName, completionRate, topHabitsCompletionRates, 3);
        // Add update operation to batch
        batch.update(habit.reference, {
          'completionRate': completionRate,
        });
      }

      final topHabitsCompletionRatesList = topHabitsCompletionRates.entries.toList();
      topHabitsCompletionRatesList.sort((a, b) => a.value.compareTo(b.value));
      topHabitsCompletionRates.clear();
      topHabitsCompletionRates.addEntries(topHabitsCompletionRatesList);
      
      // Commit the batch update
      try {
        await batch.commit();
      } catch (e) {
        print('Error committing batch update for habit completion rates: $e');
        throw Exception('Failed to update habit completion rates: $e');
      }

      // Update top habits document
      try {
        await _firestore.collection('topHabits').doc(currentUserId).set({
          'topHabits': topHabitsCompletionRates,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating top habits document: $e');
        throw Exception('Failed to update top habits document: $e');
      }
    } catch (e) {
      print('Error updating habit performance: $e');
      throw Exception('Failed to update performance of habits: $e');
    }
  }

  /// Maintains a map of the top N performing habits
  /// @param maxTopHabits The maximum number of top habits to track (e.g., 5)
  void updateTopHabitsMap(String habitId, double completionRate, 
      Map<String, double> topHabitsCompletionRates, int maxTopHabits) {
    
    // If map has fewer entries than maxTopHabits, add directly
    if (topHabitsCompletionRates.length < maxTopHabits) {
      topHabitsCompletionRates[habitId] = completionRate;
      return;
    }

    // Find the lowest performing habit in the current top habits
    var lowestEntry = topHabitsCompletionRates.entries
        .reduce((a, b) => a.value < b.value ? a : b);

    // If new completion rate is higher than the lowest, replace it
    if (completionRate > lowestEntry.value) {
      topHabitsCompletionRates.remove(lowestEntry.key);
      topHabitsCompletionRates[habitId] = completionRate;
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
