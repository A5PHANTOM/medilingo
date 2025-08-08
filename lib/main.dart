import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:medilingo/screens/login_screen.dart';
import 'firebase_options.dart'; // Corrected import path

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediLingo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Poppins',
      ),
      home: LoginScreen(),
    );
  }
}