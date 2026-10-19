import 'package:flutter/material.dart';

import '../../models/bill.dart';

/// Ícone de cada categoria de conta, como no wireframe 4.
IconData billCategoryIcon(BillCategory category) {
  return switch (category) {
    BillCategory.housing => Icons.home_outlined,
    BillCategory.services => Icons.bolt_rounded,
    BillCategory.education => Icons.description_outlined,
    BillCategory.card => Icons.credit_card_rounded,
    BillCategory.other => Icons.category_outlined,
  };
}
