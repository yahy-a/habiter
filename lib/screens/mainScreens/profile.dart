import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habiter_/models/habit.dart';
import 'package:habiter_/providers/habit_provider.dart';
import 'package:intl/intl.dart';
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
              SliverToBoxAdapter(child: _buildHabitsHeader()),
              SliverToBoxAdapter(child: _buildHabitsList()),
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

  Widget _buildHabitsHeader() {
    return Consumer<PreferencesProvider>(
      builder: (context, prefsProvider, child) {
        final isDarkMode = prefsProvider.isDarkMode;
        return Container(
          margin: EdgeInsets.all(16),
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
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.list_rounded,
                color: isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue,
                size: 30,
              ),
              SizedBox(width: 12),
              Text(
                'Your Habits',
                style: GoogleFonts.poppins(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildHabitsList() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        return StreamBuilder<List<Habit>>(
          stream: habitProvider.allHabitsStream,
          builder: (context, snapshot) {
            // if (snapshot.connectionState == ConnectionState.waiting) {
            //   return Center(
            //     child: CircularProgressIndicator(
            //       valueColor: AlwaysStoppedAnimation<Color>(
            //         Provider.of<PreferencesProvider>(context).isDarkMode 
            //           ? Color.fromARGB(255, 187, 134, 252)
            //           : Colors.blue
            //       ),
            //       backgroundColor: Provider.of<PreferencesProvider>(context).isDarkMode
            //           ? Colors.white24
            //           : Colors.grey[200],
            //     ),
            //   );
            // }
            
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading habits',
                  style: GoogleFonts.poppins(
                    color: Provider.of<PreferencesProvider>(context).isDarkMode 
                      ? Colors.white70 
                      : Colors.black54,
                    fontSize: 16,
                  ),
                ),
              );
            }

            final habits = snapshot.data ?? [];
            
            if (habits.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sentiment_dissatisfied_rounded,
                      size: 48,
                      color: Provider.of<PreferencesProvider>(context).isDarkMode 
                        ? Colors.white70 
                        : Colors.black54,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No habits yet',
                      style: GoogleFonts.poppins(
                        color: Provider.of<PreferencesProvider>(context).isDarkMode 
                          ? Colors.white70 
                          : Colors.black54,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a new habit to get started',
                      style: GoogleFonts.poppins(
                        color: Provider.of<PreferencesProvider>(context).isDarkMode 
                          ? Colors.white54 
                          : Colors.black38,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                return AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity: 1.0,
                  child: _buildHabitItem(habits[index]),
                );
              },
            );
          }
        );
      }
    );
  }

  Widget _buildHabitItem(Habit habit) {
    return Consumer<PreferencesProvider>(
      builder: (context, prefsProvider, child) {
        final isDarkMode = prefsProvider.isDarkMode;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [Color(0xFF1A1A1A), Color(0xFF2D2D2D)]
                  : [Colors.white, Color(0xFFF5F5F5)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? Colors.black38 : Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      habit.name,
                      style: GoogleFonts.poppins(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue)
                            .withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${habit.completionRate?.toStringAsFixed(1) ?? '0.0'}%',
                      style: GoogleFonts.poppins(
                        color: isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Created on ${DateFormat('MMM d, yyyy').format(habit.createdAt)}',
                style: GoogleFonts.poppins(
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black12 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  habit.detail,
                  style: GoogleFonts.poppins(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: isDarkMode ? Colors.white60 : Colors.black54,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            habit.frequency.toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                              fontSize: 13,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: Colors.orange.shade400,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Current: ${habit.currentStreak}',
                            style: GoogleFonts.poppins(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Best: ${habit.bestStreak}',
                            style: GoogleFonts.poppins(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }
}