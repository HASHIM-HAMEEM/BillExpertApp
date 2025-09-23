import 'dart:convert';
import 'dart:developer' as developer;
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/fx_rates.dart';

abstract class FxRatesRepository {
  Future<FxRates?> getFxRates();
  Future<void> saveFxRates(FxRates rates);
  Future<FxRates?> fetchLatestRates(String baseCurrency);
}

class HiveFxRatesRepository implements FxRatesRepository {
  static const String _boxName = 'fx_rates';
  static const String _key = 'rates';

  Future<Box> _getBox() => Hive.openBox(_boxName);

  @override
  Future<FxRates?> getFxRates() async {
    final box = await _getBox();
    return box.get(_key) as FxRates?;
  }

  @override
  Future<void> saveFxRates(FxRates rates) async {
    final box = await _getBox();
    await box.put(_key, rates);
  }

  @override
  Future<FxRates?> fetchLatestRates(String baseCurrency) async {
    try {
      // Check internet connectivity first
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        developer.log('FxRatesRepository: No internet connection available for baseCurrency: $baseCurrency');
        return null; // No internet connection
      }

      // Use exchangerate-api.com as primary API (free and reliable)
      return await _fetchFromPrimaryAPI(baseCurrency);

    } catch (e) {
      developer.log('FxRatesRepository: Primary API failed for baseCurrency: $baseCurrency, error: $e');
      developer.log('FxRatesRepository: No fallback API available, returning null');
      return null;
    }
  }

  // Primary API method
  Future<FxRates?> _fetchFromPrimaryAPI(String baseCurrency) async {
    try {
      developer.log('FxRatesRepository: Making API request to exchangerate-api.com for baseCurrency: $baseCurrency');

      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/$baseCurrency'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'InvoiceApp/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      developer.log('FxRatesRepository: API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        developer.log('FxRatesRepository: Parsing JSON response');
        final data = json.decode(response.body);

        if (data.containsKey('rates') && data['rates'] is Map) {
          final rates = Map<String, double>.from(data['rates']);
          developer.log('FxRatesRepository: Successfully parsed ${rates.length} exchange rates');

          return FxRates(
            baseCurrency: baseCurrency.toUpperCase(),
            rates: rates,
          );
        } else {
          developer.log('FxRatesRepository: Invalid response format - missing or invalid rates field');
        }
      } else {
        developer.log('FxRatesRepository: API returned error status: ${response.statusCode}, body: ${response.body}');
      }
    } catch (e, stackTrace) {
      developer.log('FxRatesRepository: Exception during API call: $e');
      developer.log('FxRatesRepository: Stack trace: $stackTrace');
    }
    return null;
  }

}

final fxRatesRepositoryProvider = Provider<FxRatesRepository>((ref) {
  return HiveFxRatesRepository();
});
