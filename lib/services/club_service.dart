import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/club_model.dart';
import '../models/event_model.dart';

class ClubService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all clubs
  Future<List<ClubModel>> getAllClubs() async {
    try {
      final response = await _supabase
          .from('clubs')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((club) => ClubModel.fromJson(club))
          .toList();
    } catch (e) {
      print('Error fetching clubs: $e');
      return [];
    }
  }

  // Get user's clubs (clubs they've joined)
  Future<List<ClubModel>> getUserClubs(String userId) async {
    try {
      final response = await _supabase
          .from('club_members')
          .select('club_id, clubs(*)')
          .eq('user_id', userId);

      return (response as List)
          .map((item) => ClubModel.fromJson(item['clubs']))
          .toList();
    } catch (e) {
      print('Error fetching user clubs: $e');
      return [];
    }
  }

  // Join a club
  Future<void> joinClub(String clubId, String userId) async {
    try {
      await _supabase.from('club_members').insert({
        'club_id': clubId,
        'user_id': userId,
        'role': 'member',
      });
    } catch (e) {
      print('Error joining club: $e');
      rethrow;
    }
  }

  // Leave a club
  Future<void> leaveClub(String clubId, String userId) async {
    try {
      await _supabase
          .from('club_members')
          .delete()
          .eq('club_id', clubId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error leaving club: $e');
      rethrow;
    }
  }

  // Check if user is club admin
  Future<bool> isClubAdmin(String clubId, String userId) async {
    try {
      final response = await _supabase
          .from('club_members')
          .select('role')
          .eq('club_id', clubId)
          .eq('user_id', userId)
          .single();

      return response['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  // Get all events for a club
  Future<List<EventModel>> getClubEvents(String clubId) async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('club_id', clubId)
          .order('date_time', ascending: true);

      return (response as List)
          .map((event) => EventModel.fromJson(event))
          .toList();
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  // Create a new event (only admins can do this)
  Future<EventModel> createEvent({
    required String clubId,
    required String title,
    required String description,
    required String venue,
    required DateTime dateTime,
    required String posterUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final response = await _supabase
          .from('events')
          .insert({
            'club_id': clubId,
            'title': title,
            'description': description,
            'venue': venue,
            'date_time': dateTime.toIso8601String(),
            'poster_url': posterUrl,
            'created_by': userId,
          })
          .select()
          .single();

      return EventModel.fromJson(response);
    } catch (e) {
      print('Error creating event: $e');
      rethrow;
    }
  }

  // Delete an event (only admins)
  Future<void> deleteEvent(String eventId) async {
    try {
      await _supabase.from('events').delete().eq('id', eventId);
    } catch (e) {
      print('Error deleting event: $e');
      rethrow;
    }
  }

  // Update an event (only admins)
  Future<void> updateEvent({
    required String eventId,
    String? title,
    String? description,
    String? venue,
    DateTime? dateTime,
    String? posterUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (venue != null) updates['venue'] = venue;
      if (dateTime != null) updates['date_time'] = dateTime.toIso8601String();
      if (posterUrl != null) updates['poster_url'] = posterUrl;

      if (updates.isNotEmpty) {
        await _supabase.from('events').update(updates).eq('id', eventId);
      }
    } catch (e) {
      print('Error updating event: $e');
      rethrow;
    }
  }
}
