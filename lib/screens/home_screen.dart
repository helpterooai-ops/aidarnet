import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/card_service.dart';
import 'card_purchase_screen.dart';
import 'sales_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardService _cardService = CardService();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _carouselTimer;

  final List<Map<String, String>> _bannerItems = [
    {'title': 'شبكة الدار نت الفائقة', 'subtitle': 'تغطية واسعة وسرعة عالية في نقل البيانات'},
    {'title': 'سحب وتوزيع آمن', 'subtitle': 'توليد وشراء الكروت بنظام الحماية المباشر'},
    {'title': 'خدمة المبيعات والوكلاء', 'subtitle': 'تابع أرباحك وعمليات السحب فوراً ولحظياً'},
  ];

  @override
  void initState() {
    super.initState();
    _cardService.ensureAgentAccount();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _currentPage = (_currentPage + 1) % _bannerItems.length;
        _pageController.animateToPage(_currentPage,
            duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('الدار نت | بوابة الوكيل'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBalanceCard(user),
          const SizedBox(height: 18),
          _buildCarousel(),
          const SizedBox(height: 18),
          _buildMainActionButton(
            title: 'كروت الشبكة',
            subtitle: 'سحب الكروت المتاحة وتصدير الأكواد للزبائن',
            icon: Icons.wifi_tethering_rounded,
            accentColor: const Color(0xFF0F172A),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const CardPurchaseScreen())),
          ),
          const SizedBox(height: 20),
          _buildMainActionButton(
            title: 'سجل المبيعات',
            subtitle: 'متابعة العمليات السابقة واستعادة الكروت بالأرقام واسم المستخدم',
            icon: Icons.receipt_long_rounded,
            accentColor: const Color(0xFFD97706),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SalesHistoryScreen())),
          ),
        ],
      ),
    );
  }

  /// بطاقة الرصيد + معرف الوكيل
  Widget _buildBalanceCard(User? user) {
    if (user == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('رصيدك الحالي', style: TextStyle(color: Colors.white70, fontSize: 13)),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('agents').doc(user.uid).snapshots(),
                builder: (context, snap) {
                  // ✅ إصلاح الخطأ: التحقق من وجود البيانات وتحويلها إلى Map
                  if (!snap.hasData || !snap.data!.exists) {
                    return const Text('0 ريال', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 22, fontWeight: FontWeight.w900));
                  }
                  final data = snap.data!.data() as Map<String, dynamic>?;
                  final balance = ((data?['balance'] as num?) ?? 0).toDouble();
                  
                  return Text(
                    '${balance.toStringAsFixed(0)} ريال',
                    style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 22, fontWeight: FontWeight.w900),
                  );
                },
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),
          const Text('معرف الوكيل (أرسله للإدارة لشحن رصيدك):',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  user.uid,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Color(0xFFF59E0B), size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: user.uid));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ المعرف — أرسله للإدارة'), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: 130,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _bannerItems.length,
        itemBuilder: (context, index) {
          final item = _bannerItems[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item['title']!, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Text(item['subtitle']!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(18)),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
