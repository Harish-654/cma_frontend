class GrievanceModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String message;
  final int upvoteCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  GrievanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.message,
    required this.upvoteCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GrievanceModel.fromJson(Map<String, dynamic> json) {
    return GrievanceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userEmail: json['user_email'] as String,
      message: json['message'] as String,
      upvoteCount: json['upvote_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'message': message,
      'upvote_count': upvoteCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
