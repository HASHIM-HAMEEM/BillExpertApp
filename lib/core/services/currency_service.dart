import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/currency.dart';
import '../models/fx_rates.dart';
import '../models/invoice.dart';
import '../utils/currency_formatter.dart';
import 'fx_rates_repository.dart';
import 'merchant_repository.dart';

class CurrencyService {
  final FxRatesRepository _fxRepository;
  final MerchantRepository _merchantRepository;

  CurrencyService(this._fxRepository, this._merchantRepository);

  // Initialize currency system (call this when app starts)
  Future<void> initialize() async {
    try {
      developer.log('CurrencyService: Initializing currency system');

      // Check if we have cached rates
      final cachedRates = await _fxRepository.getFxRates();

      if (cachedRates == null) {
        developer.log('CurrencyService: No cached rates found, using default rates');

        // Use default rates immediately for basic functionality
        final defaultRates = _getDefaultRates('USD');
        await _fxRepository.saveFxRates(defaultRates);
        developer.log('CurrencyService: Initialized with default rates');

        // Try to fetch fresh rates in background (don't block app startup)
        try {
          final freshRates = await _fxRepository.fetchLatestRates('USD').timeout(
            const Duration(seconds: 10),
            onTimeout: () => null,
          );

          if (freshRates != null) {
            await _fxRepository.saveFxRates(freshRates);
            developer.log('CurrencyService: Successfully updated with fresh rates');
          } else {
            developer.log('CurrencyService: Failed to fetch fresh rates, keeping default rates');
          }
        } catch (e) {
          developer.log('CurrencyService: Error during background rate fetch: $e');
        }
      } else {
        developer.log('CurrencyService: Using cached rates from ${cachedRates.baseCurrency}');
      }
    } catch (e) {
      developer.log('CurrencyService: Initialization error: $e');
      // Don't rethrow - initialization failure shouldn't crash the app
    }
  }

  // Get the user's preferred display currency
  Future<Currency?> getDisplayCurrency() async {
    final profile = await _merchantRepository.getProfile();
    if (profile != null && profile.displayCurrencyCode != null && profile.displayCurrencyCode!.isNotEmpty) {
      final currency = Currency.findByCode(profile.displayCurrencyCode!);
      if (currency != null) {
        return currency;
      }
    }
    return Currency.defaultCurrency;
  }

  // Convert amount to user's display currency
  Future<String> convertAmount(double amount, String fromCurrency) async {
    try {
      final displayCurrency = await getDisplayCurrency();
      developer.log('CurrencyService: Converting $amount $fromCurrency to ${displayCurrency?.code ?? 'unknown'}');

      if (displayCurrency == null || displayCurrency.code == fromCurrency) {
        developer.log('CurrencyService: No conversion needed, returning original amount');
        return _formatAmount(amount, fromCurrency);
      }

      // Always use USD as the base currency for consistency
      const baseCurrency = 'USD';

      // Get cached exchange rates (preferably with USD as base)
      final fxRates = await _fxRepository.getFxRates();
      developer.log('CurrencyService: Cached rates available: ${fxRates != null}, base: ${fxRates?.baseCurrency}');

      FxRates? ratesToUse = fxRates;

      // If we don't have cached rates or they're not in USD base, try to fetch fresh rates
      if (ratesToUse == null || ratesToUse.baseCurrency != baseCurrency) {
        developer.log('CurrencyService: Attempting to fetch fresh USD-based rates');

        // Try to fetch fresh rates, but don't block the UI if it fails
        try {
          final freshRates = await _fxRepository.fetchLatestRates(baseCurrency).timeout(
            const Duration(seconds: 5), // Shorter timeout for UI operations
            onTimeout: () => null,
          );

          if (freshRates != null) {
            await _fxRepository.saveFxRates(freshRates);
            ratesToUse = freshRates;
            developer.log('CurrencyService: Successfully fetched and saved fresh rates');
          } else {
            developer.log('CurrencyService: Failed to fetch fresh rates, using default rates');
            ratesToUse = _getDefaultRates(baseCurrency); // Use default rates as fallback
          }
        } catch (e) {
          developer.log('CurrencyService: Error fetching rates: $e, using default rates');
          ratesToUse = _getDefaultRates(baseCurrency); // Use default rates as fallback
        }
      }

      // ratesToUse is guaranteed to be non-null due to fallback logic above
      final result = _convertWithRates(amount, fromCurrency, displayCurrency.code, ratesToUse);
      developer.log('CurrencyService: Conversion result: $result');
      return result;
    } catch (e) {
      developer.log('CurrencyService: Unexpected error converting amount: $e');
      // On error, return original amount
      return _formatAmount(amount, fromCurrency);
    }
  }

  // Shared numeric conversion logic
  double _calculateConvertedAmount(double amount, String fromCurrency, String toCurrency, FxRates rates) {
    if (rates.baseCurrency == fromCurrency) {
      final rate = rates.rates[toCurrency] ?? 1.0;
      return amount * rate;
    } else if (rates.baseCurrency == toCurrency) {
      final rate = rates.rates[fromCurrency] ?? 1.0;
      return rate > 0 ? amount / rate : amount;
    } else {
      final fromRate = rates.rates[fromCurrency] ?? 1.0;
      final toRate = rates.rates[toCurrency] ?? 1.0;
      return fromRate > 0 ? (amount / fromRate) * toRate : amount;
    }
  }

  String _convertWithRates(double amount, String fromCurrency, String toCurrency, FxRates rates) {
    final converted = _calculateConvertedAmount(amount, fromCurrency, toCurrency, rates);
    return _formatAmount(converted, toCurrency);
  }

  String _formatAmount(double amount, String currencyCode) {
    return CurrencyFormatter.formatCurrency(amount, currencyCode);
  }

  // Convert and return numeric value in the user's display currency
  Future<double> convertAmountValue(double amount, String fromCurrency) async {
    try {
      final displayCurrency = await getDisplayCurrency();
      if (displayCurrency == null || displayCurrency.code == fromCurrency) {
        return amount;
      }

      const baseCurrency = 'USD';
      FxRates? ratesToUse = await _fxRepository.getFxRates();
      if (ratesToUse == null || ratesToUse.baseCurrency != baseCurrency) {
        try {
          final freshRates = await _fxRepository.fetchLatestRates(baseCurrency).timeout(
            const Duration(seconds: 5),
            onTimeout: () => null,
          );
          ratesToUse = freshRates ?? _getDefaultRates(baseCurrency);
        } catch (_) {
          ratesToUse = _getDefaultRates(baseCurrency);
        }
      }

      return _calculateConvertedAmount(amount, fromCurrency, displayCurrency.code, ratesToUse);
    } catch (_) {
      return amount; // fallback
    }
  }

  // Get default exchange rates when API is unavailable
  FxRates _getDefaultRates(String baseCurrency) {
    // Basic default rates (1 USD = X other currency)
    final defaultRates = {
      'USD': 1.0,    // Base currency
      'EUR': 0.85,   // Euro
      'GBP': 0.75,   // British Pound
      'JPY': 110.0,  // Japanese Yen
      'CAD': 1.25,   // Canadian Dollar
      'AUD': 1.35,   // Australian Dollar
      'CHF': 0.92,   // Swiss Franc
      'CNY': 6.45,   // Chinese Yuan
      'INR': 74.0,   // Indian Rupee
      'BRL': 5.2,    // Brazilian Real
      'MXN': 18.5,   // Mexican Peso
      'KRW': 1180.0, // Korean Won
      'SGD': 1.35,   // Singapore Dollar
      'NZD': 1.4,    // New Zealand Dollar
      'ZAR': 14.8,   // South African Rand
      'TRY': 13.5,   // Turkish Lira
      'RUB': 75.0,   // Russian Ruble
      'SEK': 8.8,    // Swedish Krona
      'NOK': 8.6,    // Norwegian Krone
      'DKK': 6.3,    // Danish Krone
      'PLN': 3.9,    // Polish Zloty
      'THB': 32.0,   // Thai Baht
      'IDR': 14400.0, // Indonesian Rupiah
      'MYR': 4.2,    // Malaysian Ringgit
      'PHP': 51.0,   // Philippine Peso
      'VND': 23000.0, // Vietnamese Dong
      'ARS': 100.0,  // Argentine Peso
      'COP': 3800.0, // Colombian Peso
      'CLP': 800.0,  // Chilean Peso
      'PEN': 3.8,    // Peruvian Sol
      'EGP': 15.7,   // Egyptian Pound
      'NGN': 410.0,  // Nigerian Naira
      'KES': 113.0,  // Kenyan Shilling
      'GHS': 6.0,    // Ghanaian Cedi
      'TZS': 2300.0, // Tanzanian Shilling
      'UGX': 3500.0, // Ugandan Shilling
      'MAD': 9.5,    // Moroccan Dirham
      'DZD': 135.0,  // Algerian Dinar
      'TND': 2.8,    // Tunisian Dinar
      'LBP': 1500.0, // Lebanese Pound
      'JOD': 0.71,   // Jordanian Dinar
      'SAR': 3.75,   // Saudi Riyal
      'AED': 3.67,   // UAE Dirham
      'QAR': 3.64,   // Qatari Riyal
      'BHD': 0.38,   // Bahraini Dinar
      'OMR': 0.39,   // Omani Rial
      'KWD': 0.31,   // Kuwaiti Dinar
      'PKR': 160.0,  // Pakistani Rupee
      'BDT': 85.0,   // Bangladeshi Taka
      'LKR': 200.0,  // Sri Lankan Rupee
      'NPR': 118.0,  // Nepalese Rupee
      'MVR': 15.4,   // Maldivian Rufiyaa
    };

    return FxRates(
      baseCurrency: baseCurrency,
      rates: defaultRates,
    );
  }

  // Check if device has internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      return !connectivityResults.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  // Refresh exchange rates manually
  Future<bool> refreshExchangeRates() async {
    try {
      developer.log('CurrencyService: Starting manual refresh of exchange rates');

      final hasInternet = await hasInternetConnection();
      developer.log('CurrencyService: Internet connection check result: $hasInternet');

      if (!hasInternet) {
        developer.log('CurrencyService: No internet connection available');
        return false;
      }

      // Always fetch USD-based rates for consistency
      const baseCurrency = 'USD';
      developer.log('CurrencyService: Fetching rates with base: $baseCurrency');

      final rates = await _fxRepository.fetchLatestRates(baseCurrency);
      developer.log('CurrencyService: fetchLatestRates returned: ${rates != null ? 'success' : 'null'}');

      if (rates != null) {
        await _fxRepository.saveFxRates(rates);
        developer.log('CurrencyService: Successfully refreshed rates. Base: ${rates.baseCurrency}, ${rates.rates.length} currencies');
        return true;
      } else {
        developer.log('CurrencyService: Failed to fetch rates - rates object is null');
        return false;
      }
    } catch (e, stackTrace) {
      developer.log('CurrencyService: Error refreshing rates: $e');
      developer.log('CurrencyService: Stack trace: $stackTrace');
      return false;
    }
  }

  // Get last updated timestamp (for UI display)
  Future<DateTime?> getLastUpdated() async {
    try {
      final rates = await _fxRepository.getFxRates();
      if (rates != null) {
        // We don't store timestamp in FxRates, so return current time as approximation
        // In a real app, you'd want to add a timestamp field to FxRates model
        return DateTime.now();
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }

  // Batch convert multiple amounts (for dashboard totals, etc.)
  Future<List<double>> convertAmountsBatch(List<double> amounts, String fromCurrency) async {
    if (amounts.isEmpty) return [];

    try {
      final displayCurrency = await getDisplayCurrency();
      if (displayCurrency == null || displayCurrency.code == fromCurrency) {
        return amounts; // No conversion needed
      }

      const baseCurrency = 'USD';
      FxRates? ratesToUse = await _fxRepository.getFxRates();

      if (ratesToUse == null || ratesToUse.baseCurrency != baseCurrency) {
        try {
          final freshRates = await _fxRepository.fetchLatestRates(baseCurrency).timeout(
            const Duration(seconds: 3),
            onTimeout: () => null,
          );
          ratesToUse = freshRates ?? _getDefaultRates(baseCurrency);
        } catch (_) {
          ratesToUse = _getDefaultRates(baseCurrency);
        }
      }

      return amounts.map((amount) =>
        _calculateConvertedAmount(amount, fromCurrency, displayCurrency.code, ratesToUse!)
      ).toList();

    } catch (_) {
      return amounts; // Return original amounts on error
    }
  }

  // Convert invoice totals for dashboard display
  Future<List<Map<String, dynamic>>> convertInvoiceTotals(List<Invoice> invoices) async {
    if (invoices.isEmpty) return [];

    try {
      final displayCurrency = await getDisplayCurrency();
      if (displayCurrency == null) return [];

      final convertedData = <Map<String, dynamic>>[];

      for (final invoice in invoices) {
        final sourceCurrency = invoice.currencyCode ?? 'USD';
        final convertedAmount = await convertAmountValue(invoice.totalAmount, sourceCurrency);

        convertedData.add({
          'invoice': invoice,
          'convertedTotal': convertedAmount,
          'displayCurrency': displayCurrency.code,
          'originalCurrency': sourceCurrency,
        });
      }

      return convertedData;

    } catch (_) {
      // Return invoices with original amounts if conversion fails
      return invoices.map((invoice) => {
        'invoice': invoice,
        'convertedTotal': invoice.totalAmount,
        'displayCurrency': invoice.currencyCode ?? 'USD',
        'originalCurrency': invoice.currencyCode ?? 'USD',
      }).toList();
    }
  }

  // Set user's display currency preference
  Future<bool> setDisplayCurrency(String currencyCode) async {
    try {
      final profile = await _merchantRepository.getProfile();
      if (profile == null) return false;

      final updatedProfile = profile.copyWith(displayCurrencyCode: currencyCode);
      await _merchantRepository.saveProfile(updatedProfile);
      return true;
    } catch (e) {
      developer.log('CurrencyService: Error setting display currency: $e');
      return false;
    }
  }

  // Get available currencies for selection
  List<Currency> getAvailableCurrencies() {
    return Currency.allCurrencies;
  }
}

// Provider
// Provider for currency service
final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService(
    ref.watch(fxRatesRepositoryProvider),
    ref.watch(merchantRepositoryProvider),
  );
});

// State provider to track display currency changes
final displayCurrencyProvider = Provider<String>((ref) {
  return 'USD'; // Default fallback
});

// Future provider to get current display currency
final displayCurrencyFutureProvider = FutureProvider<String>((ref) async {
  final currencyService = ref.watch(currencyServiceProvider);
  try {
    final currency = await currencyService.getDisplayCurrency();
    return currency?.code ?? 'USD';
  } catch (e) {
    return 'USD'; // Default fallback
  }
});

// Provider to refresh display currency
final refreshDisplayCurrencyProvider = Provider<void>((ref) {
  ref.invalidate(displayCurrencyFutureProvider);
});
