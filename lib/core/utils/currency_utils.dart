import 'package:intl/intl.dart';

class CurrencyUtils {
  static String extractSymbol(String currencyString) {
    // Example format: 'USD ($)', 'LKR (Rs)', 'EUR (€)'
    final match = RegExp(r'\((.*?)\)').firstMatch(currencyString);
    return match?.group(1) ?? '\$'; // Fallback to $ if no parentheses found
  }

  static String formatAmount(double amount, String currencyString, {bool isCompact = false, int decimalDigits = 2}) {
    final symbol = extractSymbol(currencyString);
    final formatter = isCompact 
        ? NumberFormat.compactCurrency(symbol: symbol, decimalDigits: decimalDigits)
        : NumberFormat.currency(symbol: symbol, decimalDigits: decimalDigits);
    
    return formatter.format(amount);
  }
}
