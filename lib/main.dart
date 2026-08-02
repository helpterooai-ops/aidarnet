import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("خطأ في تهيئة فايربيس: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الدار نت | Al-Dar Net',
      debugShowCheckedModeBanner: false,

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'IBMPlexSansArabic',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E293B), // أزرق كحلي مطفي فاخر
          primary: const Color(0xFF0F172A),
          secondary: const Color(0xFFD97706), // ذهبي مطفي أنيق
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),

      home: const SplashScreen(),
    );
  }
}
