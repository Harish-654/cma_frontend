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
  String? expandedTaskId;

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

  void _toggleTaskExpansion(Meeting task) {
    setState(() {
      if (expandedTaskId == task.id) {
        expandedTaskId = null;
      } else {
        expandedTaskId = task.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
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
                color: const Color.fromARGB(255, 121, 121, 121),
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              DateFormat('MMMM dd, yyyy').format(widget.selectedDate),
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 185, 185, 185),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${todayTasks.where((t) => t.isCompleted).length}/${todayTasks.length}',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'SF Pro Text',
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
                        color: Colors.white38,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No tasks for this day',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'SF Pro Text',
                          color: Colors.white60,
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

          // Floating Navigation Bar
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.only(bottom: 20),
                child: Container(
                  width: MediaQuery.of(context).size.width - 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BottomNavigationBar(
                      backgroundColor: Colors.grey[900],
                      currentIndex: 0,
                      elevation: 0,
                      selectedItemColor: Colors.teal,
                      unselectedItemColor: Colors.white60,
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
        ],
      ),
    );
  }

  Widget _buildTaskItem(Meeting task) {
    return Dismissible(
      key: Key(task.id ?? DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.teal,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20),
        child: Icon(Icons.check_circle, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.teal,
          borderRadius: BorderRadius.circular(16),
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
              ? Colors.grey[900]!.withOpacity(0.5)
              : Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: task.isCompleted ? Colors.grey[700]! : Colors.grey[800]!,
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
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: 1.0,
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
                  color: task.isCompleted ? Colors.teal : Colors.white60,
                  width: 2,
                ),
                color: task.isCompleted ? Colors.teal : Colors.transparent,
              ),
              child: task.isCompleted
                  ? Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          SizedBox(width: 16),

          // Task info
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
                        ? Colors.white
                        : const Color.fromARGB(255, 227, 227, 227),
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: Colors.white38,
                    decorationThickness: 2,
                  ),
                  child: Text(task.title ?? 'Untitled'),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    // Category
                    Icon(Icons.label_outline, size: 14, color: Colors.white60),
                    SizedBox(width: 4),
                    Text(
                      task.category ?? 'No Category',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'SF Pro Text',
                        color: Colors.white38,
                      ),
                    ),
                    SizedBox(width: 16),
                    // Time
                    Icon(Icons.access_time, size: 14, color: Colors.white38),
                    SizedBox(width: 4),
                    Text(
                      DateFormat('hh:mm a').format(task.from),
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'SF Pro Text',
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
            onPressed: () => _deleteTask(task),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedTaskCard(Meeting task) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with checkbox and delete button
          Row(
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
                      color: task.isCompleted ? Colors.teal : Colors.white60,
                      width: 2,
                    ),
                    color: task.isCompleted ? Colors.teal : Colors.transparent,
                  ),
                  child: task.isCompleted
                      ? Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              SizedBox(width: 16),

              // Task title
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: task.isCompleted
                        ? Colors.white
                        : const Color.fromARGB(255, 227, 227, 227),
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: Colors.white38,
                    decorationThickness: 2,
                  ),
                  child: Text(task.title ?? 'Untitled'),
                ),
              ),

              // Delete button
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red[300],
                  size: 20,
                ),
                onPressed: () => _deleteTask(task),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Category and time row
          AnimatedOpacity(
            duration: Duration(milliseconds: 400),
            opacity: 1.0,
            child: Row(
              children: [
                Icon(Icons.label_outline, size: 16, color: Colors.white60),
                SizedBox(width: 8),
                Text(
                  task.category ?? 'No Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'SF Pro Text',
                    color: Colors.white70,
                  ),
                ),
                SizedBox(width: 24),
                Icon(Icons.access_time, size: 16, color: Colors.white60),
                SizedBox(width: 8),
                Text(
                  DateFormat('hh:mm a').format(task.from),
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'SF Pro Text',
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // Date row
          AnimatedOpacity(
            duration: Duration(milliseconds: 500),
            opacity: 1.0,
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.white60),
                SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(task.from),
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'SF Pro Text',
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Description section
          if (task.description != null && task.description!.isNotEmpty) ...[
            SizedBox(height: 16),
            AnimatedOpacity(
              duration: Duration(milliseconds: 600),
              opacity: 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.white30),
                  SizedBox(height: 12),
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'SF Pro Text',
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    task.description!,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'SF Pro Text',
                      color: Colors.white60,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: Text(
          'Delete Task',
          style: TextStyle(fontFamily: 'SF Pro Display', color: Colors.white70),
        ),
        content: Text(
          'Are you sure you want to delete this task?',
          style: TextStyle(fontFamily: 'SF Pro Text', color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                color: Colors.white70,
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
                color: Colors.red[300],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
