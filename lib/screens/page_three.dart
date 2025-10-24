import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/class_service.dart';
import '../models/user_model.dart';
import '../models/class_model.dart';
import 'main_screen.dart';
import 'auth/login_page.dart';

class PageThree extends StatefulWidget {
  @override
  State<PageThree> createState() => _PageThreeState();
}

class _PageThreeState extends State<PageThree> {
  final AuthService _authService = AuthService();
  final ClassService _classService = ClassService();
  UserModel? _currentUser;
  List<ClassModel> _myClasses = [];
  bool _isLoading = true;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted || _isLoadingData) return;

    _isLoadingData = true;
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final user = await _authService.getCurrentUserProfile();
      final classes = await _classService.getMyClasses();

      if (!mounted) {
        _isLoadingData = false;
        return;
      }

      setState(() {
        _currentUser = user;
        _myClasses = classes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');

      if (!mounted) {
        _isLoadingData = false;
        return;
      }

      setState(() => _isLoading = false);
    } finally {
      _isLoadingData = false;
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();

      if (!mounted) return;

      // Force navigation to login page
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      print('Error logging out: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: ${e.toString()}')),
      );
    }
  }

  Future<void> _showCreateClassDialog() async {
    if (!mounted) return;

    final nameController = TextEditingController();
    final descController = TextEditingController();
    final batchController = TextEditingController();

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Create Your Class'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Class Name',
                  hintText: 'e.g., Computer Science 2024',
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: batchController,
                decoration: InputDecoration(
                  labelText: 'Batch (Optional)',
                  hintText: 'e.g., 2024-2028',
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Brief description',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(null); // Return null for skip
            },
            child: Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Please enter class name')),
                );
                return;
              }

              try {
                final newClass = await _classService.createClass(
                  name: nameController.text.trim(),
                  description: descController.text.isEmpty
                      ? null
                      : descController.text.trim(),
                  batch: batchController.text.isEmpty
                      ? null
                      : batchController.text.trim(),
                );

                // Return the class code
                Navigator.of(dialogContext).pop(newClass.classCode);
              } catch (e) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );

    nameController.dispose();
    descController.dispose();
    batchController.dispose();

    if (!mounted) return;

    // If class was created, show the code
    if (result != null && result.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (codeContext) => AlertDialog(
          title: Text('Class Created! 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Share this code with your students:'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      result,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: result));
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Code copied!')));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(codeContext).pop(),
              child: Text('Got it!'),
            ),
          ],
        ),
      );
    }

    // Navigate to main screen AFTER all dialogs close
    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => MainScreen()));
  }

  Future<void> _showJoinClassDialog() async {
    if (!mounted) return;

    final codeController = TextEditingController();

    final joined = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Join a Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the class code from your representative:'),
            SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Class Code',
                hintText: 'e.g., ABC123',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false); // Skip
            },
            child: Text('Skip for now'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Please enter a class code')),
                );
                return;
              }

              try {
                await _classService.joinClass(
                  codeController.text.toUpperCase().trim(),
                );

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Joined class successfully!')),
                );

                Navigator.of(dialogContext).pop(true); // Success
              } catch (e) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: Text('Join'),
          ),
        ],
      ),
    );

    codeController.dispose();

    if (!mounted) return;

    // Show success message if joined
    if (joined == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Welcome to your class!')));
    }

    // Navigate to main screen AFTER dialog closes
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => MainScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _currentUser?.fullName ?? 'User',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _currentUser?.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentUser?.role == 'representative'
                            ? 'Class Representative'
                            : 'Student',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // My Classes Section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.school, color: colorScheme.primary),
                        SizedBox(width: 8),
                        Text(
                          'My Classes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: _currentUser?.role == 'representative'
                              ? _showCreateClassDialog
                              : _showJoinClassDialog,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (_myClasses.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            _currentUser?.role == 'representative'
                                ? 'No classes yet. Create one!'
                                : 'Not in any class. Join one!',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      ...(_myClasses.map((classItem) {
                        final messenger = ScaffoldMessenger.of(context);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(
                              Icons.class_,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            classItem.name,
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (classItem.batch != null)
                                Text('Batch: ${classItem.batch}'),
                              Text('Code: ${classItem.classCode}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: classItem.classCode),
                              );
                              messenger.showSnackBar(
                                SnackBar(content: Text('Code copied!')),
                              );
                            },
                          ),
                        );
                      })),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Logout
              ListTile(
                leading: Icon(Icons.logout, color: colorScheme.error),
                title: Text(
                  'Logout',
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
