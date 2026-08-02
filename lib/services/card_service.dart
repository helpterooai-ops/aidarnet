import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// دالة سحب كرت من الفئة المطلوبة وتسجيل عملية البيع وحساب الربح
  Future<Map<String, dynamic>?> drawCard({
    required String categoryValue,
    required double wholesalePrice,
    required double customerPaid,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("يجب تسجيل الدخول أولاً لسحب كرت.");
      }

      final collectionName = 'cards_$categoryValue';

      // 1. البحث عن كرت متاح فقط (available)
      final querySnapshot = await _db
          .collection(collectionName)
          .where('status', '==', 'available')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null; // لا توجد كروت متاحة
      }

      final docRef = querySnapshot.docs.first.reference;
      final cardData = querySnapshot.docs.first.data();
      final String cardCode = (cardData['card'] ?? cardData['card_number'] ?? cardData['code']) as String;

      final double profit = customerPaid - wholesalePrice;

      // 2. تنفيذ المعاملة الآمنة (Transaction)
      await _db.runTransaction((transaction) async {
        final freshSnapshot = await transaction.get(docRef);

        if (!freshSnapshot.exists) {
          throw Exception("الكرت غير موجود.");
        }

        final currentStatus = freshSnapshot.data()?['status'];
        if (currentStatus != 'available') {
          throw Exception("عذراً، تم سحب هذا الكرت للتو من قبل مستخدم آخر.");
        }

        // تحديث الكرت إلى مستخدم
        transaction.update(docRef, {
          'status': 'used',
          'userUid': user.uid,
          'customerNumber': user.email ?? user.uid,
          'usedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // إضافة عملية الشراء في سجل المبيعات (sales_history)
        final salesRef = _db.collection('sales_history').doc();
        transaction.set(salesRef, {
          'saleId': salesRef.id,
          'cardCode': cardCode,
          'category': categoryValue,
          'wholesalePrice': wholesalePrice,
          'customerPaid': customerPaid,
          'profit': profit,
          'userUid': user.uid,
          'userEmail': user.email ?? 'بدون بريد',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      return {
        'cardCode': cardCode,
        'profit': profit,
      };
    } catch (e) {
      print("خطأ أثناء سحب الكرت: $e");
      rethrow;
    }
  }
}
