/// Categorias de receita disponíveis no formulário (wireframe 6).
enum IncomeCategory {
  work('Trabalho'),
  extra('Extra'),
  sale('Venda'),
  other('Outros');

  const IncomeCategory(this.label);

  final String label;

  static IncomeCategory fromName(String? name) {
    return IncomeCategory.values.firstWhere(
      (IncomeCategory c) => c.name == name,
      orElse: () => IncomeCategory.other,
    );
  }
}

/// Receita (lançamento de dinheiro recebido).
class Income {
  const Income({
    required this.id,
    required this.amount,
    required this.description,
    required this.receivedAt,
    required this.category,
  });

  final String id;
  final double amount;
  final String description;
  final DateTime receivedAt;
  final IncomeCategory category;

  factory Income.fromMap(String id, Map<String, dynamic> map) {
    return Income(
      id: id,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String? ?? '',
      receivedAt: DateTime.fromMillisecondsSinceEpoch(map['receivedAt'] as int),
      category: IncomeCategory.fromName(map['category'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'amount': amount,
      'description': description,
      'receivedAt': receivedAt.millisecondsSinceEpoch,
      'category': category.name,
    };
  }

  Income copyWith({
    String? id,
    double? amount,
    String? description,
    DateTime? receivedAt,
    IncomeCategory? category,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      receivedAt: receivedAt ?? this.receivedAt,
      category: category ?? this.category,
    );
  }
}
