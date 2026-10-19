import 'package:intl/intl.dart';

/// Formatação de valores e datas no padrão brasileiro.
///
/// O app inteiro exibe dinheiro como `R$ 1.234,56` e datas como `15/09`.
/// Concentrar isso aqui garante que nenhuma tela invente um formato próprio.
abstract final class Formatters {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
    decimalDigits: 2,
  );

  static final NumberFormat _decimal = NumberFormat.decimalPatternDigits(
    locale: 'pt_BR',
    decimalDigits: 2,
  );

  static final DateFormat _dayMonth = DateFormat('dd/MM', 'pt_BR');
  static final DateFormat _fullDate = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final DateFormat _monthYear = DateFormat("MMMM 'de' yyyy", 'pt_BR');

  /// `1234.5` → `R$ 1.234,50`
  static String currency(num value) => _currency.format(value);

  /// `1234.5` → `1.234,50` (sem o símbolo da moeda)
  static String decimal(num value) => _decimal.format(value);

  /// `DateTime(2026, 9, 15)` → `15/09`
  static String dayMonth(DateTime date) => _dayMonth.format(date);

  /// `DateTime(2026, 9, 15)` → `15/09/2026`
  static String fullDate(DateTime date) => _fullDate.format(date);

  /// `DateTime(2026, 9, 15)` → `Setembro de 2026`
  static String monthYear(DateTime date) {
    final String formatted = _monthYear.format(date);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }
}
