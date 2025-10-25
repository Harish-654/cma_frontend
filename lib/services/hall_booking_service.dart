import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exam_hall_model.dart';
import '../models/hall_booking_model.dart';

class HallBookingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all exam halls
  Future<List<ExamHallModel>> getAllHalls() async {
    try {
      final response = await _supabase
          .from('exam_halls')
          .select()
          .order('hall_number');

      return (response as List)
          .map((item) => ExamHallModel.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching halls: $e');
      return [];
    }
  }

  // Get available halls for date and time slot
  Future<List<ExamHallModel>> getAvailableHalls(
      DateTime date, String timeSlot) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      // Get all halls
      final allHalls = await getAllHalls();

      // Get booked hall IDs for this date and time
      final bookedResponse = await _supabase
          .from('hall_bookings')
          .select('hall_id')
          .eq('exam_date', dateStr)
          .eq('time_slot', timeSlot);

      final bookedHallIds = (bookedResponse as List)
          .map((item) => item['hall_id'] as String)
          .toSet();

      // Filter out booked halls
      return allHalls
          .where((hall) => !bookedHallIds.contains(hall.id))
          .toList();
    } catch (e) {
      print('Error fetching available halls: $e');
      return [];
    }
  }

  // Get booked halls for date and time slot
  Future<List<HallBookingModel>> getBookedHalls(
      DateTime date, String timeSlot) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('hall_bookings')
          .select('*, exam_halls(*)')
          .eq('exam_date', dateStr)
          .eq('time_slot', timeSlot)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => HallBookingModel.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching booked halls: $e');
      return [];
    }
  }

  // Book a hall
  Future<HallBookingModel?> bookHall({
    required String hallId,
    required DateTime examDate,
    required String timeSlot,
    required String purpose,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final dateStr = examDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('hall_bookings')
          .insert({
            'hall_id': hallId,
            'booked_by_user_id': user.id,
            'booked_by_name': user.userMetadata?['name'] ?? 'Unknown',
            'booked_by_email': user.email ?? '',
            'exam_date': dateStr,
            'time_slot': timeSlot,
            'purpose': purpose,
          })
          .select('*, exam_halls(*)')
          .single();

      return HallBookingModel.fromJson(response);
    } catch (e) {
      print('Error booking hall: $e');
      return null;
    }
  }

  // Cancel booking
  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _supabase.from('hall_bookings').delete().eq('id', bookingId);
      return true;
    } catch (e) {
      print('Error canceling booking: $e');
      return false;
    }
  }

  // Real-time subscription
  RealtimeChannel subscribeToBookings(
      Function(List<HallBookingModel>) onUpdate, DateTime date, String timeSlot) {
    final dateStr = date.toIso8601String().split('T')[0];
    
    return _supabase
        .channel('hall_bookings_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'hall_bookings',
          callback: (payload) async {
            final bookings = await getBookedHalls(date, timeSlot);
            onUpdate(bookings);
          },
        )
        .subscribe();
  }
}
