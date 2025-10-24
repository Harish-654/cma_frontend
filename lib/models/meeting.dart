import 'package:flutter/material.dart';

class Meeting {
  String? id;
  String? title;
  String? description;
  String? category;
  DateTime from;
  DateTime to;
  Color background;
  bool isCompleted;
  bool isLocal;
  bool isAllDay;

  Meeting({
    this.id,
    this.title,
    this.description,
    this.category,
    required this.from,
    required this.to,
    required this.background,
    this.isCompleted = false,
    this.isLocal = false,
    this.isAllDay = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
      'color': background.value.toString(),
      'isCompleted': isCompleted,
      'isAllDay': isAllDay,
    };
  }

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      from: DateTime.parse(json['from']),
      to: DateTime.parse(json['to']),
      background: Color(int.parse(json['color'])),
      isCompleted: json['isCompleted'] ?? false,
      isAllDay: json['isAllDay'] ?? false,
    );
  }
}
