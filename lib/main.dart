import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/main_screen.dart';
import 'screens/auth/login_page.dart';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zyfftqdylmluzoivknoy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp5ZmZ0cWR5bG1sdXpvaXZrbm95Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyNjcxOTMsImV4cCI6MjA3Njg0MzE5M30.W-AlgGN-jEcZWY6gx-Jz7aYVa8AHCr1O0NFXBYY9jK4',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'College Management App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF6750A4),
          brightness: Brightness.dark,
          background: Colors.black,
          surface: Color(0xFF1C1B1F),
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.light,
      home: AuthGate(), // Use AuthGate instead of MainScreen
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Check if user is logged in
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          // User is logged in -> Show main screen
          return MainScreen();
        } else {
          // User is not logged in -> Show login page
          return LoginPage();
        }
      },
    );
  }
}
