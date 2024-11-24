import 'dart:math';

import 'package:flutter_svg/svg.dart';
import 'package:habiter_/providers/preferences_service.dart';
import 'package:habiter_/screens/mainScreens/analytics.dart';
import 'package:habiter_/screens/additional/add.dart';
import 'package:habiter_/screens/mainScreens/home.dart';
import 'package:habiter_/screens/mainScreens/settings.dart';
import 'package:habiter_/screens/mainScreens/profile.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habiter_/providers/habit_provider.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
    final List<Widget> _pages = [
    const HomeCont(),        // Your current home page content
    const SettingsScreen(),       // Settings page        // Empty container for FAB
    const AnalyticsPage(),     // Statistics page
    const ProfilePage(),        // Profile page
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) => Scaffold(
        backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: _buildBottomNavBar(),
        floatingActionButton: _selectedIndex == 0 ? _buildFloatingActionButton() : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomAppBar(
          color: Colors.transparent,
          elevation: 0,
          height: 65,
          padding: EdgeInsets.zero,
          notchMargin: 8,
          shape: AutomaticNotchedShape(
            RoundedRectangleBorder(),
            CircleBorder(),
          ),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child: _buildNavBarItem(Icons.home_rounded, 0),
                      ),
                      SizedBox(width: 15),
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child: _buildNavBarItem(Icons.settings_rounded, 1),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: _selectedIndex == 0 ? 40 : 10,
                ), // Smooth FAB space transition
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child: _buildNavBarItem(Icons.bar_chart_rounded, 2),
                      ),
                      SizedBox(width: 15),
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child: _buildNavBarItem(Icons.person_rounded, 3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0, end: isSelected ? 1.0 : 0.0),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, sin(value * pi * 2) * 4),
          child: Container(
            margin: EdgeInsets.fromLTRB(4, 0, 4, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: isDarkMode ? [
                  isSelected 
                    ? Color(0xFF9C27B0).withOpacity(0.8 * value)
                    : Colors.transparent,
                  isSelected
                    ? Color(0xFF7B1FA2).withOpacity(0.9 * value) 
                    : Colors.transparent,
                ] : [
                  isSelected 
                    ? Color(0xFF2196F3).withOpacity(0.8 * value)
                    : Colors.transparent,
                  isSelected
                    ? Color(0xFF1976D2).withOpacity(0.9 * value) 
                    : Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: (isDarkMode ? Color(0xFF9C27B0) : Color(0xFF2196F3)).withOpacity(0.3 * value),
                    blurRadius: 8 * value,
                    offset: Offset(0, 2 * value),
                  )
              ],
            ),
            child: Transform.rotate(
              angle: isSelected ? sin(value * pi * 2) * 0.1 : 0,
              child: Transform.scale(
                scale: 1.0 + (isSelected ? sin(value * pi) * 0.2 : 0),
                child: IconButton(
                  icon: Icon(
                    icon,
                    size: 26,
                  ),
                  color: Color.lerp(
                    Colors.grey[400],
                    Colors.white,
                    isSelected ? value : 0
                  ),
                  onPressed: () => _onItemTapped(index),
                  splashColor: (isDarkMode ? Colors.purple : Colors.blue).withOpacity(0.3),
                  highlightColor: (isDarkMode ? Colors.purple : Colors.blue).withOpacity(0.2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
    return Stack(
      children: [
        // FAB Socket/Background
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.2),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        // FAB
        Positioned.fill(
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode ? [
                    Color(0xFF9C27B0),
                    Color(0xFF7B1FA2),
                  ] : [
                    Color(0xFF2196F3),
                    Color(0xFF1976D2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDarkMode ? Color(0xFF9C27B0) : Color(0xFF2196F3)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: CircleBorder(),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AddHabitPage()));
                  },
                  child: Icon(
                    Icons.add,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add navigation logic here
  }
}
