import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global error handling service for the application
class ErrorService {
  ErrorService._();
  static final ErrorService instance = ErrorService._();

  /// Initialize global error handling
  void initialize() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError(
        'Flutter Error',
        details.exception,
        details.stack,
        context: details.context?.toString(),
      );
    };

    // Catch errors outside of Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError('Platform Error', error, stack);
      return true;
    };
  }

  /// Log error with comprehensive details
  void _logError(
    String type,
    Object error,
    StackTrace? stackTrace, {
    String? context,
  }) {
    developer.log(
      'ERROR: $type',
      error: error,
      stackTrace: stackTrace,
      name: 'InvoiceApp',
    );

    if (kDebugMode) {
      debugPrint('=== ERROR DETAILS ===');
      debugPrint('Type: $type');
      debugPrint('Error: $error');
      if (context != null) debugPrint('Context: $context');
      debugPrint('Stack: $stackTrace');
      debugPrint('=====================');
    }
  }

  /// Handle and report application errors
  static void handleError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    bool fatal = false,
  }) {
    instance._logError(
      fatal ? 'Fatal Error' : 'Application Error',
      error,
      stackTrace,
      context: context,
    );
  }

  /// Show user-friendly error message
  static void showUserError(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: duration ?? const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Network error handler
  static String getNetworkErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('timeout')) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (errorString.contains('no internet') || 
               errorString.contains('network unreachable')) {
      return 'No internet connection. Please check your network settings.';
    } else if (errorString.contains('server') || errorString.contains('500')) {
      return 'Server error. Please try again later.';
    } else if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Requested resource not found.';
    } else if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Authentication failed. Please check your credentials.';
    } else if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'Access denied.';
    } else {
      return 'Network error occurred. Please try again.';
    }
  }

  /// Data validation error handler
  static String getValidationErrorMessage(String field, Object error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('required')) {
      return '$field is required.';
    } else if (errorString.contains('email')) {
      return 'Please enter a valid email address.';
    } else if (errorString.contains('phone')) {
      return 'Please enter a valid phone number.';
    } else if (errorString.contains('number')) {
      return 'Please enter a valid number.';
    } else if (errorString.contains('date')) {
      return 'Please enter a valid date.';
    } else {
      return 'Invalid $field format.';
    }
  }
}
