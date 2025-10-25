import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/class_model.dart';
import '../models/user_model.dart';

class ClassService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Fetch all classes where the user is either the representative or a member
  Future<List<ClassModel>> getMyClasses() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('getMyClasses: User not authenticated');
      return [];
    }

    try {
      print('=== GET MY CLASSES DEBUG ===');
      print('User ID: $userId');

      // Representative classes (created by user)
      print('Fetching representative classes...');
      final repClasses = await _supabase
          .from('classes')
          .select()
          .eq('representative_id', userId);

      print('Representative classes: ${repClasses.length}');

      // Member classes (joined by user, via class_members)
      print('Fetching member classes...');
      final memberResponse = await _supabase
          .from('class_members')
          .select('class_id, classes!inner(*)')
          .eq('user_id', userId);

      print('Member classes response: ${memberResponse.length}');

      // Merge and deduplicate by ID
      List<ClassModel> allClasses = [];

      // Add rep classes
      for (var json in (repClasses as List)) {
        allClasses.add(ClassModel.fromJson(json));
      }
      
      // Add member classes; avoid duplicates
      final repClassIds = allClasses.map((e) => e.id).toSet();
      for (var item in (memberResponse as List)) {
        if (item['classes'] != null) {
          final classModel = ClassModel.fromJson(item['classes']);
          if (!repClassIds.contains(classModel.id)) {
            allClasses.add(classModel);
          }
        }
      }

      print('Total classes: ${allClasses.length}');
      return allClasses;
    } catch (e, stackTrace) {
      print('=== ERROR FETCHING CLASSES ===');
      print('Error: $e');
      print('Stack: $stackTrace');
      return [];
    }
  }

  Future<List<UserModel>> getClassMembers(String classId) async {
    try {
      final response = await _supabase
          .from('class_members')
          .select('user_id, users!inner(*)')
          .eq('class_id', classId);

      return (response as List)
          .map((item) => UserModel.fromJson(item['users']))
          .toList();
    } catch (e) {
      print('Error fetching class members: $e');
      return [];
    }
  }

  Future<ClassModel> createClass({
    required String name,
    String? description,
    String? batch,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final classCode = _generateClassCode();

      print('=== CREATE CLASS DEBUG ===');
      print('Creating class: $name');

      final response = await _supabase
          .from('classes')
          .insert({
            'name': name,
            'description': description,
            'class_code': classCode,
            'batch': batch,
            'representative_id': userId,
          })
          .select()
          .single();

      print('Class created successfully!');
      return ClassModel.fromJson(response);
    } catch (e, stackTrace) {
      print('Error creating class: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> joinClass(String classCode) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      print('=== JOIN CLASS DEBUG ===');
      print('User ID: $userId');
      print('Class code: $classCode');

      if (userId == null) {
        print('ERROR: User not authenticated');
        throw Exception('Not authenticated');
      }

      // 1. Find class by code
      print('Step 1: Searching for class...');
      final classResponse = await _supabase
          .from('classes')
          .select()
          .eq('class_code', classCode.trim().toUpperCase())
          .maybeSingle();

      print('Class response: $classResponse');

      if (classResponse == null) {
        print('ERROR: Class not found');
        throw Exception('Invalid class code');
      }

      final classId = classResponse['id'];
      print('Class found: ${classResponse['name']} (ID: $classId)');

      // 2. Check if already member
      print('Step 2: Checking if already a member...');
      final existingMember = await _supabase
          .from('class_members')
          .select()
          .eq('class_id', classId)
          .eq('user_id', userId)
          .maybeSingle();

      print('Existing member check: $existingMember');

      if (existingMember != null) {
        print('ERROR: Already a member');
        throw Exception('Already a member of this class');
      }

      // 3. Join class
      print('Step 3: Inserting into class_members...');
      final insertData = {
        'class_id': classId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      };
      print('Insert data: $insertData');
      
      await _supabase.from('class_members').insert(insertData);

      // 4. Verify insertion
      print('Step 4: Verifying insert...');
      final verify = await _supabase
          .from('class_members')
          .select()
          .eq('class_id', classId)
          .eq('user_id', userId);
      print('Verification result: $verify');

      if (verify.isEmpty) {
        throw Exception('Failed to join class - insert did not persist');
      }

      print('SUCCESS: Joined class!');
    } catch (e, stackTrace) {
      print('=== ERROR JOINING CLASS ===');
      print('Error: $e');
      print('Type: ${e.runtimeType}');
      print('Stack: $stackTrace');
      rethrow;
    }
  }
}
