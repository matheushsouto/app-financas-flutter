import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/income.dart';

/// CRUD de receitas em `users/{userId}/incomes`.
class IncomeService {
  IncomeService({FirebaseFirestore? firestore})
    : _injectedFirestore = firestore;

  final FirebaseFirestore? _injectedFirestore;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('incomes');

  /// Receitas do mês de [month], da mais recente para a mais antiga,
  /// atualizadas em tempo real.
  Stream<List<Income>> watchByMonth(String userId, DateTime month) {
    final DateTime start = DateTime(month.year, month.month);
    final DateTime end = DateTime(month.year, month.month + 1);

    return _collection(userId)
        .where(
          'receivedAt',
          isGreaterThanOrEqualTo: start.millisecondsSinceEpoch,
        )
        .where('receivedAt', isLessThan: end.millisecondsSinceEpoch)
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map((doc) => Income.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> create(String userId, Income income) {
    return _collection(userId).add(income.toMap());
  }

  Future<void> delete(String userId, String incomeId) {
    return _collection(userId).doc(incomeId).delete();
  }
}
