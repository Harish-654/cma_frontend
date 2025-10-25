import 'exam_hall_model.dart';

class HallBookingModel {
  final String id;
  final String hallId;
  final String bookedByUserId;
  final String bookedByName;
  final String bookedByEmail;
  final DateTime examDate;
  final String timeSlot;
  final String purpose;
  final DateTime createdAt;
  
  // Related hall details (from join)
  ExamHallModel? hall;

  HallBookingModel({
    required this.id,
    required this.hallId,
    required this.bookedByUserId,
    required this.bookedByName,
    required this.bookedByEmail,
    required this.examDate,
    required this.timeSlot,
    required this.purpose,
    required this.createdAt,
    this.hall,
  });

  factory HallBookingModel.fromJson(Map<String, dynamic> json) {
    return HallBookingModel(
      id: json['id'] as String,
      hallId: json['hall_id'] as String,
      bookedByUserId: json['booked_by_user_id'] as String,
      bookedByName: json['booked_by_name'] as String,
      bookedByEmail: json['booked_by_email'] as String,
      examDate: DateTime.parse(json['exam_date'] as String),
      timeSlot: json['time_slot'] as String,
      purpose: json['purpose'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      hall: json['exam_halls'] != null 
          ? ExamHallModel.fromJson(json['exam_halls'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hall_id': hallId,
      'booked_by_user_id': bookedByUserId,
      'booked_by_name': bookedByName,
      'booked_by_email': bookedByEmail,
      'exam_date': examDate.toIso8601String().split('T')[0],
      'time_slot': timeSlot,
      'purpose': purpose,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
