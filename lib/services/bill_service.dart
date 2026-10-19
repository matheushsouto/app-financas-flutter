import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bill.dart';

/// CRUD de contas a pagar em `users/{userId}/bills`.
class BillService {
  BillService({FirebaseFirestore? firestore}) : _injectedFirestore = firestore;

  /// Quantas ocorrências (incluindo a primeira) "Repetir todo mês" cria.
  static const int recurrenceMonths = 12;

  final FirebaseFirestore? _injectedFirestore;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('bills');

  /// Contas com vencimento no mês de [month], em ordem de vencimento.
  Stream<List<Bill>> watchByMonth(String userId, DateTime month) {
    final DateTime start = DateTime(month.year, month.month);
    final DateTime end = DateTime(month.year, month.month + 1);

    return _collection(userId)
        .where('dueDate', isGreaterThanOrEqualTo: start.millisecondsSinceEpoch)
        .where('dueDate', isLessThan: end.millisecondsSinceEpoch)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map((doc) => Bill.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Cria a conta. Com [repeatMonthly], cria também as dos próximos meses
  /// (mesmo dia; em meses curtos, o último dia do mês).
  Future<void> create(
    String userId,
    Bill bill, {
    bool repeatMonthly = false,
  }) async {
    final CollectionReference<Map<String, dynamic>> collection = _collection(
      userId,
    );

    if (!repeatMonthly) {
      await collection.add(bill.toMap());
      return;
    }

    final String recurrenceId = collection.doc().id;
    final WriteBatch batch = _firestore.batch();
    for (int i = 0; i < recurrenceMonths; i++) {
      batch.set(
        collection.doc(),
        bill
            .copyWith(
              dueDate: _addMonths(bill.dueDate, i),
              recurrenceId: recurrenceId,
            )
            .toMap(),
      );
    }
    await batch.commit();
  }

  Future<void> setPaid(String userId, String billId, {required bool paid}) {
    return _collection(userId).doc(billId).update(<String, dynamic>{
      'paidAt': paid ? DateTime.now().millisecondsSinceEpoch : null,
    });
  }

  Future<void> delete(String userId, String billId) {
    return _collection(userId).doc(billId).delete();
  }

  static DateTime _addMonths(DateTime date, int months) {
    final int lastDay = DateTime(date.year, date.month + months + 1, 0).day;
    return DateTime(
      date.year,
      date.month + months,
      date.day > lastDay ? lastDay : date.day,
    );
  }
}
