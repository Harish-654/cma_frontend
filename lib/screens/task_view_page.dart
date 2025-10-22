import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meeting.dart';

class TaskViewPage extends StatefulWidget {
  final DateTime selectedDate;
  final List<Meeting> allTasks;
  final Function(Meeting) onDeleteTask;

  TaskViewPage({
    required this.selectedDate,
    required this.allTasks,
    required this.onDeleteTask,
  });

  @override
  State<TaskViewPage> createState() => _TaskViewPageState();
}

class _TaskViewPageState extends State<TaskViewPage> {
  late List<Meeting> beforeTasks;
  late List<Meeting> onDateTasks;
  late List<Meeting> afterTasks;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _selectedDateKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _organizeTasks();

    // Scroll to selected date after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _organizeTasks() {
    final selectedDateOnly = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );

    beforeTasks = [];
    onDateTasks = [];
    afterTasks = [];

    for (var task in widget.allTasks) {
      final taskDate = DateTime(task.from.year, task.from.month, task.from.day);

      if (taskDate.isBefore(selectedDateOnly)) {
        beforeTasks.add(task);
      } else if (taskDate.isAtSameMomentAs(selectedDateOnly)) {
        onDateTasks.add(task);
      } else {
        afterTasks.add(task);
      }
    }

    beforeTasks.sort((a, b) => b.from.compareTo(a.from));
    onDateTasks.sort((a, b) => a.from.compareTo(b.from));
    afterTasks.sort((a, b) => a.from.compareTo(b.from));
  }

  void _scrollToSelectedDate() {
    try {
      final context = _selectedDateKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.1, // Position at 10% from top
        );
      }
    } catch (e) {
      print('Scroll error: $e');
    }
  }

  Map<DateTime, List<Meeting>> _groupTasksByDate(List<Meeting> tasks) {
    Map<DateTime, List<Meeting>> grouped = {};
    for (var task in tasks) {
      final dateOnly = DateTime(task.from.year, task.from.month, task.from.day);
      if (!grouped.containsKey(dateOnly)) {
        grouped[dateOnly] = [];
      }
      grouped[dateOnly]!.add(task);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(8),
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Task View',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Task list
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
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
                    child: ListView(
                      controller: _scrollController,
                      children: [
                        // Previous tasks
                        if (beforeTasks.isNotEmpty) ...[
                          _buildHeader(
                            'Previous Tasks',
                            Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          ..._buildGroupedTasks(beforeTasks),
                          SizedBox(height: 24),
                        ],

                        // Current day tasks - with scroll key
                        Container(
                          key: _selectedDateKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(
                                DateFormat(
                                  'EEEE, MMM dd, yyyy',
                                ).format(widget.selectedDate),
                                Theme.of(context).colorScheme.primary,
                              ),
                              if (onDateTasks.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'No tasks for this day',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...onDateTasks.map(
                                  (task) =>
                                      _buildTaskCard(task, showDate: false),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),

                        // Upcoming tasks
                        if (afterTasks.isNotEmpty) ...[
                          _buildHeader(
                            'Upcoming Tasks',
                            Theme.of(context).colorScheme.tertiary,
                          ),
                          ..._buildGroupedTasks(afterTasks),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Navigation Bar
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BottomNavigationBar(
                  backgroundColor: Colors.white,
                  currentIndex: 0,
                  elevation: 0,
                  onTap: (index) {
                    // Pass the selected index back to main screen
                    Navigator.pop(context, index);
                  },

                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Page 1',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.explore),
                      label: 'Page 2',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Page 3',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, Color color) {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  List<Widget> _buildGroupedTasks(List<Meeting> tasks) {
    final grouped = _groupTasksByDate(tasks);
    final sortedDates = grouped.keys.toList()..sort();

    List<Widget> widgets = [];
    for (var date in sortedDates) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(top: 12, bottom: 8, left: 4),
          child: Text(
            DateFormat('EEEE, MMM dd, yyyy').format(date),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );

      for (var task in grouped[date]!) {
        widgets.add(_buildTaskCard(task, showDate: false));
      }
    }

    return widgets;
  }

  Widget _buildTaskCard(Meeting task, {bool showDate = true}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: task.background.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: task.background, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetails(task),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: task.background,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title ?? 'Untitled',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: task.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          task.category ?? 'No Category',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: 4),
                          Text(
                            showDate
                                ? DateFormat(
                                    'MMM dd, hh:mm a',
                                  ).format(task.from)
                                : DateFormat('hh:mm a').format(task.from),
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteTask(task),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(Meeting task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title ?? 'Untitled'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, size: 18),
                SizedBox(width: 8),
                Text(task.category ?? 'No Category'),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(task.from),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text(task.description ?? 'No description')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteTask(Meeting task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Task'),
        content: Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onDeleteTask(task);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
