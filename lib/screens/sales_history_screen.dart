import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package0cloud_firestore/cloud_firestore.dart' if (dart.library.io) 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المبيعات والعمليات'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sales_history')
            // تم التعديل إلى الصيغة الحديثة
            .where('userUid', isEqualTo: user?.uid ?? '')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history_toggle_off_rounded, size: 70, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد عمليات شراء مسجلة حتى الآن', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          double totalProfit = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalProfit += (data['profit'] as num?)?.toDouble() ?? 0.0;
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي أرباحك المسجلة:', style: TextStyle(color: Colors.white, fontSize: 16)),
                    Text(
                      '${totalProfit.toStringAsFixed(1)} ريال',
                      style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String code = data['cardCode'] ?? '****';
                    final String cat = data['category'] ?? '';
                    final double profit = (data['profit'] as num?)?.toDouble() ?? 0.0;
                    final Timestamp? ts = data['timestamp'] as Timestamp?;
                    final DateTime dt = ts?.toDate() ?? DateTime.now();

                    final String formattedDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} | ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFD97706),
                          child: Icon(Icons.check, color: Colors.white),
                        ),
                        title: Text('كرت فئة $cat ريال - الكود: $code'),
                        subtitle: Text('التاريخ: $formattedDate\nالربح: $profit ريال'),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم نسخ كود الكرت')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('تحميل / حفظ تقرير سجل المبيعات'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      StringBuffer sb = StringBuffer();
                      sb.writeln("=== تقرير سجل مبيعات الدار نت ===");
                      sb.writeln("إجمالي الأرباح: $totalProfit ريال");
                      sb.writeln("عدد العمليات: ${docs.length}");
                      sb.writeln("===============================");
                      for (var doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        sb.writeln("فئة: ${data['category']} | كود: ${data['cardCode']} | ربح: ${data['profit']}");
                      }

                      Clipboard.setData(ClipboardData(text: sb.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ تقرير المبيعات الكامل إلى الحافظة لطباعته أو حفظه')),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
