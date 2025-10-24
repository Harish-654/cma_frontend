import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'task_view_page.dart';
import '../models/meeting.dart';
import '../services/task_service.dart';
import '../main.dart'; // For supabase instance
// Add this line

class PageOne extends StatefulWidget {
  final Function(int)? onNavigateToPage; // ← Add this

  PageOne({this.onNavigateToPage}); // ← Add this

  @override
  State<PageOne> createState() => _PageOneState();
}

class _PageOneState extends State<PageOne> {
  late CalendarController _calendarController;
  late MeetingDataSource _dataSource;
  final TaskService _taskService = TaskService();
  bool _isLoading = true;
  bool _isDisposed = false;
  bool _hasLoadedData = false;

  @override
  bool get wantKeepAlive => true; // ← Add this flag

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _dataSource = MeetingDataSource([]);
    if (!_hasLoadedData) {
      // ← Only load once
      _loadTasks();
    }
  }

  // Load tasks from Supabase
  Future<void> _loadTasks() async {
    if (_isDisposed || _hasLoadedData) return; // ← Check if already loaded

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final tasks = await _taskService.getUserTasks();

      if (_isDisposed || !mounted) return;

      setState(() {
        _dataSource = MeetingDataSource(tasks);
        _isLoading = false;
        _hasLoadedData = true; // ← Mark as loaded
      });
    } catch (e) {
      print('Error loading tasks: $e');

      if (_isDisposed || !mounted) return;

      setState(() => _isLoading = false);
    }
  }

  // Add a method to refresh data manually
  Future<void> refreshTasks() async {
    _hasLoadedData = false;
    await _loadTasks();
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
                      color: Theme.of(context).colorScheme.onSurface,
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

                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TaskViewPage(
                              selectedDate: details.date!,
                              allTasks: tasksList,
                              onDeleteTask: (task) async {
                                // Delete from Supabase
                                try {
                                  await _taskService.deleteTask(task.id!);
                                  await _loadTasks(); // Reload tasks

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Task deleted')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error deleting task'),
                                    ),
                                  );
                                }
                              },
                              onNavigateToPage: widget.onNavigateToPage,
                            ),
                          ),
                        );
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
    Color selectedColor = Color(0xFF6750A4);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ... your existing form fields ...
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
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

                  Navigator.pop(context);

                  // Save to Supabase
                  try {
                    await _taskService.createPersonalTask(newMeeting);
                    await _loadTasks(); // Reload tasks

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Task created successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
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
