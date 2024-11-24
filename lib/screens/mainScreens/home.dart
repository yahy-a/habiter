import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habiter_/models/habit.dart';
import 'package:habiter_/providers/preferences_service.dart';
import 'package:intl/intl.dart';
import 'package:habiter_/providers/habit_provider.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

class HomeCont extends StatefulWidget {
  const HomeCont({super.key});

  @override
  State<HomeCont> createState() => _HomeContState();
}

class _HomeContState extends State<HomeCont> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        return SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildDatePicker(context)),
              SliverToBoxAdapter(child: _buildStreakInfo()),
              SliverToBoxAdapter(child: _buildProgressCircle()),
              SliverToBoxAdapter(child: _buildHabitList()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        String formattedDate = DateFormat('dd-MM-yyyy').format(habitProvider.selectedDate);
        final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode ? [
                Color(0xFF2A2A2A),
                Color(0xFF1F1F1F),
              ] : [
                Colors.white,
                Colors.grey[100]!,
              ],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0.0, 0.5),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      formattedDate,
                      key: ValueKey<String>(formattedDate),
                      style: GoogleFonts.poppins(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Provider.of<PreferencesProvider>(context,listen: true).notificationsEnabled ? Icons.notifications : Icons.notifications_outlined,
                  color: isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue,
                  size: 28,
                ),
                onPressed: () {
                  bool isEnabled = Provider.of<PreferencesProvider>(context).notificationsEnabled;
                  Provider.of<PreferencesProvider>(context).setNotificationsEnabled(!isEnabled);
                },
                style: IconButton.styleFrom(
                  padding: EdgeInsets.all(8),
                  backgroundColor: (isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue).withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
    return Container(
      height: 80,
      color: isDarkMode ? Colors.transparent : Colors.white,
      child: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              DateTime firstDate = DateTime.now().subtract(Duration(days: 4));
              DateTime date = firstDate.add(Duration(days: index));
              bool isSelected = date.day == habitProvider.selectedDate.day &&
                  date.month == habitProvider.selectedDate.month &&
                  date.year == habitProvider.selectedDate.year;
              bool isCurrentDay = date.day == DateTime.now().day &&
                  date.month == DateTime.now().month &&
                  date.year == DateTime.now().year;
              return GestureDetector(
                onTap: () {
                  habitProvider.setSelectedDate(date);
                },
                child: Container(
                  width: 65,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isSelected
                          ? [
                              (isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue).withOpacity(0.3),
                              (isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue).withOpacity(0.1),
                            ]
                          : isDarkMode ? [
                              Color(0xFF2A2A2A),
                              Color(0xFF2A2A2A),
                              Color(0xFF1F1F1F),
                            ] : [
                              Colors.white,
                              Colors.grey[200]!,
                              Colors.grey[200]!,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode ? const Color.fromARGB(60, 37, 36, 36) : Colors.white.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: isCurrentDay
                        ? Border.all(
                            color: (isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue)
                                .withOpacity(0.5),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        date.day.toString(),
                        style: GoogleFonts.poppins(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(date),
                        style: GoogleFonts.poppins(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStreakInfo() {
    return Container(
      margin: EdgeInsets.all(12),
      child: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
          return FutureBuilder<Map<String, int>>(
            future: Future.wait([
              habitProvider.getOverallStreak(),
              habitProvider.getOverallBestStreak()
            ]).then((values) => {'streak': values[0], 'bestStreak': values[1]}),
            builder: (context, snapshot) {
              final streakData = snapshot.data ?? {'streak': 0, 'bestStreak': 0};
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode ? [
                      Color(0xFF2A2A2A),
                      Color(0xFF1F1F1F),
                    ] : [
                      Colors.white,
                      Colors.grey[100]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: (isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current overall Streak',
                              style: GoogleFonts.poppins(
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${streakData['streak']} days',
                              style: GoogleFonts.poppins(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: (isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue).withOpacity(0.2),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Best Streak',
                              style: GoogleFonts.poppins(
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${streakData['bestStreak']} days',
                              style: GoogleFonts.poppins(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProgressCircle() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isDarkMode ? Colors.purple : Colors.blue).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDarkMode ? [
                              Color(0xFF2A2D3E),
                              Color(0xFF1F1F1F),
                            ] : [
                              Colors.white,
                              Colors.grey[100]!,
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 130,
                        width: 130,
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 2500),
                          curve: Curves.easeInOutCubic,
                          tween: Tween<double>(
                            begin: 0,
                            end: habitProvider.progressValue,
                          ),
                          builder: (context, value, _) =>
                              CircularProgressIndicator(
                            value: value,
                            strokeWidth: 12,
                            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 2500),
                            curve: Curves.easeInOutCubic,
                            tween: Tween<double>(
                              begin: 0,
                              end: habitProvider.progressValue,
                            ),
                            builder: (context, value, _) => Text(
                              '${(value * 100).toInt()}%',
                              style: GoogleFonts.rajdhani(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          Text(
                            'PROGRESS',
                            style: GoogleFonts.rajdhani(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode ? [
                        Color(0xFF2A2D3E),
                        Color(0xFF1F1F1F),
                      ] : [
                        Colors.white,
                        Colors.grey[100]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${habitProvider.progress}/${habitProvider.total}',
                        style: GoogleFonts.rajdhani(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'COMPLETED',
                        style: GoogleFonts.rajdhani(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
          ],
        );
      },
    );
  }

  Widget _buildHabitList() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
        bool isToday = habitProvider.selectedDate.day == DateTime.now().day &&
            habitProvider.selectedDate.month == DateTime.now().month &&
            habitProvider.selectedDate.year == DateTime.now().year;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    (isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue).withOpacity(0.3),
                    (isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "${isToday ? "Today's" : "Scheduled"} Habits",
                style: GoogleFonts.rajdhani(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            SizedBox(height: 16),
            StreamBuilder<List<Habit>>(
              stream: habitProvider.habitsStream,
              builder: (context, snapshot) {
                print('StreamBuilder state: ${snapshot.connectionState}');
                print('StreamBuilder data length: ${snapshot.data?.length}');
                if (snapshot.hasError) {
                  print('StreamBuilder error: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  habitProvider.setProgress(0, 0);
                  return Container(
                    margin: EdgeInsets.all(20),
                    padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode ? [
                          Color(0xFF2A2A2A),
                          Color(0xFF1F1F1F),
                        ] : [
                          Colors.white,
                          Colors.grey[100]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.add_task_rounded,
                          color: isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Habits Yet',
                          style: GoogleFonts.poppins(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start building better habits by adding your first habit',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                List<Habit> habits = snapshot.data!;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  int progress = habits
                      .where((habit) =>
                          habit.isCompletedForDate(habitProvider.selectedDate))
                      .length;
                  int total = habits.length;
                  habitProvider.setProgress(progress, total);
                });
                return ListView.builder(
                  key: ValueKey(habits.length),
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    return _buildHabitItem(habits[index]);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHabitItem(Habit habit) {
    return Consumer<HabitProvider>(builder: (context, habitProvider, child) {
      final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
      bool isToday = habitProvider.selectedDate.day == DateTime.now().day &&
          habitProvider.selectedDate.month == DateTime.now().month &&
          habitProvider.selectedDate.year == DateTime.now().year;
      bool isCompleted;
        isCompleted = habitProvider.getCompletionStatus(habit.id!);
      return Dismissible(
        key: Key(habit.id!),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.red.withOpacity(0.1),
                Colors.red.shade900,
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: 8),
              Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
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
                      'Delete Habit',
                      style: GoogleFonts.poppins(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Are you sure you want to delete this habit? This action cannot be undone.',
                  style: GoogleFonts.poppins(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) async {
          try {
            await habitProvider.deleteHabit(habit.id!);
            await Future.delayed(Duration(milliseconds: 300));
          } catch (e) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
                  title: Text(
                    'Error',
                    style: GoogleFonts.poppins(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    'Error deleting habit',
                    style: GoogleFonts.poppins(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        'OK',
                        style: GoogleFonts.poppins(
                          color: isDarkMode ? Colors.purple : Colors.blue,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          }
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCompleted
                  ? isDarkMode ? [
                      Color(0xFF9C27B0),
                      Color(0xFF7B1FA2),
                    ] : [
                      Colors.blue,
                      Colors.blue[700]!,
                    ]
                  : isDarkMode ? [
                      Color(0xFF2A2A2A),
                      Color(0xFF1F1F1F),
                    ] : [
                      Colors.white,
                      Colors.grey[100]!,
                    ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        habit.name,
                        style: GoogleFonts.poppins(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Row(
                        children: [
                          if (isToday)
                            GestureDetector(
                              onTap: () async {
                                try {
                                  await habitProvider.updateHabitCompletion(
                                      habit.id!, !isCompleted);
                                  isCompleted = !isCompleted;
                                } catch (e) {
                                  print('Error updating habit completion: $e');
                                }
                              },
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 0),
                                curve: Curves.easeInOut,
                                width: 32,
                                height: 32,
                                margin: EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isCompleted
                                        ? isDarkMode ? Color(0xFFCE93D8).withOpacity(0.6) : Colors.blue[200]!.withOpacity(0.6)
                                        : isDarkMode ? Colors.white30 : Colors.black26,
                                    width: 1.5,
                                  ),
                                  color: isCompleted
                                      ? isDarkMode ? Color(0xFF9C27B0) : Colors.blue
                                      : Colors.transparent,
                                  boxShadow: [
                                    if (isCompleted)
                                      BoxShadow(
                                        color: (isDarkMode ? Color(0xFF9C27B0) : Colors.blue).withOpacity(0.3),
                                        spreadRadius: 1,
                                      )
                                  ],
                                ),
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: Duration(milliseconds: 100),
                                    child: isCompleted
                                        ? Icon(Icons.check,
                                            key: ValueKey(true),
                                            size: 18,
                                            color: Colors.white)
                                        : SizedBox(key: ValueKey(false)),
                                  ),
                                ),
                              ),
                            ),
                          PopupMenuButton(
                            color: isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
                            icon: Icon(
                              Icons.more_horiz,
                              color: isDarkMode ? Colors.white : Colors.black,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide.none
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                height: 36,
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                onTap: () {
                                  final nameController = TextEditingController(text: habit.name);
                                  final detailController = TextEditingController(text: habit.detail);
                                  
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide.none,
                                      ),
                                      title: Text(
                                        'Edit Habit',
                                        style: GoogleFonts.poppins(
                                          color: isDarkMode ? Colors.white : Colors.black87,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: nameController,
                                            style: GoogleFonts.poppins(color: isDarkMode ? Colors.white : Colors.black87),
                                            decoration: InputDecoration(
                                              labelText: 'Habit Name',
                                              labelStyle: GoogleFonts.poppins(color: isDarkMode ? Colors.white70 : Colors.black54),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: isDarkMode ? Colors.white30 : Colors.black26),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: isDarkMode ? Color(0xFF9C27B0) : Colors.blue),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          TextField(
                                            controller: detailController,
                                            style: GoogleFonts.poppins(color: isDarkMode ? Colors.white : Colors.black87),
                                            maxLines: 3,
                                            decoration: InputDecoration(
                                              labelText: 'Habit Detail',
                                              labelStyle: GoogleFonts.poppins(color: isDarkMode ? Colors.white70 : Colors.black54),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: isDarkMode ? Colors.white30 : Colors.black26),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: isDarkMode ? Color(0xFF9C27B0) : Colors.blue),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text(
                                            'Cancel',
                                            style: GoogleFonts.poppins(
                                              color: isDarkMode ? Colors.white70 : Colors.black54,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async{
                                            await habitProvider.updateHabit(habit.id!, nameController.text, detailController.text);
                                            // ignore: use_build_context_synchronously
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isDarkMode ? Color(0xFF9C27B0) : Colors.blue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            'Save',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Edit',
                                      style: GoogleFonts.poppins(
                                        color: isDarkMode ? Colors.white : Colors.black,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                // Edit action is handled in onTap
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white24,
                        Colors.transparent
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          habit.detail,
                          style: GoogleFonts.poppins(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontSize: 14,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.orange.shade400,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              habit.currentStreak.toString(),
                              style: GoogleFonts.poppins(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
