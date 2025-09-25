import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Centralized logging utility that respects build modes
class AppLogger {
  static const String _tag = 'BillExpert';
  
  /// Log debug information (only in debug builds)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag ?? _tag,
        level: 500, // Debug level
      );
    }
  }
  
  /// Log informational messages (only in debug builds)
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag ?? _tag,
        level: 800, // Info level
      );
    }
  }
  
  /// Log warnings (appears in debug and profile builds)
  static void warning(String message, {String? tag}) {
    if (kDebugMode || kProfileMode) {
      developer.log(
        message,
        name: tag ?? _tag,
        level: 900, // Warning level
      );
    }
  }
  
  /// Log errors (appears in all builds for crash reporting)
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log critical errors that should always be visible
  static void critical(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 1200, // Severe level
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Safe logging for sensitive data (only in debug mode with sanitization)
  static void debugSensitive(String message, {String? tag}) {
    if (kDebugMode) {
      // In debug mode, you can choose to sanitize or show full data
      final sanitized = _sanitizeMessage(message);
      developer.log(
        '[SENSITIVE] $sanitized',
        name: tag ?? _tag,
        level: 500,
      );
    }
  }
  
  /// Sanitize sensitive information from log messages
  static String _sanitizeMessage(String message) {
    // Replace potential sensitive data patterns
    return message
        .replaceAll(RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'), '****-****-****-****') // Credit cards
        .replaceAll(RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), '***@***.***') // Emails
        .replaceAll(RegExp(r'\b\d{10,15}\b'), '***********'); // Phone numbers
  }
  
  /// Check if logging is enabled for current build
  static bool get isLoggingEnabled => kDebugMode;
  
  /// Check if verbose logging is enabled
  static bool get isVerboseLoggingEnabled => kDebugMode;
}
