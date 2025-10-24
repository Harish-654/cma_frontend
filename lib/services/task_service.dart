import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/meeting.dart';
import 'package:flutter/material.dart';

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create personal task
  Future<void> createPersonalTask(Meeting task) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase.from('tasks').insert({
      'title': task.title,
      'description': task.description,
      'category': task.category,
      'due_date': task.from.toIso8601String(),
      'color': '#${task.background.value.toRadixString(16).substring(2)}',
      'created_by': userId,
      'is_personal': true,
    });
  }

  // Create class task (for representatives)
  Future<void> createClassTask({
    required Meeting task,
    required String classId,
    required List<String> studentIds,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Insert task
    final taskResponse = await _supabase
        .from('tasks')
        .insert({
          'title': task.title,
          'description': task.description,
          'category': task.category,
          'due_date': task.from.toIso8601String(),
          'color': '#${task.background.value.toRadixString(16).substring(2)}',
          'created_by': userId,
          'class_id': classId,
          'is_personal': false,
        })
        .select()
        .single();

    // Assign to students
    for (String studentId in studentIds) {
      await _supabase.from('task_assignments').insert({
        'task_id': taskResponse['id'],
        'student_id': studentId,
      });
    }
  }

  // Get user tasks (personal + assigned)
  Future<List<Meeting>> getUserTasks() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // Get personal tasks
    final personalTasks = await _supabase
        .from('tasks')
        .select()
        .eq('created_by', userId)
        .eq('is_personal', true);

    // Get assigned tasks
    final assignedTasks = await _supabase
        .from('task_assignments')
        .select('*, tasks(*)')
        .eq('student_id', userId);

    List<Meeting> meetings = [];

    // Convert personal tasks
    for (var task in personalTasks) {
      meetings.add(_convertToMeeting(task, false));
    }

    // Convert assigned tasks
    for (var assignment in assignedTasks) {
      final task = assignment['tasks'];
      meetings.add(
        _convertToMeeting(task, assignment['is_completed'] ?? false),
      );
    }

    return meetings;
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('task_assignments')
        .update({
          'is_completed': isCompleted,
          'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
        })
        .eq('task_id', taskId)
        .eq('student_id', userId);
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }

  // Convert task to Meeting model
  Meeting _convertToMeeting(Map<String, dynamic> task, bool isCompleted) {
    final colorHex = task['color'] ?? 'FF6750A4';
    final colorValue = int.parse(colorHex.replaceAll('#', 'FF'), radix: 16);

    return Meeting(
      id: task['id'],
      title: task['title'],
      category: task['category'],
      description: task['description'],
      from: DateTime.parse(task['due_date']),
      to: DateTime.parse(task['due_date']).add(Duration(hours: 1)),
      background: Color(colorValue),
      isCompleted: isCompleted,
    );
  }
}
