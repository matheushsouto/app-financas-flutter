/// Categorias de conta a pagar disponíveis no formulário (wireframe 7).
enum BillCategory {
  housing('Moradia'),
  services('Serviços'),
  education('Educação'),
  card('Cartão'),
  other('Outros');

  const BillCategory(this.label);

  final String label;

  static BillCategory fromName(String? name) {
    return BillCategory.values.firstWhere(
      (BillCategory c) => c.name == name,
      orElse: () => BillCategory.other,
    );
  }
}

/// Situação de uma conta, calculada a partir de pagamento e vencimento.
enum BillStatus { paid, overdue, dueTomorrow, pending }

/// Conta a pagar.
class Bill {
  const Bill({
    required this.id,
    required this.amount,
    required this.description,
    required this.dueDate,
    required this.category,
    this.paidAt,
    this.recurrenceId,
  });

  final String id;
  final double amount;
  final String description;
  final DateTime dueDate;
  final BillCategory category;

  /// Data do pagamento; `null` enquanto a conta estiver em aberto.
  final DateTime? paidAt;

  /// Liga as contas geradas por "Repetir todo mês".
  final String? recurrenceId;

  bool get isPaid => paidAt != null;

  BillStatus statusOn(DateTime today) {
    if (isPaid) return BillStatus.paid;

    final DateTime day = DateTime(today.year, today.month, today.day);
    if (dueDate.isBefore(day)) return BillStatus.overdue;
    if (dueDate == DateTime(day.year, day.month, day.day + 1)) {
      return BillStatus.dueTomorrow;
    }
    return BillStatus.pending;
  }

  factory Bill.fromMap(String id, Map<String, dynamic> map) {
    final int? paidAt = map['paidAt'] as int?;
    return Bill(
      id: id,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String? ?? '',
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
      category: BillCategory.fromName(map['category'] as String?),
      paidAt: paidAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(paidAt),
      recurrenceId: map['recurrenceId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'amount': amount,
      'description': description,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'category': category.name,
      'paidAt': paidAt?.millisecondsSinceEpoch,
      'recurrenceId': recurrenceId,
    };
  }

  Bill copyWith({
    String? id,
    double? amount,
    String? description,
    DateTime? dueDate,
    BillCategory? category,
    String? recurrenceId,
  }) {
    return Bill(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      paidAt: paidAt,
      recurrenceId: recurrenceId ?? this.recurrenceId,
    );
  }
}
