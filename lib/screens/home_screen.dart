import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'card_purchase_screen.dart';
import 'sales_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBannerIndex = 0;
  late Timer _bannerTimer;

  final List<String> _bannerMessages = [
    'جميع الخدمات تعمل بنجاح 🚀',
    'أسرع شبكة اتصال إنترنت في المنطقة ⚡',
    'سرعة فائقة ومستقرة مع شبكة الدار نت 🌐',
  ];

  @override
  void initState() {
    super.initState();
    // تبديل البطاقة الترويجية كل 4 ثوانٍ
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentBannerIndex = (_currentBannerIndex + 1) % _bannerMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text(
          'Al-Dar Net | الدار نت',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFF59E0B)),
            tooltip: 'تسجيل الخروج',
            onPressed: _logout,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. البطاقة الإعلانية البارزة (إطار زجاجي فاخر بحواف منحنية)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD97706).withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'تحديثات الشبكة المباشرة',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      _bannerMessages[_currentBannerIndex],
                      key: ValueKey<int>(_currentBannerIndex),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'أقسام الخدمات والعمليات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),

            // 2. شبكة الأقسام الستة (6 مربعات أنيقة)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildGridCard(
                  title: 'شبكات الواي فاي',
                  subtitle: 'شراء كروت وتوليد أكواد',
                  icon: Icons.wifi_rounded,
                  iconColor: const Color(0xFF1E88E5),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CardPurchaseScreen()),
                    );
                  },
                ),
                _buildGridCard(
                  title: 'سجل المبيعات',
                  subtitle: 'عمليات الشراء والأرباح',
                  icon: Icons.receipt_long_rounded,
                  iconColor: const Color(0xFFD97706),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SalesHistoryScreen()),
                    );
                  },
                ),
                _buildGridCard(
                  title: 'إدارة الرصيد',
                  subtitle: 'كشف الحساب والعمولات',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF10B981),
                  onTap: () => _showSectionInfo(context, 'إدارة الرصيد', 'رصيدك الحالي نشط وتستطيع السحب حسب العمولات المعتمدة.'),
                ),
                _buildGridCard(
                  title: 'قائمة الأسعار',
                  subtitle: 'فئات الكروت والخصومات',
                  icon: Icons.sell_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  onTap: () => _showSectionInfo(context, 'قائمة الأسعار', 'أسعار الفئات:\n• 500 ريال (شراء 450)\n• 1000 ريال (شراء 900)\n• 2000 ريال (شراء 1800)\n• 5000 ريال (شراء 4500)'),
                ),
                _buildGridCard(
                  title: 'الدعم الفني',
                  subtitle: 'تواصل مباشر مع الإدارة',
                  icon: Icons.support_agent_rounded,
                  iconColor: const Color(0xFFEC4899),
                  onTap: () => _showSectionInfo(context, 'الدعم الفني', 'للدعم الفني وإضافة كروت جديدة التواصل مع إدارة شبكة الدار نت.'),
                ),
                _buildGridCard(
                  title: 'الملف الشخصي',
                  subtitle: 'إعدادات الحساب والوكيل',
                  icon: Icons.person_outline_rounded,
                  iconColor: const Color(0xFF64748B),
                  onTap: () => _showSectionInfo(context, 'الملف الشخصي', 'حساب الوكيل مفعل وجاهز لإجراء العمليات.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.slate.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSectionInfo(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}
