import 'package:hive/hive.dart';

part 'fx_rates.g.dart';

// Rates are stored as: currencyCode -> rateToBase
// Example with base USD: { 'EUR': 1.09 } meaning 1 EUR = 1.09 USD
@HiveType(typeId: 20)
class FxRates extends HiveObject {
  @HiveField(0)
  String baseCurrency;

  @HiveField(1)
  Map<String, double> rates; // uppercased currency codes

  /// Timestamp when the rates were fetched. Useful for freshness checks.
  @HiveField(2)
  DateTime fetchedAt;

  FxRates({required this.baseCurrency, Map<String, double>? rates, DateTime? fetchedAt})
      : rates = rates ?? {},
        fetchedAt = fetchedAt ?? DateTime.now();
}


