import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('سجل المبيعات واستعادة الكروت')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث باسم المستخدم أو كود الكرت لاستعادته...',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0F172A)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sales_history')
                  .where('userUid', isEqualTo: user?.uid ?? '')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)));
                }

                final docs = snapshot.data?.docs ?? [];

                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final code = (data['cardCode'] ?? '').toString().toLowerCase();
                  final username = (data['username'] ?? '').toString().toLowerCase();
                  final email = (data['userEmail'] ?? '').toString().toLowerCase();

                  return code.contains(_searchQuery) ||
                      username.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد عمليات مبيعات مطابقة',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    final String code = data['cardCode'] ?? '****';
                    final String cat = data['category'] ?? '';
                    final String username = data['username'] ?? 'مستخدم';
                    final double profit = (data['profit'] as num?)?.toDouble() ?? 0.0;
                    final Timestamp? ts = data['timestamp'] as Timestamp?;
                    final DateTime dt = ts?.toDate() ?? DateTime.now();

                    final String dateStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'فئة $cat ريال',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              '+$profit ريال',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          // ✅ تم تصحيح الاسم هنا إلى CrossAxisAlignment
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text('كود الكرت: $code', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                            Text('اسم المستخدم: $username | التاريخ: $dateStr', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_rounded, color: Color(0xFF0F172A)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                content: const Text('تم نسخ كود الكرت بنجاح'),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
