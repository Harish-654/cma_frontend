import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/class_service.dart';
import '../main_screen.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _classService = ClassService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String _selectedRole = 'student';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    if (!_isLogin && _nameController.text.isEmpty) {
      _showError('Please enter your name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => MainScreen()));
      } else {
        await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          role: _selectedRole,
        );

        if (!mounted) return;

        if (_selectedRole == 'representative') {
          await _showCreateClassDialog();
        } else {
          await _showJoinClassDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showCreateClassDialog() async {
    if (!mounted) return;

    final nameController = TextEditingController();
    final descController = TextEditingController();
    final batchController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final shouldContinue = await showDialog<bool>(
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
              Navigator.of(dialogContext).pop(false);
            },
            child: Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                scaffoldMessenger.showSnackBar(
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

                Navigator.of(dialogContext).pop(true);

                // Show class code in new dialog
                await _showClassCodeDialog(newClass.classCode);
              } catch (e) {
                scaffoldMessenger.showSnackBar(
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

    // Navigate to main screen after dialog closes
    if (mounted) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    }
  }

  Future<void> _showClassCodeDialog(String classCode) async {
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
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
                    classCode,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  SizedBox(width: 12),
                  IconButton(
                    icon: Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: classCode));
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Code copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Students can join using this code',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Future<void> _showJoinClassDialog() async {
    if (!mounted) return;

    final codeController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Join a Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the class code provided by your representative:'),
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
              Navigator.of(dialogContext).pop(false);
            },
            child: Text('Skip for now'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Please enter a class code')),
                );
                return;
              }

              try {
                await _classService.joinClass(
                  codeController.text.toUpperCase(),
                );

                Navigator.of(dialogContext).pop(true);

                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Successfully joined class!')),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Invalid code: ${e.toString()}')),
                );
              }
            },
            child: Text('Join'),
          ),
        ],
      ),
    );

    codeController.dispose();

    // Navigate to main screen after dialog closes
    if (mounted) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 80, color: colorScheme.primary),
                SizedBox(height: 24),
                Text(
                  _isLogin ? 'Welcome Back' : 'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _isLogin ? 'Sign in to continue' : 'Sign up to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 40),

                if (!_isLogin) ...[
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'I am a:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Student'),
                                value: 'student',
                                groupValue: _selectedRole,
                                onChanged: (value) {
                                  setState(() => _selectedRole = value!);
                                },
                                activeColor: colorScheme.primary,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Representative'),
                                value: 'representative',
                                groupValue: _selectedRole,
                                onChanged: (value) {
                                  setState(() => _selectedRole = value!);
                                },
                                activeColor: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                TextField(
                  controller: _emailController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isLogin ? 'Sign In' : 'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    setState(() => _isLogin = !_isLogin);
                  },
                  child: Text(
                    _isLogin
                        ? 'Don\'t have an account? Sign Up'
                        : 'Already have an account? Sign In',
                    style: TextStyle(color: colorScheme.primary),
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
