class ClassModel {
  final String id;
  final String name;
  final String? description;
  final String classCode;
  final String representativeId;
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.name,
    this.description,
    required this.classCode,
    required this.representativeId,
    required this.createdAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      classCode: json['class_code'],
      representativeId: json['representative_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'class_code': classCode,
      'representative_id': representativeId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
