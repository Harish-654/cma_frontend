import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors
              .deepPurpleAccent, // Change this to any color you want (Colors.purple, Colors.green, etc.)
          brightness: Brightness.light,
        ),
      ),
      home: MainScreen(),
    );
  }
}
