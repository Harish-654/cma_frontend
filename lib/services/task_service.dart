import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/meeting.dart';
import 'package:flutter/material.dart';
import 'local_storage_service.dart';

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalStorageService _localStorage = LocalStorageService();

  // Get user's tasks from Supabase
  Future<List<Meeting>> getUserTasks() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // Personal tasks
      final personalTasks = await _supabase
          .from('tasks')
          .select()
          .eq('created_by', userId)
          .isFilter('class_id', null);

      // Class tasks assigned to user
      final assignedTasks = await _supabase
          .from('task_assignments')
          .select('tasks(*)')
          .eq('student_id', userId);

      List<Meeting> meetings = [];

      // Convert personal tasks
      for (var task in personalTasks) {
        meetings.add(_taskToMeeting(task));
      }

      // Convert assigned tasks
      for (var item in assignedTasks) {
        if (item['tasks'] != null) {
          meetings.add(_taskToMeeting(item['tasks']));
        }
      }

      return meetings;
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  // Get ALL tasks (Supabase + Local Storage)
  Future<List<Meeting>> getAllUserTasks() async {
    List<Meeting> allTasks = [];

    // 1. Get Supabase tasks
    try {
      final supabaseTasks = await getUserTasks();
      allTasks.addAll(supabaseTasks);
    } catch (e) {
      print('Error loading Supabase tasks: $e');
    }

    // 2. Get local tasks
    try {
      final localTasks = await _localStorage.getLocalMeetings();
      for (var task in localTasks) {
        task.isLocal = true;
      }
      allTasks.addAll(localTasks);
    } catch (e) {
      print('Error loading local tasks: $e');
    }

    return allTasks;
  }

  // Convert task to Meeting
  Meeting _taskToMeeting(Map<String, dynamic> task) {
    return Meeting(
      id: task['id'],
      title: task['title'],
      description: task['description'],
      category: task['category'] ?? 'Task',
      from: DateTime.parse(task['due_date']),
      to: DateTime.parse(task['due_date']).add(Duration(hours: 1)),
      background: Color(0xFF6750A4),
      isCompleted: task['is_completed'] ?? false,
      isLocal: false,
    );
  }

  // Create personal task (for students)
  Future<void> createPersonalTask(Meeting task) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase.from('tasks').insert({
      'title': task.title,
      'description': task.description,
      'category': task.category,
      'due_date': task.from.toIso8601String(),
      'created_by': userId,
      'class_id': null,
    });
  }

  // Create local task (for representative's personal tasks)
  Future<void> createLocalTask(Meeting task) async {
    await _localStorage.saveLocalTask(task);
  }

  // Create class task and assign to students
  Future<void> createClassTask({
    required Meeting task,
    required String classId,
    required List<String> studentIds,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // 1. Create the task
    final response = await _supabase
        .from('tasks')
        .insert({
          'title': task.title,
          'description': task.description,
          'category': task.category,
          'due_date': task.from.toIso8601String(),
          'created_by': userId,
          'class_id': classId,
        })
        .select()
        .single();

    final taskId = response['id'];

    // 2. Assign to students
    final assignments = studentIds
        .map((studentId) => {'task_id': taskId, 'student_id': studentId})
        .toList();

    await _supabase.from('task_assignments').insert(assignments);
  }

  // Delete task from Supabase
  Future<void> deleteTask(String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }

  // Delete task (local or Supabase)
  Future<void> deleteTaskAny(Meeting task) async {
    if (task.isLocal) {
      await _localStorage.deleteLocalTask(task.id!);
    } else {
      await deleteTask(task.id!);
    }
  }

  // Toggle task completion in Supabase
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    await _supabase
        .from('tasks')
        .update({'is_completed': isCompleted})
        .eq('id', taskId);
  }

  // Toggle completion (local or Supabase)
  Future<void> toggleTaskCompletionAny(Meeting task) async {
    if (task.isLocal) {
      await _localStorage.updateLocalTaskCompletion(task.id!, task.isCompleted);
    } else {
      await toggleTaskCompletion(task.id!, task.isCompleted);
    }
  }
}
