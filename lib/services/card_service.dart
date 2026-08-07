import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// إنشاء حساب الوكيل (مرة واحدة) حتى تستطيع الإدارة ربطه وتحويل الرصيد له
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

  /// سحب كرت مع فحص الرصيد وخصم سعر الجملة داخل معاملة آمنة
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
    final agentRef = _db.collection('agents').doc(user.uid);

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

    await _db.runTransaction((transaction) async {
      // 1) فحص رصيد الوكيل
      final agentSnap = await transaction.get(agentRef);
      if (!agentSnap.exists) throw Exception("لا يوجد حساب وكيل — تواصل مع الإدارة.");
      final double balance =
          ((agentSnap.data()?['balance'] as num?) ?? 0).toDouble();
      if (balance < wholesalePrice) {
        throw Exception(
            "رصيدك غير كافٍ (رصيدك: ${balance.toStringAsFixed(0)} — المطلوب: ${wholesalePrice.toStringAsFixed(0)} ريال).");
      }

      // 2) فحص الكرت (منع التعارض)
      final fresh = await transaction.get(docRef);
      if (!fresh.exists) throw Exception("الكرت غير موجود.");
      if ((fresh.data() as Map<String, dynamic>?)?['status'] != 'available') {
        throw Exception("عذراً، تم سحب هذا الكرت للتو من مستخدم آخر.");
      }

      // 3) خصم الرصيد بسعر الجملة
      final spent = ((agentSnap.data()?['totalSpent'] as num?) ?? 0).toDouble();
      transaction.update(agentRef, {
        'balance': balance - wholesalePrice,
        'totalSpent': spent + wholesalePrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4) تحديث الكرت
      transaction.update(docRef, {
        'status': 'used',
        'userUid': user.uid,
        'userEmail': userEmail,
        'username': username,
        'usedAt': FieldValue.serverTimestamp(),
      });

      // 5) سجل المبيعات
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
