class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final DateTime dueDate;
  final String? color;
  final String createdBy;
  final String? classId;
  final bool isPersonal;
  final bool isCompleted;
  final DateTime? completedAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.category,
    required this.dueDate,
    this.color,
    required this.createdBy,
    this.classId,
    required this.isPersonal,
    this.isCompleted = false,
    this.completedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      dueDate: DateTime.parse(json['due_date']),
      color: json['color'],
      createdBy: json['created_by'],
      classId: json['class_id'],
      isPersonal: json['is_personal'] ?? true,
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'due_date': dueDate.toIso8601String(),
      'color': color,
      'created_by': createdBy,
      'class_id': classId,
      'is_personal': isPersonal,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
