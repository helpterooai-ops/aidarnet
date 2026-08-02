import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// دالة سحب كرت وتحديث حالته وتسجيل بيانات المستخدم بدقة
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

      final String userEmail = user.email ?? 'بدون بريد';
      final String username = userEmail.contains('@') 
          ? userEmail.split('@').first 
          : (user.displayName ?? user.uid);

      final collectionName = 'cards_$categoryValue';

      // 1. البحث عن كرت متاح فقط (available)
      final querySnapshot = await _db
          .collection(collectionName)
          .where('status', isEqualTo: 'available')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
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

        final dataMap = freshSnapshot.data() as Map<String, dynamic>?;
        if (dataMap?['status'] != 'available') {
          throw Exception("عذراً، تم سحب هذا الكرت للتو من قبل مستخدم آخر.");
        }

        // تحديث حالة الكرت وربطه باسم المستخدم
        transaction.update(docRef, {
          'status': 'used',
          'userUid': user.uid,
          'userEmail': userEmail,
          'username': username,
          'usedAt': FieldValue.serverTimestamp(),
        });

        // تسجيل العملية في سجل المبيعات لتمكين الاستعادة لاحقاً
        final salesRef = _db.collection('sales_history').doc();
        transaction.set(salesRef, {
          'saleId': salesRef.id,
          'cardCode': cardCode,
          'category': categoryValue,
          'wholesalePrice': wholesalePrice,
          'customerPaid': customerPaid,
          'profit': profit,
          'userUid': user.uid,
          'userEmail': userEmail,
          'username': username,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      return {
        'cardCode': cardCode,
        'profit': profit,
        'username': username,
      };
    } catch (e) {
      rethrow;
    }
  }
}
