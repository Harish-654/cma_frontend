import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/meeting.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import 'task_view_page.dart';

class PageOne extends StatefulWidget {
  final Function(int)? onNavigateToPage;

  PageOne({this.onNavigateToPage});

  @override
  State<PageOne> createState() => _PageOneState();
}

class _PageOneState extends State<PageOne> {
  late MeetingDataSource _dataSource;
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _dataSource = MeetingDataSource([]);
    _loadTasks();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // Load tasks from Supabase and Local Storage
  Future<void> _loadTasks() async {
    if (_isDisposed || !mounted) return;
    
    print('🔵 page_one: Loading tasks...');
    
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final tasks = await _taskService.getAllUserTasks();
      
      print('🔵 page_one: Tasks received: ${tasks.length}');
      for (var task in tasks) {
        print('  📋 ${task.title} - ${task.from}');
      }
      
      if (_isDisposed || !mounted) return;
      
      setState(() {
        _dataSource = MeetingDataSource(tasks);
        _isLoading = false;
      });
      
      print('✅ page_one: Calendar updated with tasks!');
    } catch (e) {
      print('❌ page_one: Error loading tasks: $e');
      if (_isDisposed || !mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Calendar Header
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Calendar',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SF Pro Display',
                            color: colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, color: colorScheme.primary),
                          onPressed: _loadTasks,
                        ),
                      ],
                    ),
                  ),
                  // Calendar
                  Expanded(
                    child: SfCalendar(
                      view: CalendarView.month,
                      dataSource: _dataSource,
                      monthViewSettings: MonthViewSettings(
                        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
                        appointmentDisplayCount: 3,
                        showAgenda: false,
                      ),
                      headerStyle: CalendarHeaderStyle(
                        textAlign: TextAlign.center,
                        textStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF Pro Display',
                          color: colorScheme.onSurface,
                        ),
                      ),
                      todayHighlightColor: colorScheme.primary,
                      selectionDecoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: colorScheme.primary, width: 2),
                        shape: BoxShape.circle,
                      ),
                      cellBorderColor: colorScheme.outline.withOpacity(0.2),
                      onTap: (CalendarTapDetails details) async {
                        if (details.date != null) {
                          final tasksList = <Meeting>[];
                          for (var appointment in _dataSource.appointments ?? []) {
                            if (appointment is Meeting) {
                              tasksList.add(appointment);
                            }
                          }

                          // Get current user role
                          final userProfile = await _authService.getCurrentUser();
                          final isRep = userProfile?.role == 'representative';

                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TaskViewPage(
                                selectedDate: details.date!,
                                allTasks: tasksList,
                                onDeleteTask: (task) async {
                                  try {
                                    await _taskService.deleteTaskAny(task);
                                    await _loadTasks();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Task deleted')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error deleting task')),
                                    );
                                  }
                                },
                                onNavigateToPage: widget.onNavigateToPage,
                                isRepresentative: isRep,
                              ),
                            ),
                          );
                          
                          // ⭐ KEY FIX - Reload tasks after returning
                          print('🔵 Returned from TaskViewPage, reloading...');
                          await _loadTasks();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Meeting> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].to;
  }

  @override
  String getSubject(int index) {
    return appointments![index].title ?? 'Untitled';
  }

  @override
  Color getColor(int index) {
    return appointments![index].background;
  }

  @override
  bool isAllDay(int index) {
    return false;
  }
}
