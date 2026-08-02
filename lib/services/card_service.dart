import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// دالة سحب كرت من الفئة المطلوبة (مثلاً "500", "1000", "2000", "5000")
  Future<String?> drawCard(String categoryValue) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("يجب تسجيل الدخول أولاً لسحب كرت.");
      }

      // تحديد اسم المجموعة بناءً على الفئة
      final collectionName = 'cards_$categoryValue';

      // البحث عن أول كرت متاح (`available`) في هذه الفئة
      final querySnapshot = await _db
          .collection(collectionName)
          .where('status', '==', 'available')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null; // لا توجد كروت متاحة حالياً في هذه الفئة
      }

      final docRef = querySnapshot.docs.first.reference;
      final cardData = querySnapshot.docs.first.data();
      final cardCode = cardData['card'] as String;

      // تنفيذ المعاملة (Transaction) لضمان الأمان وتحديث الحالة بدقة
      await _db.runTransaction((transaction) async {
        final freshSnapshot = await transaction.get(docRef);
        
        if (!freshSnapshot.exists) {
          throw Exception("الكرت غير موجود.");
        }
        
        final currentStatus = freshSnapshot.data()?['status'];
        if (currentStatus != 'available') {
          throw Exception("عذراً، تم سحب هذا الكرت للتو من قبل مستخدم آخر. حاول مرة أخرى.");
        }

        // تحديث الكرت إلى مستخدم وإسناده لرقم/معرف المستخدم الحالي
        transaction.update(docRef, {
          'status': 'used',
          'userUid': user.uid,
          'customerNumber': user.email ?? user.uid,
          'usedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return cardCode; // إرجاع كود الكرت الناجح ليعرضه التطبيق للمستخدم
    } catch (e) {
      print("خطأ أثناء سحب الكرت: $e");
      rethrow;
    }
  }
}
