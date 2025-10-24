import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meeting.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/add_class_task_dialog.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../services/class_service.dart';
import '../main.dart';

class TaskViewPage extends StatefulWidget {
  final DateTime selectedDate;
  final List<Meeting> allTasks;
  final Function(Meeting) onDeleteTask;
  final Function(int)? onNavigateToPage;
  final bool isRepresentative;

  const TaskViewPage({super.key, 
    required this.selectedDate,
    required this.allTasks,
    required this.onDeleteTask,
    this.onNavigateToPage,
    this.isRepresentative = false,
  });

  @override
  State<TaskViewPage> createState() => _TaskViewPageState();
}

class _TaskViewPageState extends State<TaskViewPage>
    with SingleTickerProviderStateMixin {
  late List<Meeting> todayTasks;
  String? expandedTaskId;
  bool isSpeedDialOpen = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _forYouSlideAnimation;
  late Animation<double> _forClassSlideAnimation;

  final TaskService _taskService = TaskService();
  final ClassService _classService = ClassService();

  @override
  void initState() {
    super.initState();
    _loadTodayTasks();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _forYouSlideAnimation = Tween<double>(begin: 0.0, end: -64.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _forClassSlideAnimation = Tween<double>(begin: 0.0, end: -128.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSpeedDial() {
    setState(() {
      isSpeedDialOpen = !isSpeedDialOpen;
      if (isSpeedDialOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
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
    if (!mounted) return; // Add check

    setState(() {
      task.isCompleted = !task.isCompleted;
    });
  }

  // Update _toggleTaskExpansion
  void _toggleTaskExpansion(Meeting task) {
    if (!mounted) return; // Add check

    setState(() {
      if (expandedTaskId == task.id) {
        expandedTaskId = null;
      } else {
        expandedTaskId = task.id;
      }
    });
  }

  // For Students - Save to Supabase
  // Update _addPersonalTask
  void _addPersonalTask() async {
    if (!mounted) return; // Add at start
    _toggleSpeedDial();

    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        selectedDate: widget.selectedDate,
        onTaskCreated: (task) async {
          try {
            await _taskService.createPersonalTask(task);

            if (!mounted) return; // Check before setState

            setState(() {
              todayTasks.add(task);
              todayTasks.sort((a, b) => a.from.compareTo(b.from));
            });

            if (mounted) {
              // Check before using context
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Task created successfully!'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              // Check before using context
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  // For Representatives "For You" - Save to Local Storage
  void _addRepresentativePersonalTask() async {
    if (!mounted) return; // Add at start
    _toggleSpeedDial();

    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        selectedDate: widget.selectedDate,
        onTaskCreated: (task) async {
          try {
            task.isLocal = true;
            await _taskService.createLocalTask(task);

            if (!mounted) return; // Check before setState

            setState(() {
              todayTasks.add(task);
              todayTasks.sort((a, b) => a.from.compareTo(b.from));
            });

            if (mounted) {
              // Check before using context
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Personal task created locally!'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              // Check before using context
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  // For Representatives "For Class" - Save to Supabase
  void _addClassTask() async {
    if (!mounted) return; // Add at start
    _toggleSpeedDial();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        if (mounted) Navigator.pop(context);
        throw Exception('Not authenticated');
      }

      final classes = await _classService.getMyClasses();

      if (!mounted) return; // Check before using context

      if (classes.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You haven\'t created any classes yet. Create one in Profile.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final classId = classes[0].id;
      final students = await _classService.getClassMembers(classId);

      if (!mounted) return; // Check before using context

      Navigator.pop(context);

      if (students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No students in your class yet. Share code: ${classes[0].classCode}',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AddClassTaskDialog(
          selectedDate: widget.selectedDate,
          classStudents: students,
          onTaskCreated: (task, studentIds) async {
            try {
              await _taskService.createClassTask(
                task: task,
                classId: classId,
                studentIds: studentIds,
              );

              if (mounted) {
                // Check before using context
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Task sent to ${studentIds.length} students!',
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                // Check before using context
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        // Check before using context
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
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
                fontFamily: 'SF Pro Text',
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              DateFormat('MMMM dd, yyyy').format(widget.selectedDate),
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'SF Pro Display',
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
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${todayTasks.where((t) => t.isCompleted).length}/${todayTasks.length}',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'SF Pro Text',
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
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
                        color: colorScheme.surfaceContainerHighest,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No tasks for this day',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'SF Pro Text',
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
                    return _buildTaskItem(todayTasks[index]);
                  },
                ),

          // Backdrop
          if (isSpeedDialOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleSpeedDial,
                child: Container(color: Colors.black.withOpacity(0.7)),
              ),
            ),

          // Navigation Bar
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.only(bottom: 20),
                child: Container(
                  width: MediaQuery.of(context).size.width - 40,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.2),
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
                      type: BottomNavigationBarType.fixed,
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
            ),
          ),

          // Speed Dial FAB
          Positioned(
            right: 20,
            bottom: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.isRepresentative)
                  AnimatedBuilder(
                    animation: _forClassSlideAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _forClassSlideAnimation.value),
                        child: Opacity(
                          opacity: isSpeedDialOpen ? 1.0 : 0.0,
                          child: child,
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'For Class',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 12,
                              fontFamily: 'SF Pro Text',
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Material(
                          elevation: 4,
                          shape: CircleBorder(),
                          color: Colors.purple[400],
                          child: InkWell(
                            customBorder: CircleBorder(),
                            onTap: _addClassTask,
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.group,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (widget.isRepresentative) SizedBox(height: 16),

                AnimatedBuilder(
                  animation: _forYouSlideAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _forYouSlideAnimation.value),
                      child: Opacity(
                        opacity: isSpeedDialOpen ? 1.0 : 0.0,
                        child: child,
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'For You',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 12,
                            fontFamily: 'SF Pro Text',
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Material(
                        elevation: 4,
                        shape: CircleBorder(),
                        color: colorScheme.primary,
                        child: InkWell(
                          customBorder: CircleBorder(),
                          onTap: widget.isRepresentative
                              ? _addRepresentativePersonalTask
                              : _addPersonalTask,
                          child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.person,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: Material(
                        elevation: 6,
                        shape: CircleBorder(),
                        color: colorScheme.primary,
                        child: InkWell(
                          customBorder: CircleBorder(),
                          onTap: widget.isRepresentative
                              ? _toggleSpeedDial
                              : _addPersonalTask,
                          child: Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.add,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Meeting task) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(task.id ?? DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20),
        child: Icon(Icons.check_circle, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.check_circle, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        _toggleTaskCompletion(task);
        return false;
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: task.isCompleted
              ? colorScheme.surfaceContainerHighest.withOpacity(0.5)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: task.isCompleted
                ? colorScheme.outline.withOpacity(0.5)
                : colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleTaskExpansion(task),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedSize(
              duration: Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: Container(
                padding: EdgeInsets.all(16),
                child: expandedTaskId == task.id
                    ? _buildExpandedTaskCard(task)
                    : _buildCollapsedTaskCard(task),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedTaskCard(Meeting task) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: 1.0,
      child: Row(
        children: [
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
                      : colorScheme.onSurfaceVariant,
                  width: 2,
                ),
                color: task.isCompleted
                    ? colorScheme.primary
                    : Colors.transparent,
              ),
              child: task.isCompleted
                  ? Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: task.isCompleted
                        ? colorScheme.onSurface
                        : colorScheme.onSurface,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: colorScheme.onSurfaceVariant,
                    decorationThickness: 2,
                  ),
                  child: Text(task.title ?? 'Untitled'),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
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
                        fontFamily: 'SF Pro Text',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 16),
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
                        fontFamily: 'SF Pro Text',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
    );
  }

  Widget _buildExpandedTaskCard(Meeting task) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                          : colorScheme.onSurfaceVariant,
                      width: 2,
                    ),
                    color: task.isCompleted
                        ? colorScheme.primary
                        : Colors.transparent,
                  ),
                  child: task.isCompleted
                      ? Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: task.isCompleted
                        ? colorScheme.onSurface
                        : colorScheme.onSurface,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: colorScheme.onSurfaceVariant,
                    decorationThickness: 2,
                  ),
                  child: Text(task.title ?? 'Untitled'),
                ),
              ),
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
          SizedBox(height: 16),
          AnimatedOpacity(
            duration: Duration(milliseconds: 400),
            opacity: 1.0,
            child: Row(
              children: [
                Icon(
                  Icons.label_outline,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 8),
                Text(
                  task.category ?? 'No Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'SF Pro Text',
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: 24),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 8),
                Text(
                  DateFormat('hh:mm a').format(task.from),
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'SF Pro Text',
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          AnimatedOpacity(
            duration: Duration(milliseconds: 500),
            opacity: 1.0,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(task.from),
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'SF Pro Text',
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            SizedBox(height: 16),
            AnimatedOpacity(
              duration: Duration(milliseconds: 600),
              opacity: 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: colorScheme.outline),
                  SizedBox(height: 12),
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'SF Pro Text',
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    task.description!,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'SF Pro Text',
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _deleteTask(Meeting task) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Delete Task',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            color: colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this task?',
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            color: colorScheme.onSurfaceVariant,
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
          TextButton(
            onPressed: () {
              widget.onDeleteTask(task);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                color: colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
