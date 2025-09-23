import '../models/currency.dart';

/// Centralized currency formatting utility
class CurrencyFormatter {
  /// Format amount with currency symbol and proper decimal places
  static String formatCurrency(double amount, String currencyCode) {
    final currency = Currency.findByCode(currencyCode);
    final symbol = currency?.symbol ?? currencyCode;

    // Format with 2 decimal places
    final formattedAmount = amount.toStringAsFixed(2);

    // Handle currency symbol positioning based on currency conventions
    return _formatWithSymbol(formattedAmount, symbol, currencyCode);
  }

  /// Format amount without currency symbol (for calculations or internal use)
  static String formatAmount(double amount) {
    return amount.toStringAsFixed(2);
  }

  /// Get currency symbol for a currency code
  static String getCurrencySymbol(String currencyCode) {
    final currency = Currency.findByCode(currencyCode);
    return currency?.symbol ?? currencyCode;
  }

  /// Get currency name for a currency code
  static String getCurrencyName(String currencyCode) {
    final currency = Currency.findByCode(currencyCode);
    return currency?.name ?? currencyCode;
  }

  /// Get currency flag emoji for a currency code
  static String getCurrencyFlag(String currencyCode) {
    final currency = Currency.findByCode(currencyCode);
    return currency?.flag ?? '🏳️';
  }

  /// Format with proper symbol positioning
  static String _formatWithSymbol(String amount, String symbol, String currencyCode) {
    // Currencies where symbol comes after amount (e.g., "100 €")
    const symbolAfterCurrencies = {'EUR', 'SEK', 'NOK', 'DKK', 'ISK', 'CZK', 'PLN'};

    if (symbolAfterCurrencies.contains(currencyCode.toUpperCase())) {
      return '$amount $symbol';
    }

    // Default: symbol before amount (e.g., "$100", "£100")
    return '$symbol$amount';
  }

  /// Format amount for display with thousands separators (for large amounts)
  static String formatLargeAmount(double amount, String currencyCode) {
    final currency = Currency.findByCode(currencyCode);
    final symbol = currency?.symbol ?? currencyCode;

    // Use NumberFormat for proper localization
    final formatter = _getNumberFormat(currencyCode);

    return '$symbol${formatter.format(amount)}';
  }

  /// Get NumberFormat based on currency conventions
  static dynamic _getNumberFormat(String currencyCode) {
    // For simplicity, return a basic formatter
    // In a real app, you might want to use intl package for proper localization
    return _BasicNumberFormatter();
  }
}

/// Basic number formatter (can be replaced with intl package)
class _BasicNumberFormatter {
  String format(double number) {
    // Simple thousands separator
    final parts = number.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Add thousands separator
    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
    }

    return '${buffer.toString()}.$decimalPart';
  }
}

/// Extension methods for easier usage
extension CurrencyFormatting on double {
  /// Format as currency
  String formatAsCurrency(String currencyCode) {
    return CurrencyFormatter.formatCurrency(this, currencyCode);
  }

  /// Format as large amount
  String formatAsLargeAmount(String currencyCode) {
    return CurrencyFormatter.formatLargeAmount(this, currencyCode);
  }
}

/// Extension for strings to extract currency info
extension CurrencyInfo on String {
  String getCurrencySymbol() => CurrencyFormatter.getCurrencySymbol(this);
  String getCurrencyName() => CurrencyFormatter.getCurrencyName(this);
  String getCurrencyFlag() => CurrencyFormatter.getCurrencyFlag(this);
}
