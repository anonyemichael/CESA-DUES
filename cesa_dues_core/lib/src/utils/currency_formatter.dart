import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Currency formatting utilities for GHS (Ghanaian Cedi).
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _formatter = NumberFormat.currency(
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  static final _compactFormatter = NumberFormat.compact();

  /// Format pesewas amount to display string.
  /// Example: 5000 → "GH₵50.00"
  static String format(int pesewas) {
    return _formatter.format(pesewas / 100);
  }

  /// Format pesewas amount as compact string.
  /// Example: 1710000 → "GH₵17.1K"
  static String formatCompact(int pesewas) {
    return '${AppConstants.currencySymbol}${_compactFormatter.format(pesewas / 100)}';
  }

  /// Format cedis amount to display string.
  /// Example: 50.0 → "GH₵50.00"
  static String formatCedis(double cedis) {
    return _formatter.format(cedis);
  }

  static String formatGhs(double cedis) {
    return 'GHS ${cedis.toStringAsFixed(2)}';
  }

  /// Parse a cedis input string to pesewas.
  /// Example: "50" → 5000, "50.50" → 5050
  static int? parseToPesewas(String input) {
    final value = double.tryParse(input.replaceAll(',', ''));
    if (value == null || value < 0) return null;
    return (value * 100).round();
  }
}
