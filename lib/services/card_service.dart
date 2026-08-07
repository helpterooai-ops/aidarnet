import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// إنشاء حساب الوكيل (مرة واحدة) حتى تستطيع الإدارة ربطه بالـ UID
  Future<void> ensureAgentAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final ref = _db.collection('agents').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      final email = user.email ?? '';
      await ref.set({
        'uid': user.uid,
        'email': email,
        'name': email.contains('@') ? email.split('@').first : (user.displayName ?? user.uid),
        'balance': 0.0,
        'totalAdded': 0.0,
        'totalSpent': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// سحب كرت — الخصم يتم تلقائياً لأن الكرت يخرج من "المتاح" فينقص الرصيد المعروض
  Future<Map<String, dynamic>?> drawCard({
    required String categoryValue,
    required double wholesalePrice,
    required double customerPaid,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("يجب تسجيل الدخول أولاً.");

    final String userEmail = user.email ?? 'بدون بريد';
    final String username = userEmail.contains('@')
        ? userEmail.split('@').first
        : (user.displayName ?? user.uid);

    final collectionName = 'cards_$categoryValue';

    // البحث عن كرت متاح
    final querySnapshot = await _db
        .collection(collectionName)
        .where('status', isEqualTo: 'available')
        .limit(1)
        .get();
    if (querySnapshot.docs.isEmpty) return null;

    final docRef = querySnapshot.docs.first.reference;
    final cardData = querySnapshot.docs.first.data();
    final String cardCode =
        (cardData['card'] ?? cardData['card_number'] ?? cardData['code']) as String;
    final double profit = customerPaid - wholesalePrice;

    // معاملة آمنة لمنع التعارض بين وكيلين
    await _db.runTransaction((transaction) async {
      final fresh = await transaction.get(docRef);
      if (!fresh.exists) throw Exception("الكرت غير موجود.");
      if ((fresh.data() as Map<String, dynamic>?)?['status'] != 'available') {
        throw Exception("عذراً، تم سحب هذا الكرت للتو من مستخدم آخر.");
      }

      transaction.update(docRef, {
        'status': 'used',
        'userUid': user.uid,
        'userEmail': userEmail,
        'username': username,
        'usedAt': FieldValue.serverTimestamp(),
      });

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

    return {'cardCode': cardCode, 'profit': profit, 'username': username};
  }
}
