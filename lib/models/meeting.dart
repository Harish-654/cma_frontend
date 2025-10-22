import 'package:flutter/material.dart';

class Meeting {
  Meeting({
    this.id,
    this.title,
    this.category,
    this.description,
    required this.from,
    required this.to,
    required this.background,
    this.isAllDay = false,
  });

  String? id;
  String? title;
  String? category;
  String? description;
  DateTime from;
  DateTime to;
  Color background;
  bool isAllDay;

  Map<String, dynamic> toJson() {
    return {
      'id': id ?? '',
      'title': title ?? '',
      'category': category ?? '',
      'description': description ?? '',
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
      'color': background.value,
      'isAllDay': isAllDay,
    };
  }

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id']?.toString(),
      title: json['title']?.toString(),
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      from: json['from'] != null
          ? DateTime.parse(json['from'])
          : DateTime.now(),
      to: json['to'] != null
          ? DateTime.parse(json['to'])
          : DateTime.now().add(Duration(hours: 1)),
      background: json['color'] != null
          ? Color(json['color'] as int)
          : Color(0xFF3F51B5),
      isAllDay: json['isAllDay'] as bool? ?? false,
    );
  }
}
