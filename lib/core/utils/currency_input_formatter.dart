import 'package:flutter/services.dart';

import 'formatters.dart';

/// Máscara de moeda: o usuário digita só números e o valor "cresce" da
/// direita para a esquerda (`1` → `0,01`, `150` → `1,50`, `123456` → `1.234,56`).
class CurrencyInputFormatter extends TextInputFormatter {
  /// Texto mascarado (`1.234,56`) → `1234.56`.
  static double parse(String text) {
    final String digits = text.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? 0 : int.parse(digits) / 100;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();

    final String text = Formatters.decimal(int.parse(digits) / 100);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
