import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/invoice.dart';
import '../config/app_config.dart';
import 'currency_service.dart';

/// Cache entry for converted currency values
class CurrencyConversionCache {
  final double amount;
  final String fromCurrency;
  final String toCurrency;
  final double convertedValue;
  final DateTime timestamp;

  CurrencyConversionCache({
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
    required this.convertedValue,
    required this.timestamp,
  });

  String get key => '${amount}_${fromCurrency}_$toCurrency';
  
  bool get isExpired => 
    DateTime.now().difference(timestamp) > AppConfig.currencyRefreshInterval;
}

/// Optimized currency conversion service with caching
class CurrencyCacheService {
  final CurrencyService _currencyService;
  final Map<String, CurrencyConversionCache> _cache = {};
  Timer? _cleanupTimer;

  CurrencyCacheService(this._currencyService) {
    _startCleanupTimer();
  }

  void dispose() {
    _cleanupTimer?.cancel();
  }

  /// Start periodic cache cleanup
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _cleanupExpiredEntries();
    });
  }

  /// Remove expired cache entries
  void _cleanupExpiredEntries() {
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      developer.log(
        'CurrencyCacheService: Cleaned up ${expiredKeys.length} expired entries',
        name: 'InvoiceApp',
      );
    }
  }

  /// Get cached conversion or compute new one
  Future<double> convertAmount(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    // Return amount if same currency
    if (fromCurrency == toCurrency) return amount;

    final key = '${amount}_${fromCurrency}_$toCurrency';
    
    // Check cache first
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) {
      developer.log(
        'CurrencyCacheService: Cache hit for $key',
        name: 'InvoiceApp',
      );
      return cached.convertedValue;
    }

    // Convert and cache
    try {
      final convertedValue = await _currencyService.convertAmountValue(
        amount,
        fromCurrency,
      );

      _cache[key] = CurrencyConversionCache(
        amount: amount,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        convertedValue: convertedValue,
        timestamp: DateTime.now(),
      );

      developer.log(
        'CurrencyCacheService: Cached new conversion $key = $convertedValue',
        name: 'InvoiceApp',
      );

      return convertedValue;
    } catch (error) {
      developer.log(
        'CurrencyCacheService: Conversion failed for $key: $error',
        name: 'InvoiceApp',
        error: error,
      );
      return amount; // Fallback to original amount
    }
  }

  /// Batch convert multiple invoices efficiently
  Future<Map<String, double>> batchConvertInvoices(
    List<Invoice> invoices,
    String toCurrency,
  ) async {
    final Map<String, double> results = {};
    final List<Future<void>> conversions = [];

    for (final invoice in invoices) {
      final future = convertAmount(
        invoice.totalAmount,
        invoice.currencyCode ?? AppConfig.defaultCurrency,
        toCurrency,
      ).then((value) {
        results[invoice.id] = value;
      });
      conversions.add(future);
    }

    await Future.wait(conversions);
    return results;
  }

  /// Get aggregated sums for invoice statuses with caching
  Future<Map<InvoiceStatus, double>> getStatusSums(
    List<Invoice> invoices,
    String displayCurrency,
  ) async {
    final Map<InvoiceStatus, double> sums = {};
    
    // Group invoices by status
    final groupedInvoices = <InvoiceStatus, List<Invoice>>{};
    for (final invoice in invoices) {
      groupedInvoices.putIfAbsent(invoice.status, () => []).add(invoice);
    }

    // Convert each group in parallel
    final futures = groupedInvoices.entries.map((entry) async {
      final status = entry.key;
      final statusInvoices = entry.value;
      
      double sum = 0;
      for (final invoice in statusInvoices) {
        sum += await convertAmount(
          invoice.totalAmount,
          invoice.currencyCode ?? AppConfig.defaultCurrency,
          displayCurrency,
        );
      }
      
      sums[status] = sum;
    });

    await Future.wait(futures);
    return sums;
  }

  /// Clear all cached conversions
  void clearCache() {
    _cache.clear();
    developer.log(
      'CurrencyCacheService: Cache cleared',
      name: 'InvoiceApp',
    );
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final expired = _cache.values.where((entry) => entry.isExpired).length;
    final valid = _cache.length - expired;

    return {
      'total_entries': _cache.length,
      'valid_entries': valid,
      'expired_entries': expired,
      'cache_hit_potential': valid / (_cache.length + 1), // Avoid division by zero
    };
  }
}

/// Provider for currency cache service
final currencyCacheServiceProvider = Provider<CurrencyCacheService>((ref) {
  final currencyService = ref.watch(currencyServiceProvider);
  final service = CurrencyCacheService(currencyService);
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
