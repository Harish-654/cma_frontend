import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';

class ClassService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create class (for representatives)
  Future<ClassModel> createClass({
    required String name,
    String? description,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Generate unique class code
    final codeResult = await _supabase.rpc('generate_class_code');
    final classCode = codeResult as String;

    final response = await _supabase
        .from('classes')
        .insert({
          'name': name,
          'description': description,
          'class_code': classCode,
          'representative_id': userId,
        })
        .select()
        .single();

    return ClassModel.fromJson(response);
  }

  // Join class with code (for students)
  Future<void> joinClass(String classCode) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Get class by code
    final classData = await _supabase
        .from('classes')
        .select()
        .eq('class_code', classCode)
        .single();

    // Add student to class
    await _supabase.from('class_members').insert({
      'class_id': classData['id'],
      'student_id': userId,
    });
  }

  // Get classes (for representatives)
  Future<List<ClassModel>> getMyClasses() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('classes')
        .select()
        .eq('representative_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => ClassModel.fromJson(json)).toList();
  }

  // Get joined classes (for students)
  Future<List<ClassModel>> getJoinedClasses() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('class_members')
        .select('classes(*)')
        .eq('student_id', userId);

    return (response as List)
        .map((item) => ClassModel.fromJson(item['classes']))
        .toList();
  }

  // Get class members
  Future<List<UserModel>> getClassMembers(String classId) async {
    final response = await _supabase
        .from('class_members')
        .select('users(*)')
        .eq('class_id', classId);

    return (response as List)
        .map((item) => UserModel.fromJson(item['users']))
        .toList();
  }

  // Leave class
  Future<void> leaveClass(String classId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('class_members')
        .delete()
        .eq('class_id', classId)
        .eq('student_id', userId);
  }

  // Delete class (for representatives)
  Future<void> deleteClass(String classId) async {
    await _supabase.from('classes').delete().eq('id', classId);
  }
}
