import 'dart:convert';
import 'dart:developer' as developer;
import '../utils/app_logger.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/fx_rates.dart';
import '../config/app_config.dart';

abstract class FxRatesRepository {
  Future<FxRates?> getFxRates();
  Future<void> saveFxRates(FxRates rates);
  Future<FxRates?> fetchLatestRates(String baseCurrency);
  Map<String, dynamic> getLastDiagnostics();
}

class HiveFxRatesRepository implements FxRatesRepository {
  static const String _boxName = 'fx_rates';
  static const String _key = 'rates';

  Future<Box<FxRates>> _getBox() => Hive.openBox<FxRates>(_boxName);

  Iterable<ConnectivityResult> _normalizeConnectivityResult(dynamic result) {
    if (result is Iterable<ConnectivityResult>) {
      return result;
    }
    if (result is ConnectivityResult) {
      return [result];
    }
    return const [];
  }

  final Map<String, dynamic> _lastDiagnostics = {};
  void _mergeDiag(Map<String, dynamic> data) {
    _lastDiagnostics.addAll(data);
  }

  @override
  Map<String, dynamic> getLastDiagnostics() {
    return Map<String, dynamic>.from(_lastDiagnostics);
  }

  @override
  Future<FxRates?> getFxRates() async {
    final box = await _getBox();
    return box.get(_key);
  }

  @override
  Future<void> saveFxRates(FxRates rates) async {
    try {
      final box = await _getBox();
      await box.put(_key, rates);
      _mergeDiag({'saved': true});
    } catch (e) {
      _mergeDiag({'saved': false, 'saveException': e.toString()});
      rethrow;
    }
  }

  @override
  Future<FxRates?> fetchLatestRates(String baseCurrency) async {
    try {
      // Check internet connectivity first
      final connectivityResults = await Connectivity().checkConnectivity();
      final normalizedResults = _normalizeConnectivityResult(
        connectivityResults,
      );
      final hasConnection = normalizedResults.any(
        (result) => result != ConnectivityResult.none,
      );

      developer.log(
        'FxRatesRepository: Connectivity results $normalizedResults, hasConnection=$hasConnection',
      );
      _mergeDiag({
        'connectivity': normalizedResults.toString(),
        'hasConnection': hasConnection,
        'baseCurrency': baseCurrency,
        'stage': 'connectivity-checked',
      });

      if (!hasConnection) {
        developer.log(
          'FxRatesRepository: No internet connection available for baseCurrency: $baseCurrency',
        );
        _mergeDiag({'result': 'failure', 'reason': 'no-internet'});
        return null; // No internet connection
      }

      // Try primary API first
      final primaryResult = await _fetchFromPrimaryAPI(baseCurrency);
      if (primaryResult != null) {
        _mergeDiag({'result': 'primary-success'});
        return primaryResult;
      }

      developer.log(
        'FxRatesRepository: Primary API failed, attempting fallback',
      );
      _mergeDiag({'stage': 'primary-failed'});

      // Fallback API attempt
      final fallbackResult = await _fetchFromFallbackAPI(baseCurrency);
      if (fallbackResult != null) {
        _mergeDiag({'result': 'fallback-success'});
        return fallbackResult;
      }

      developer.log(
        'FxRatesRepository: Both primary and fallback API calls failed',
      );
      _mergeDiag({'result': 'failure', 'reason': 'both-failed'});
      return null;
    } catch (e, stackTrace) {
      developer.log(
        'FxRatesRepository: Unexpected error for baseCurrency: $baseCurrency, error: $e',
      );
      developer.log('FxRatesRepository: Stack trace: $stackTrace');
      _mergeDiag({
        'result': 'failure',
        'reason': 'exception',
        'error': e.toString(),
      });
      return null;
    }
  }

  Map<String, double> _coerceRatesToDouble(dynamic rawRates) {
    final Map<String, double> result = {};
    if (rawRates is Map) {
      rawRates.forEach((key, value) {
        if (key is String) {
          if (value is num) {
            result[key] = value.toDouble();
          } else if (value is String) {
            final parsed = double.tryParse(value);
            if (parsed != null) {
              result[key] = parsed;
            }
          }
        }
      });
    }
    return result;
  }

  // Primary API method
  Future<FxRates?> _fetchFromPrimaryAPI(String baseCurrency) async {
    try {
      developer.log(
        'FxRatesRepository: Making API request to exchangerate-api.com for baseCurrency: $baseCurrency',
      );

      final url = '${AppConfig.exchangeRateApiUrl}$baseCurrency';
      _mergeDiag({'primaryUrl': url});
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'InvoiceApp/1.0',
            },
          )
          .timeout(AppConfig.apiTimeout);

      developer.log(
        'FxRatesRepository: API response status: ${response.statusCode}',
      );
      final primaryPreview = response.body.length > 200
          ? response.body.substring(0, 200)
          : response.body;
      _mergeDiag({
        'primaryStatus': response.statusCode,
        'primaryBodyPreview': primaryPreview,
      });

      if (response.statusCode == 200) {
        developer.log('FxRatesRepository: Parsing JSON response');
        final data = json.decode(response.body);

        if (data.containsKey('rates') && data['rates'] is Map) {
          final rates = _coerceRatesToDouble(data['rates']);
          developer.log(
            'FxRatesRepository: Successfully parsed ${rates.length} exchange rates',
          );
          _mergeDiag({'primaryRateCount': rates.length});

          return FxRates(
            baseCurrency: baseCurrency.toUpperCase(),
            rates: rates,
            fetchedAt: DateTime.now(),
          );
        } else {
          developer.log(
            'FxRatesRepository: Invalid response format - missing or invalid rates field',
          );
          _mergeDiag({'primaryParse': 'missing-rates'});
        }
      } else {
        developer.log(
          'FxRatesRepository: API returned error status: ${response.statusCode}, body: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      developer.log('FxRatesRepository: Exception during API call: $e');
      developer.log('FxRatesRepository: Stack trace: $stackTrace');
      _mergeDiag({'primaryException': e.toString()});
    }
    return null;
  }

  Future<FxRates?> _fetchFromFallbackAPI(String baseCurrency) async {
    try {
      developer.log(
        'FxRatesRepository: Making API request to fallback exchangerate.host for baseCurrency: $baseCurrency',
      );
      final url =
          '${AppConfig.fallbackExchangeRateApiUrl}${baseCurrency.toUpperCase()}';
      _mergeDiag({'fallbackUrl': url});
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'InvoiceApp/1.0',
            },
          )
          .timeout(AppConfig.apiTimeout);

      developer.log(
        'FxRatesRepository: Fallback API response status: ${response.statusCode}',
      );
      final fallbackPreview = response.body.length > 200
          ? response.body.substring(0, 200)
          : response.body;
      _mergeDiag({
        'fallbackStatus': response.statusCode,
        'fallbackBodyPreview': fallbackPreview,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log(
          'FxRatesRepository: Fallback decoded keys: ${data.keys.join(', ')}',
        );
        if (data.containsKey('rates') && data['rates'] is Map) {
          final rates = _coerceRatesToDouble(data['rates']);
          developer.log(
            'FxRatesRepository: Fallback API provided ${rates.length} rates',
          );
          _mergeDiag({'fallbackRateCount': rates.length});
          return FxRates(
            baseCurrency: baseCurrency.toUpperCase(),
            rates: rates,
            fetchedAt: DateTime.now(),
          );
        } else {
          developer.log(
            'FxRatesRepository: Fallback API response missing rates',
          );
          _mergeDiag({'fallbackParse': 'missing-rates'});
        }
      } else {
        developer.log(
          'FxRatesRepository: Fallback API returned status ${response.statusCode}, body: ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      developer.log('FxRatesRepository: Fallback API error: $e');
      developer.log('FxRatesRepository: Fallback stack trace: $stackTrace');
      _mergeDiag({'fallbackException': e.toString()});
    }
    return null;
  }
}

final fxRatesRepositoryProvider = Provider<FxRatesRepository>((ref) {
  return HiveFxRatesRepository();
});
