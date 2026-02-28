import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/caregiver/caregiver_home.dart';

void main() {
  runApp(const PillCareApp());
}

class PillCareApp extends StatelessWidget {
  const PillCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PillCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.manrope().fontFamily,
        scaffoldBackgroundColor: const Color(0xFFF6F6F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF135BEC),
          primary: const Color(0xFF135BEC),
          secondary: const Color(0xFF7C3AED),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/caregiver': (context) => const CaregiverHome(),
      },
    );
  }
}
