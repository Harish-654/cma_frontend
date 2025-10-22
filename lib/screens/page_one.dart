import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'task_view_page.dart';
import '../models/meeting.dart'; // Add this line

class PageOne extends StatefulWidget {
  final Function(int)? onNavigateToPage; // ← Add this

  PageOne({this.onNavigateToPage}); // ← Add this

  @override
  State<PageOne> createState() => _PageOneState();
}

class _PageOneState extends State<PageOne> {
  late CalendarController _calendarController;
  late MeetingDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _dataSource = MeetingDataSource(_getDataSource());
  }

  List<Meeting> _getDataSource() {
    final List<Meeting> meetings = <Meeting>[];
    final DateTime today = DateTime.now();

    meetings.add(
      Meeting(
        id: '1',
        title: 'Discuss Q4 Goals',
        category: 'Meeting',
        description: 'Review team objectives and KPIs for Q4',
        from: DateTime(today.year, today.month, today.day, 10, 0),
        to: DateTime(today.year, today.month, today.day, 11, 0),
        background: Color(0xFF0F8644),
      ),
    );

    meetings.add(
      Meeting(
        id: '2',
        title: 'Sprint Planning',
        category: 'Work',
        description: 'Plan next sprint tasks and assignments',
        from: DateTime(today.year, today.month, today.day, 14, 0),
        to: DateTime(today.year, today.month, today.day, 15, 0),
        background: Color(0xFF3F51B5),
      ),
    );

    meetings.add(
      Meeting(
        id: '3',
        title: 'Pull Request Review',
        category: 'Development',
        description: 'Review team members code contributions',
        from: DateTime(today.year, today.month, today.day + 1, 11, 0),
        to: DateTime(today.year, today.month, today.day + 1, 12, 0),
        background: Color(0xFFFF6B6B),
      ),
    );

    meetings.add(
      Meeting(
        id: '4',
        title: 'Data Structures Study',
        category: 'Study',
        description: 'Review binary trees and graph algorithms',
        from: DateTime(today.year, today.month, today.day + 2, 16, 0),
        to: DateTime(today.year, today.month, today.day + 2, 18, 0),
        background: Color(0xFFE91E63),
      ),
    );

    meetings.add(
      Meeting(
        id: '5',
        title: 'AI Workshop',
        category: 'Workshop',
        description: 'Machine learning fundamentals workshop',
        from: DateTime(today.year, today.month, today.day - 2, 9, 0),
        to: DateTime(today.year, today.month, today.day - 2, 12, 0),
        background: Color(0xFF009688),
      ),
    );

    meetings.add(
      Meeting(
        id: '6',
        title: 'Database Assignment Deadline',
        category: 'Assignment',
        description: 'Submit ER diagram and normalization project',
        from: DateTime(today.year, today.month, today.day + 5, 23, 59),
        to: DateTime(today.year, today.month, today.day + 5, 23, 59),
        background: Color(0xFFD32F2F),
      ),
    );

    return meetings;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          children: [
            // Calendar Header
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Month View',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      _showAddTaskDialog();
                    },
                  ),
                ],
              ),
            ),

            // Google Calendar-style Month View
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  child: SfCalendar(
                    view: CalendarView.month,
                    controller: _calendarController,
                    dataSource: _dataSource,
                    monthViewSettings: MonthViewSettings(
                      appointmentDisplayMode:
                          MonthAppointmentDisplayMode.appointment,
                      appointmentDisplayCount: 4,
                      showAgenda: false,
                      monthCellStyle: MonthCellStyle(
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        trailingDatesTextStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                        leadingDatesTextStyle: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.38),
                        ),
                      ),
                    ),
                    headerStyle: CalendarHeaderStyle(
                      textAlign: TextAlign.center,
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    viewHeaderStyle: ViewHeaderStyle(
                      dayTextStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    todayHighlightColor: Theme.of(context).colorScheme.primary,
                    selectionDecoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    appointmentBuilder:
                        (
                          BuildContext context,
                          CalendarAppointmentDetails details,
                        ) {
                          final Meeting meeting = details.appointments.first;
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: meeting.background,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              meeting.category ?? 'Untitled',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                    onTap: (CalendarTapDetails details) async {
                      if (details.date != null) {
                        final tasksList = <Meeting>[];
                        for (var appointment
                            in _dataSource.appointments ?? []) {
                          if (appointment is Meeting) {
                            tasksList.add(appointment);
                          }
                        }

                        // Wait for the result from TaskViewPage
                        final selectedPageIndex = await Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => TaskViewPage(
                                  selectedDate: details.date!,
                                  allTasks: tasksList,
                                  onDeleteTask: (task) {
                                    setState(() {
                                      _dataSource.appointments?.remove(task);
                                      _dataSource.notifyListeners(
                                        CalendarDataSourceAction.remove,
                                        [task],
                                      );
                                    });
                                  },
                                ),
                              ),
                            );

                        // If a page was selected from task view, notify main screen
                        if (selectedPageIndex != null &&
                            selectedPageIndex != 0) {
                          // Pop this route and pass the index to main_screen
                          Navigator.pop(context, selectedPageIndex);
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    Color selectedColor = Color(0xFF3F51B5);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter task title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    hintText: 'e.g., Work, Personal, Study',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter task details',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text(selectedTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      [
                        Color(0xFF3F51B5),
                        Color(0xFF0F8644),
                        Color(0xFFE91E63),
                        Color(0xFFFF6B6B),
                        Color(0xFF009688),
                        Color(0xFF7B1FA2),
                      ].map((color) {
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedColor = color),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: selectedColor == color
                                  ? Border.all(color: Colors.black, width: 3)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    categoryController.text.isNotEmpty) {
                  final newMeeting = Meeting(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    category: categoryController.text,
                    description: descriptionController.text,
                    from: DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    ),
                    to: DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour + 1,
                      selectedTime.minute,
                    ),
                    background: selectedColor,
                  );
                  setState(() {
                    _dataSource.appointments!.add(newMeeting);
                    _dataSource.notifyListeners(CalendarDataSourceAction.add, [
                      newMeeting,
                    ]);
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> tasksToJson() {
    return _dataSource.appointments!
        .map((meeting) => (meeting as Meeting).toJson())
        .toList();
  }

  void loadTasksFromJson(List<dynamic> jsonList) {
    final meetings = jsonList.map((json) => Meeting.fromJson(json)).toList();
    setState(() {
      _dataSource = MeetingDataSource(meetings);
    });
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Meeting> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return _getMeetingData(index).from;
  }

  @override
  DateTime getEndTime(int index) {
    return _getMeetingData(index).to;
  }

  @override
  String getSubject(int index) {
    final category = _getMeetingData(index).category;
    return category != null && category.isNotEmpty ? category : 'Untitled';
  }

  @override
  Color getColor(int index) {
    return _getMeetingData(index).background;
  }

  @override
  bool isAllDay(int index) {
    return _getMeetingData(index).isAllDay;
  }

  Meeting _getMeetingData(int index) {
    final dynamic meeting = appointments![index];
    late final Meeting meetingData;
    if (meeting is Meeting) {
      meetingData = meeting;
    }
    return meetingData;
  }
}

// REMOVE the Meeting class from here - it's now in models/meeting.dart
