import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habiter_/providers/habit_provider.dart';
import 'package:habiter_/providers/preferences_service.dart';
import 'package:provider/provider.dart';

class AddHabitPage extends StatefulWidget {
  const AddHabitPage({super.key});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final _formKey = GlobalKey<FormState>();
  late final HabitProvider _habitProvider;

  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDetailsController = TextEditingController();
  final TextEditingController _numberOfDaysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _habitProvider = Provider.of<HabitProvider>(context, listen: false);
  }

  int _selectedWeekDay = DateTime.sunday;
  final Map<int, String> _weekDays = {
    DateTime.monday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday: 'Thursday',
    DateTime.friday: 'Friday',
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
  };

  final List<String> _frequencyOptions = [
    'Daily',
    'weekdays',
    'Weekly',
    'Monthly'
  ];

  int _selectedMonthDay = 1;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
        elevation: isDarkMode ? 0 : 1,
        title: Text(
          'Create New Habit',
          style: GoogleFonts.nunito(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, 
            color: isDarkMode ? Colors.white : Colors.black87
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Task Name'),
              _buildTextField(
                hint: 'Enter task name (e.g., "Morning Run")',
                controller: _taskNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a task name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              _buildSectionTitle('Task Details'),
              _buildTextField(
                hint: 'Enter task details (e.g., "Run for 30 minutes")',
                maxLines: 3,
                controller: _taskDetailsController,
              ),
              SizedBox(height: 24),
              _buildSectionTitle('Frequency'),
              Text(
                'How often would you like to perform this habit? ',
                style: GoogleFonts.nunito(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              _buildDropdown(),
              _buildWeekDaySelector(),
              _buildMonthDaySelector(),
              SizedBox(height: 24),
              _buildSectionTitle('Number of Days'),
              Text(
                'For how many days would you like to track this habit?',
                style: GoogleFonts.nunito(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              _buildTextField(
                hint: 'Enter number of days',
                controller: _numberOfDaysController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of days';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (int.parse(value) <= 0) {
                    return 'Number of days must be greater than 0';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SizedBox(height: 32),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.nunito(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    int maxLines = 1,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
    return TextFormField(
      style: GoogleFonts.nunito(
        color: isDarkMode ? Colors.white : Colors.black87
      ),
      maxLines: maxLines,
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(color: Colors.grey[400]),
        filled: true,
        fillColor: isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
    );
  }

  Widget _buildDropdown() {
    final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) => Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            borderRadius: BorderRadius.circular(8),
            value: habitProvider.frequency,
            isExpanded: true,
            dropdownColor: isDarkMode ? Color(0xFF2A2A2A) : Colors.grey[100],
            style: GoogleFonts.nunito(color: isDarkMode ? Colors.white : Colors.black87),
            items: _frequencyOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              habitProvider.setFrequency(newValue!);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWeekDaySelector() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        if (habitProvider.frequency != 'Weekly') return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Select day of the week',
              style: GoogleFonts.nunito(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: _weekDays.entries.map((entry) {
                  return RadioListTile<int>(
                    title: Text(
                      entry.value,
                      style: GoogleFonts.nunito(color: Colors.white),
                    ),
                    value: entry.key,
                    groupValue: _selectedWeekDay,
                    onChanged: (value) {
                      setState(() {
                        _selectedWeekDay = value!;
                      });
                      habitProvider.setSelectedWeekDay(value!);
                    },
                    activeColor: Colors.purple,
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthDaySelector() {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        if (habitProvider.frequency != 'Monthly') return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Select day of the month',
              style: GoogleFonts.nunito(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(
                  'Day ${habitProvider.selectedMonthDay}',
                  style: GoogleFonts.nunito(color: Colors.white),
                ),
                trailing: Icon(Icons.calendar_today, color: Colors.purple),
                onTap: () => _showDayPicker(context),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDayPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2A2A2A),
          title: Text(
            'Select Day of Month',
            style: GoogleFonts.nunito(color: Colors.white),
          ),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: 31,
              itemBuilder: (context, index) {
                final day = index + 1;
                return ListTile(
                  title: Text(
                    'Day $day',
                    style: GoogleFonts.nunito(color: Colors.white),
                  ),
                  onTap: () {
                    Provider.of<HabitProvider>(context, listen: false)
                        .setSelectedMonthDay(day);
                    Navigator.pop(context);
                  },
                  selected: _selectedMonthDay == day,
                  selectedTileColor: Colors.purple.withOpacity(0.2),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreateButton() {
    final isDarkMode = Provider.of<PreferencesProvider>(context).isDarkMode;
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        if (habitProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.purple : Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                habitProvider.setNumberOfDays(int.parse(_numberOfDaysController.text));
                habitProvider.setTaskName(_taskNameController.text);
                habitProvider.setTaskDetails(_taskDetailsController.text);
                try {
                  await habitProvider.addHabit();
                  if (!mounted) return;
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: Text(
              'Create Habit',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskDetailsController.dispose();
    _numberOfDaysController.dispose();
    super.dispose();
  }
}
