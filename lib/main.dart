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
    // 1️⃣ نعرّف الثيم الأساسي (مع الخط)
    final ThemeData baseTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'IBMPlexSansArabic',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E293B), // أزرق كحلي مطفي فاخر
        primary: const Color(0xFF0F172A),
        secondary: const Color(0xFFD97706), // ذهبي مطفي أنيق
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    );

    return MaterialApp(
      title: 'الدار نت | Al-Dar Net',
      debugShowCheckedModeBanner: false,

      // 2️⃣ الاتجاه من اليمين لليسار
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },

      // 3️⃣ الحل السحري: إجبار الخط على كل أنماط النصوص
      theme: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(fontFamily: 'IBMPlexSansArabic'),
        primaryTextTheme: baseTheme.primaryTextTheme.apply(fontFamily: 'IBMPlexSansArabic'),
      ),

      home: const SplashScreen(),
    );
  }
}