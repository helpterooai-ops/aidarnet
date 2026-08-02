import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/card_service.dart';

class CardPurchaseScreen extends StatefulWidget {
  const CardPurchaseScreen({super.key});

  @override
  State<CardPurchaseScreen> createState() => _CardPurchaseScreenState();
}

class _CardPurchaseScreenState extends State<CardPurchaseScreen> {
  final CardService _cardService = CardService();

  final List<Map<String, dynamic>> _categories = [
    {'value': '500', 'title': 'فئة 500 ريال', 'wholesalePrice': 450.0},
    {'value': '1000', 'title': 'فئة 1000 ريال', 'wholesalePrice': 900.0},
    {'value': '2000', 'title': 'فئة 2000 ريال', 'wholesalePrice': 1800.0},
    {'value': '5000', 'title': 'فئة 5000 ريال', 'wholesalePrice': 4500.0},
  ];

  void _openPurchaseDialog(Map<String, dynamic> category, int availableCount) {
    if (availableCount <= 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('الكروت غير متوفرة', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'عذراً، لا توجد كروت متاحة حالياً في ${category['title']}.\nيرجى التواصل مع الإدارة لإضافة كروت جديدة.',
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      return;
    }

    final double wholesalePrice = category['wholesalePrice'];
    final TextEditingController paidController = TextEditingController(text: category['value']);
    double customerPaid = double.tryParse(category['value']) ?? wholesalePrice;
    double profit = customerPaid - wholesalePrice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تفاصيل كرت ${category['title']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          'المتوفر: $availableCount',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('سعر الشراء للوكيل:', style: TextStyle(fontSize: 15, color: Colors.grey)),
                      Text(
                        '$wholesalePrice ريال',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: paidController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'المبلغ المستلم من الزبون (ريال)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        customerPaid = double.tryParse(val) ?? 0.0;
                        profit = customerPaid - wholesalePrice;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: profit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: profit >= 0 ? Colors.green.shade300 : Colors.red.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          profit >= 0 ? 'الربح المتوقع:' : 'تنبيه الخسارة:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: profit >= 0 ? Colors.green.shade900 : Colors.red.shade900,
                          ),
                        ),
                        Text(
                          '${profit.toStringAsFixed(1)} ريال',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: profit >= 0 ? Colors.green.shade900 : Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        _processCardDraw(category, wholesalePrice, customerPaid);
                      },
                      child: const Text('تأكيد سحب الكرت', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _processCardDraw(Map<String, dynamic> category, double wholesalePrice, double customerPaid) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await _cardService.drawCard(
        categoryValue: category['value'],
        wholesalePrice: wholesalePrice,
        customerPaid: customerPaid,
      );

      if (mounted) Navigator.pop(context);

      if (result != null && mounted) {
        final String cardCode = result['cardCode'];
        final double profit = result['profit'];

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Column(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
                SizedBox(height: 8),
                Text('تم الشراء بنجاح 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('رمز الكرت (${category['title']}):', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // تم التبديل إلى grey.shade100 و grey.shade300
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    cardCode,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('صافي الربح: $profit ريال', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded),
                label: const Text('نسخ رمز الكرت'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: cardCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ الرمز للحافظة بنجاح')),
                  );
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context),
                child: const Text('متابعة'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('عذراً، لا توجد كروت متاحة حالياً في ${category['title']}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شراء كروت شبكة الدار نت'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final String collectionName = 'cards_${cat['value']}';

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(collectionName)
                // تم التعديل إلى الصيغة الحديثة
                .where('status', isEqualTo: 'available')
                .snapshots(),
            builder: (context, snapshot) {
              final int count = snapshot.hasData ? snapshot.data!.docs.length : 0;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: count > 0 ? const Color(0xFF0F172A) : Colors.grey,
                    child: const Icon(Icons.wifi_rounded, color: Colors.white),
                  ),
                  title: Text(
                    cat['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    'المتوفر حالياً: $count كرت',
                    style: TextStyle(
                      color: count > 0 ? Colors.green.shade700 : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _openPurchaseDialog(cat, count),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: count > 0 ? const Color(0xFFD97706) : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('سحب كرت'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
