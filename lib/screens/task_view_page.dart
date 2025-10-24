import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meeting.dart';

class TaskViewPage extends StatefulWidget {
  final DateTime selectedDate;
  final List<Meeting> allTasks;
  final Function(Meeting) onDeleteTask;
  final Function(int)? onNavigateToPage;

  TaskViewPage({
    required this.selectedDate,
    required this.allTasks,
    required this.onDeleteTask,
    this.onNavigateToPage,
  });

  @override
  State<TaskViewPage> createState() => _TaskViewPageState();
}

class _TaskViewPageState extends State<TaskViewPage> {
  late List<Meeting> todayTasks;

  @override
  void initState() {
    super.initState();
    _loadTodayTasks();
  }

  void _loadTodayTasks() {
    final selectedDateOnly = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );

    todayTasks = widget.allTasks.where((task) {
      final taskDate = DateTime(task.from.year, task.from.month, task.from.day);
      return taskDate.isAtSameMomentAs(selectedDateOnly);
    }).toList();

    todayTasks.sort((a, b) => a.from.compareTo(b.from));
  }

  void _toggleTaskCompletion(Meeting task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLow,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE').format(widget.selectedDate),
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              DateFormat('MMMM dd, yyyy').format(widget.selectedDate),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${todayTasks.where((t) => t.isCompleted).length}/${todayTasks.length}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          todayTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 80,
                        color: colorScheme.outlineVariant,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No tasks for this day',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 120),
                  itemCount: todayTasks.length,
                  itemBuilder: (context, index) {
                    return _buildTaskItem(todayTasks[index], colorScheme);
                  },
                ),

          // Floating Navigation Bar
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.2),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BottomNavigationBar(
                  backgroundColor: colorScheme.surface,
                  currentIndex: 0,
                  elevation: 0,
                  selectedItemColor: colorScheme.primary,
                  unselectedItemColor: colorScheme.onSurfaceVariant,
                  onTap: (index) {
                    if (widget.onNavigateToPage != null) {
                      widget.onNavigateToPage!(index);
                    }
                    Navigator.pop(context);
                  },
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Calendar',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.explore),
                      label: 'Explore',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Profile',
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

  Widget _buildTaskItem(Meeting task, ColorScheme colorScheme) {
    return Dismissible(
      key: Key(task.id ?? DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20),
        child: Icon(Icons.check_circle, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.check_circle, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        _toggleTaskCompletion(task);
        return false; // Don't actually dismiss, just toggle
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: task.isCompleted
              ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.isCompleted
                ? colorScheme.outlineVariant
                : colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showDetails(task, colorScheme),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // Checkbox
                  InkWell(
                    onTap: () => _toggleTaskCompletion(task),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task.isCompleted
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: 2,
                        ),
                        color: task.isCompleted
                            ? colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: task.isCompleted
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: colorScheme.onPrimary,
                            )
                          : null,
                    ),
                  ),
                  SizedBox(width: 16),

                  // Task info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title ?? 'Untitled',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: task.isCompleted
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: colorScheme.onSurfaceVariant,
                            decorationThickness: 2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            // Category
                            Icon(
                              Icons.label_outline,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 4),
                            Text(
                              task.category ?? 'No Category',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(width: 16),
                            // Time
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 4),
                            Text(
                              DateFormat('hh:mm a').format(task.from),
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Delete button
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    onPressed: () => _deleteTask(task),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(Meeting task, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          task.title ?? 'Untitled',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.label_outline,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 8),
                Text(
                  task.category ?? 'No Category',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(DateFormat('MMM dd, yyyy').format(task.from)),
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(DateFormat('hh:mm a').format(task.from)),
                  ),
                ),
              ],
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),
              Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                task.description!,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
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
