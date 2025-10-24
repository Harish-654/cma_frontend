import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';

class ClassService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Generate random 6-character class code
  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // Get classes where user is representative
  Future<List<ClassModel>> getMyClasses() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('classes')
          .select()
          .eq('representative_by', userId);

      return (response as List)
          .map((json) => ClassModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching classes: $e');
      return [];
    }
  }

  // Get class members (students)
  Future<List<UserModel>> getClassMembers(String classId) async {
    try {
      final response = await _supabase
          .from('class_members')
          .select('users(*)')
          .eq('class_id', classId);

      return (response as List)
          .map((item) => UserModel.fromJson(item['users']))
          .toList();
    } catch (e) {
      print('Error fetching class members: $e');
      return [];
    }
  }

  // Create a new class
  Future<ClassModel> createClass({
    required String name,
    String? description,
    String? batch,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final classCode = _generateClassCode();

      print(
        'Inserting class: name=$name, batch=$batch, code=$classCode',
      ); // Debug

      final response = await _supabase
          .from('classes')
          .insert({
            'name': name,
            'description': description,
            'class_code': classCode,
            'batch': batch,
            'representative_by': userId,
          })
          .select()
          .single();

      print('Class inserted successfully: $response'); // Debug

      return ClassModel.fromJson(response);
    } catch (e, stackTrace) {
      print('Error in createClass: $e'); // Debug
      print('Stack trace: $stackTrace'); // Debug
      rethrow;
    }
  }

  // Join class with code
  Future<void> joinClass(String classCode) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Find class by code
    final classResponse = await _supabase
        .from('classes')
        .select()
        .eq('class_code', classCode)
        .single();

    // Add user to class
    await _supabase.from('class_members').insert({
      'class_id': classResponse['id'],
      'user_id': userId,
    });
  }
}
