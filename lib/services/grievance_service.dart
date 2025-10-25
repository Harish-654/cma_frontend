import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/grievance_model.dart';

class GrievanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all grievances ordered by time (newest first)
  Future<List<GrievanceModel>> getAllGrievances() async {
    try {
      final response = await _supabase
          .from('grievances')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => GrievanceModel.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching grievances: $e');
      return [];
    }
  }

  // Get grievances ordered by upvotes (priority)
  Future<List<GrievanceModel>> getPriorityGrievances() async {
    try {
      final response = await _supabase
          .from('grievances')
          .select()
          .order('upvote_count', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => GrievanceModel.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching priority grievances: $e');
      return [];
    }
  }

  // Create new grievance
  Future<GrievanceModel?> createGrievance(String message) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final response = await _supabase
          .from('grievances')
          .insert({
            'user_id': user.id,
            'user_name': user.userMetadata?['name'] ?? 'Anonymous',
            'user_email': user.email ?? '',
            'message': message,
            'upvote_count': 0,
          })
          .select()
          .single();

      return GrievanceModel.fromJson(response);
    } catch (e) {
      print('Error creating grievance: $e');
      return null;
    }
  }

  // Check if user has upvoted a grievance
  Future<bool> hasUserUpvoted(String grievanceId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('grievance_upvotes')
          .select()
          .eq('grievance_id', grievanceId)
          .eq('user_id', user.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking upvote: $e');
      return false;
    }
  }

  // Upvote a grievance
  Future<bool> upvoteGrievance(String grievanceId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Check if already upvoted
      final hasUpvoted = await hasUserUpvoted(grievanceId);
      if (hasUpvoted) {
        print('User has already upvoted this grievance');
        return false;
      }

      // Add upvote (trigger will automatically update upvote_count)
      await _supabase.from('grievance_upvotes').insert({
        'grievance_id': grievanceId,
        'user_id': user.id,
      });

      return true;
    } catch (e) {
      print('Error upvoting: $e');
      return false;
    }
  }

  // Remove upvote
  Future<bool> removeUpvote(String grievanceId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await _supabase
          .from('grievance_upvotes')
          .delete()
          .eq('grievance_id', grievanceId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      print('Error removing upvote: $e');
      return false;
    }
  }

  // Delete grievance (only by owner)
  Future<bool> deleteGrievance(String grievanceId) async {
    try {
      await _supabase.from('grievances').delete().eq('id', grievanceId);
      return true;
    } catch (e) {
      print('Error deleting grievance: $e');
      return false;
    }
  }

  // Real-time subscription to grievances
  RealtimeChannel subscribeToGrievances(Function(List<GrievanceModel>) onUpdate) {
    return _supabase
        .channel('grievances_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'grievances',
          callback: (payload) async {
            // Refresh grievances list
            final grievances = await getAllGrievances();
            onUpdate(grievances);
          },
        )
        .subscribe();
  }
}
