class EventModel {
  final String id;
  final String clubId;
  final String title;
  final String description;
  final String venue;
  final DateTime dateTime;
  final String posterUrl;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.clubId,
    required this.title,
    required this.description,
    required this.venue,
    required this.dateTime,
    required this.posterUrl,
    required this.createdAt,
  });

  // From JSON (from Supabase)
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      venue: json['venue'] as String,
      dateTime: DateTime.parse(json['date_time'] as String),
      posterUrl: json['poster_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // To JSON (to send to Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'club_id': clubId,
      'title': title,
      'description': description,
      'venue': venue,
      'date_time': dateTime.toIso8601String(),
      'poster_url': posterUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
