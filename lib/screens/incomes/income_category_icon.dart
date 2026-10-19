import 'package:flutter/material.dart';

import '../../models/income.dart';

/// Ícone de cada categoria de receita, como no wireframe 3.
IconData incomeCategoryIcon(IncomeCategory category) {
  return switch (category) {
    IncomeCategory.work => Icons.work_outline_rounded,
    IncomeCategory.extra => Icons.laptop_mac_rounded,
    IncomeCategory.sale => Icons.sell_outlined,
    IncomeCategory.other => Icons.category_outlined,
  };
}
