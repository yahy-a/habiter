import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a habit in the application
class Habit {
  final String? id;  // Unique identifier for the habit
  final String userId;  // ID of the user who owns this habit
  final String name;  // Name of the habit
  final String detail;  // Detailed description of the habit
  final String frequency;  // How often the habit should be performed (e.g., daily, weekly)
  final int numberOfDays;  // Number of days for the habit (might be used for streak or duration)
  final int? bestStreak;  // Best streak for the habit
  final int? currentStreak;  // Current streak for the habit
  final DateTime createdAt;  // When the habit was created
  final Map<String, HabitEntry> entries;  // Map of habit entries, keyed by some identifier (possibly date)
  

  // Constructor for Habit
  Habit({
    this.id,
    required this.userId,
    required this.name,
    required this.detail,
    required this.frequency,
    required this.numberOfDays,
    this.bestStreak,
    this.currentStreak,
    DateTime? createdAt,
      Map<String, HabitEntry>? entries,
  })  : createdAt = createdAt ?? DateTime.now(),  // Use provided date or current date
        entries = entries ?? {};  // Initialize selectedWeekDay and selectedMonthDay to null
  
  // Converts Habit object to a map for Firestore
  Map<String,dynamic> toMap(){
    return {
      'userId': userId,
      'name': name,
      'detail': detail,
      'frequency': frequency,
      'numberOfDays': numberOfDays,
      'bestStreak': bestStreak,
      'currentStreak': currentStreak,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Creates a Habit object from a Firestore document
  factory Habit.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Habit(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      detail: data['detail'] ?? '',
      frequency: data['frequency'] ?? 'Daily',
      numberOfDays: data['numberOfDays'] ?? 0,
      bestStreak: data['bestStreak'],
      currentStreak: data['currentStreak'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      // Initialize with empty entries map - we'll populate it separately
      entries: {},
    );
  }

  // Add a method to create a copy of the habit with new entries
  Habit copyWithEntries(Map<String, HabitEntry> newEntries) {
    return Habit(
      id: id,
      userId: userId,
      name: name,
      detail: detail,
      frequency: frequency,
      numberOfDays: numberOfDays,
      bestStreak: bestStreak,
      currentStreak: currentStreak,
      createdAt: createdAt,
      entries: newEntries,
    );
  }

  bool isCompletedForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day).toString();
    print('Checking completion for date: $dateKey');
    print('Available entries: ${entries.length}');
    print('Entry keys: ${entries.keys.join(', ')}');
    
    for (var entry in entries.values) {
      final entryDate = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      ).toString();
      
      print('Comparing entry date: $entryDate with date: $dateKey');
      if (entryDate == dateKey) {
        print('Found matching entry, completed: ${entry.isCompleted}');
        return entry.isCompleted;
      }
    }
    print('No matching entry found');
    return false;
  }
}

// Represents an entry for a habit on a specific date
class HabitEntry{
  final String? id;  // Unique identifier for the entry
  final String habitId;  // ID of the habit this entry belongs to
  final DateTime date;  // Date of this entry
  final bool isCompleted;  // Whether the habit was completed on this date
  final int streak;  // Current streak for the habit

  // Constructor for HabitEntry
  HabitEntry({
    this.id,
    required this.habitId,
    required this.date,
    this.isCompleted = false,
    this.streak = 0,
  });

  // Converts HabitEntry object to a map for Firestore
  Map<String,dynamic> toMap(){
    return {
      "habitId" : habitId,
      "date" : Timestamp.fromDate(date),
      "isCompleted" : isCompleted,
      "streak" : streak
    };
  }

  // Creates a HabitEntry object from a Firestore document
  factory HabitEntry.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String,dynamic>;
    return HabitEntry(
      id: doc.id,
      habitId: data['habitId'],
      date: (data['date'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
      streak: data['streak'] ?? 0,
    );
  }
}