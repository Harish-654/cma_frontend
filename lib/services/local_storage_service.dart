import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart'; // Add this import
import '../models/meeting.dart';

class LocalStorageService {
  static const String _tasksKey = 'local_tasks';

  // Save task locally
  Future<void> saveLocalTask(Meeting task) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = await getLocalTasks();

    // Convert to JSON-compatible format
    tasks.add({
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'category': task.category,
      'from': task.from.toIso8601String(),
      'to': task.to.toIso8601String(),
      'color': task.background.value.toString(),
      'isCompleted': task.isCompleted,
    });

    await prefs.setString(_tasksKey, json.encode(tasks));
  }

  // Get all local tasks
  Future<List<Map<String, dynamic>>> getLocalTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_tasksKey);

    if (tasksJson == null) return [];

    return List<Map<String, dynamic>>.from(json.decode(tasksJson));
  }

  // Get local tasks as Meeting objects
  Future<List<Meeting>> getLocalMeetings() async {
    final tasks = await getLocalTasks();
    return tasks.map((taskData) {
      return Meeting(
        id: taskData['id'],
        title: taskData['title'],
        description: taskData['description'],
        category: taskData['category'],
        from: DateTime.parse(taskData['from']),
        to: DateTime.parse(taskData['to']),
        background: Color(int.parse(taskData['color'])),
        isCompleted: taskData['isCompleted'] ?? false,
      );
    }).toList();
  }

  // Delete local task
  Future<void> deleteLocalTask(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = await getLocalTasks();

    tasks.removeWhere((task) => task['id'] == taskId);
    await prefs.setString(_tasksKey, json.encode(tasks));
  }

  // Update task completion
  Future<void> updateLocalTaskCompletion(
    String taskId,
    bool isCompleted,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = await getLocalTasks();

    final taskIndex = tasks.indexWhere((task) => task['id'] == taskId);
    if (taskIndex != -1) {
      tasks[taskIndex]['isCompleted'] = isCompleted;
      await prefs.setString(_tasksKey, json.encode(tasks));
    }
  }

  // Clear all local tasks (optional, for testing)
  Future<void> clearAllTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
  }
}
