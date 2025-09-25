/// App configuration with environment-specific values
class AppConfig {
  AppConfig._();

  // Environment configuration
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );
  static const bool isDebug = !isProduction;

  // Ad configuration
  static const String admobAppId = String.fromEnvironment(
    'ADMOB_APP_ID',
    defaultValue: 'ca-app-pub-8773420441524688~5433794386',
  );

  static const String nativeAdUnitId = String.fromEnvironment(
    'NATIVE_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-8773420441524688/9150226855',
  );

  static const String bannerAdUnitId = String.fromEnvironment(
    'BANNER_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-8773420441524688/1599039891',
  );

  // Test ad IDs for development
  static const String testNativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  // Get the appropriate ad unit ID based on environment
  static String get currentNativeAdUnitId =>
      isProduction ? nativeAdUnitId : testNativeAdUnitId;
  static String get currentBannerAdUnitId =>
      isProduction ? bannerAdUnitId : testBannerAdUnitId;

  // API configuration
  static const String exchangeRateApiUrl =
      'https://api.exchangerate-api.com/v4/latest/';
  static const String fallbackExchangeRateApiUrl =
      'https://open.er-api.com/v6/latest/';
  static const Duration apiTimeout = Duration(seconds: 10);
  static const Duration shortTimeout = Duration(seconds: 5);

  // App configuration
  static const String appName = 'BillExpert';
  static const String appVersion = '1.0.0';
  static const String developerName = 'Hashim Hameem';
  static const String developerEmail = 'scnz141@gmail.com';

  // Currency configuration
  static const String defaultCurrency = 'USD';
  static const List<String> supportedCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'CHF',
    'CNY',
    'INR',
  ];

  // Performance configuration
  static const int adInterval = 3; // Show ad after every 3 items
  static const Duration currencyRefreshInterval = Duration(hours: 1);
  static const int maxRecentInvoices = 10;

  // Security configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
