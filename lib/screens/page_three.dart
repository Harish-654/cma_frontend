import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/class_service.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';
import 'main_screen.dart';
import 'hall_booking_page.dart';

class PageThree extends StatefulWidget {
  const PageThree({super.key});

  @override
  State<PageThree> createState() => _PageThreeState();
}

class _PageThreeState extends State<PageThree> {
  final AuthService _authService = AuthService();
  final ClassService _classService = ClassService();
  
  UserModel? currentUser;
  List<ClassModel> classes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndClasses();
  }

  Future<void> _loadUserAndClasses() async {
    setState(() => isLoading = true);
    
    try {
      final user = await _authService.getCurrentUser();
      final userClasses = await _classService.getMyClasses();
      
      if (mounted) {
        setState(() {
          currentUser = user;
          classes = userClasses;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user and classes: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showAddClassDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddClassBottomSheet(
        onClassAdded: _loadUserAndClasses,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (currentUser == null) {
      return Center(child: Text('Not logged in'));
    }

    final isRepresentative = currentUser!.role == 'representative';

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Section
                Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFF6B7280).withOpacity(0.2),
                      child: Icon(Icons.person, size: 50, color: Color(0xFF6B7280)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      currentUser!.name,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      currentUser!.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF6750A4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        currentUser!.role == 'representative' ? 'Representative' : 'Student',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6750A4),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32),

                // Hall Booking Button (Representatives only)
                if (isRepresentative) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HallBookingPage()),
                        );
                      },
                      icon: Icon(Icons.meeting_room, color: Colors.white),
                      label: Text('Hall Booking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],

                // My Classes Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.school, color: Color(0xFF6750A4), size: 24),
                        SizedBox(width: 8),
                        Text(
                          'My Classes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _showAddClassDialog,
                      icon: Icon(Icons.add_circle, color: Color(0xFF007AFF), size: 28),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Classes List
                classes.isEmpty
                    ? Container(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.class_, size: 64, color: Color(0xFF9CA3AF)),
                            SizedBox(height: 16),
                            Text(
                              'Not in any class. Join one!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: classes.map((classItem) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  classItem.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D1D1F),
                                  ),
                                ),
                                if (classItem.description != null) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    classItem.description!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF007AFF).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        classItem.classCode,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF007AFF),
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                    if (classItem.batch != null) ...[
                                      SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF6B7280).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          classItem.batch!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                SizedBox(height: 32),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      await _authService.signOut();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    icon: Icon(Icons.logout, color: Color(0xFFEF4444)),
                    label: Text('Logout'),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFFEF4444),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddClassBottomSheet extends StatefulWidget {
  final VoidCallback onClassAdded;

  const _AddClassBottomSheet({required this.onClassAdded});

  @override
  State<_AddClassBottomSheet> createState() => _AddClassBottomSheetState();
}

class _AddClassBottomSheetState extends State<_AddClassBottomSheet> {
  final ClassService _classService = ClassService();
  bool isCreateMode = true;
  bool isProcessing = false;

  // Create class controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController batchController = TextEditingController();

  // Join class controller
  final TextEditingController classCodeController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    batchController.dispose();
    classCodeController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    if (nameController.text.trim().isEmpty) {
      _showError('Please enter class name');
      return;
    }

    setState(() => isProcessing = true);

    try {
      await _classService.createClass(
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
        batch: batchController.text.trim().isEmpty ? null : batchController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onClassAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Class created successfully!')),
        );
      }
    } catch (e) {
      print('Error creating class: $e');
      _showError('Failed to create class');
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _joinClass() async {
    if (classCodeController.text.trim().isEmpty) {
      _showError('Please enter class code');
      return;
    }

    setState(() => isProcessing = true);

    try {
      await _classService.joinClass(classCodeController.text.trim());

      if (mounted) {
        Navigator.pop(context);
        widget.onClassAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined class successfully!')),
        );
      }
    } catch (e) {
      print('Error joining class: $e');
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Switcher
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isCreateMode = true),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isCreateMode ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Create Class',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isCreateMode ? Color(0xFF007AFF) : Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isCreateMode = false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isCreateMode ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Join Class',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: !isCreateMode ? Color(0xFF007AFF) : Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Create Class Form
            if (isCreateMode) ...[
              TextField(
                controller: nameController,
                enabled: !isProcessing,
                decoration: InputDecoration(
                  labelText: 'Class Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Color(0xFFF9FAFB),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                enabled: !isProcessing,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Color(0xFFF9FAFB),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: batchController,
                enabled: !isProcessing,
                decoration: InputDecoration(
                  labelText: 'Batch (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Color(0xFFF9FAFB),
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : _createClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isProcessing
                      ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(
                          'Create Class',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
            ],

            // Join Class Form
            if (!isCreateMode) ...[
              TextField(
                controller: classCodeController,
                enabled: !isProcessing,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Class Code',
                  hintText: 'Enter 6-digit code',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Color(0xFFF9FAFB),
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : _joinClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF34C759),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isProcessing
                      ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(
                          'Join Class',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
