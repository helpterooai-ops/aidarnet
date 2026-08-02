import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _isConnected = false;
  String _statusMessage = 'جاري التحقق من الاتصال بـ Firebase...';

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }

  /// دالة اختبار الاتصال بـ Firebase و Firestore
  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري التحقق من الاتصال بـ Firebase...';
    });

    try {
      // 1. التأكد من أن التطبيق متصل بـ Firebase Core
      if (Firebase.apps.isEmpty) {
        throw Exception("تطبيق Firebase غير مهيأ في Main.");
      }

      // 2. محاولة قراءة خفيفة جداً من Firestore لاختبار الاتصال بالأقمار/الخوادم
      await FirebaseFirestore.instance
          .collection('cards_500')
          .limit(1)
          .get(const GetOptions(source: Source.server));

      setState(() {
        _isConnected = true;
        _isLoading = false;
        _statusMessage = 'تم الاتصال بـ Firebase بنجاح! 🚀\nجميع الخدمات جاهزة للعمل.';
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isLoading = false;
        _statusMessage = 'حدث خطأ أثناء الاتصال بـ Firebase:\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الدار نت - اختبار الاتصال',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // حالة التحميل أو أيقونة النتيجة
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Icon(
                  _isConnected ? Icons.check_circle_outline : Icons.error_outline,
                  size: 80,
                  color: _isConnected ? Colors.green : Colors.red,
                ),

              const SizedBox(height: 24),

              // نص حالة الاتصال
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isLoading
                      ? Colors.blue.shade50
                      : (_isConnected ? Colors.green.shade50 : Colors.red.shade50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isLoading
                        ? Colors.blue.shade200
                        : (_isConnected ? Colors.green.shade300 : Colors.red.shade300),
                  ),
                ),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: _isLoading
                        ? Colors.blue.shade900
                        : (_isConnected ? Colors.green.shade900 : Colors.red.shade900),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // زر إعادة الفحص
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testFirebaseConnection,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة اختبار الاتصال'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'IBMPlexSansArabic',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
