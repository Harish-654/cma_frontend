class ClassModel {
  final String id;
  final String name;
  final String? description;
  final String? batch; // Add this
  final String classCode;
  final String representativeId;
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.name,
    this.description,
    this.batch, // Add this
    required this.classCode,
    required this.representativeId,
    required this.createdAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      batch: json['batch'], // Add this
      classCode: json['class_code'],
      representativeId: json['representative_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
