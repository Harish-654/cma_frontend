class ClubModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String colorHex;
  final DateTime createdAt;

  ClubModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.colorHex,
    required this.createdAt,
  });

  // From JSON (from Supabase)
  factory ClubModel.fromJson(Map<String, dynamic> json) {
    return ClubModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      colorHex: json['color_hex'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // To JSON (to send to Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'color_hex': colorHex,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
