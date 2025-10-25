class ExamHallModel {
  final String id;
  final String hallNumber;
  final String venue;
  final int capacity;
  final String? floor;
  final String? building;
  final DateTime createdAt;

  ExamHallModel({
    required this.id,
    required this.hallNumber,
    required this.venue,
    required this.capacity,
    this.floor,
    this.building,
    required this.createdAt,
  });

  factory ExamHallModel.fromJson(Map<String, dynamic> json) {
    return ExamHallModel(
      id: json['id'] as String,
      hallNumber: json['hall_number'] as String,
      venue: json['venue'] as String,
      capacity: json['capacity'] as int,
      floor: json['floor'] as String?,
      building: json['building'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hall_number': hallNumber,
      'venue': venue,
      'capacity': capacity,
      'floor': floor,
      'building': building,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
