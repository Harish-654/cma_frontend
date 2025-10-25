import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meeting.dart';
import '../models/user_model.dart';

class AddClassTaskDialog extends StatefulWidget {
  final DateTime selectedDate;
  final List<UserModel> classStudents;
  final Function(Meeting task, List<String> studentIds) onTaskCreated;

  const AddClassTaskDialog({
    super.key,
    required this.selectedDate,
    required this.classStudents,
    required this.onTaskCreated,
  });

  @override
  State<AddClassTaskDialog> createState() => _AddClassTaskDialogState();
}

class _AddClassTaskDialogState extends State<AddClassTaskDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'Assignment';
  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<String> _categories = [
    'Assignment',
    'Project',
    'Exam',
    'Quiz',
    'Presentation',
    'Lab Work',
    'Reading',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _createTask() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final taskDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final task = Meeting(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      from: taskDateTime,
      to: taskDateTime.add(Duration(hours: 1)),
      background: Color(0xFF6750A4),
      isLocal: false,
    );

    // Empty list since we're not using studentIds anymore
    widget.onTaskCreated(task, []);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Class Task',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This task will be assigned to all students in your class',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'SF Pro Text',
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title *',
                labelStyle: TextStyle(
                  fontFamily: 'SF Pro Text',
                  color: colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16),

            // Category Dropdown (Subject)
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Subject',
                labelStyle: TextStyle(
                  fontFamily: 'SF Pro Text',
                  color: colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      color: colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
              dropdownColor: colorScheme.surface,
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16),

            // Time Picker
            InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          _selectedTime.format(context),
                          style: TextStyle(
                            fontFamily: 'SF Pro Text',
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Description Field
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: TextStyle(
                  fontFamily: 'SF Pro Text',
                  color: colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              color: colorScheme.onSurface,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _createTask,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Create Task',
            style: TextStyle(
              fontFamily: 'SF Pro Text',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
