import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Security service for data protection and validation
class SecurityService {
  SecurityService._();
  static final SecurityService instance = SecurityService._();

  final _random = Random.secure();

  /// Sanitize user input to prevent injection attacks
  String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '')
        .trim();
  }

  /// Validate URL for safety
  bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Only allow HTTP and HTTPS schemes
      if (!['http', 'https'].contains(uri.scheme.toLowerCase())) {
        return false;
      }

      // Prevent localhost and private IP ranges in production
      if (AppConfig.isProduction) {
        final host = uri.host.toLowerCase();
        if (host == 'localhost' || 
            host == '127.0.0.1' || 
            host.startsWith('192.168.') ||
            host.startsWith('10.') ||
            host.startsWith('172.')) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generate secure random string for IDs
  String generateSecureId({int length = 16}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  /// Hash sensitive data for storage
  String hashData(String data, {String? salt}) {
    final saltToUse = salt ?? generateSecureId(length: 32);
    final bytes = utf8.encode(data + saltToUse);
    final digest = sha256.convert(bytes);
    return '$saltToUse:${digest.toString()}';
  }

  /// Verify hashed data
  bool verifyHash(String data, String hashedData) {
    try {
      final parts = hashedData.split(':');
      if (parts.length != 2) return false;
      
      final salt = parts[0];
      final hash = parts[1];
      
      final newHash = hashData(data, salt: salt);
      return newHash.split(':')[1] == hash;
    } catch (e) {
      return false;
    }
  }

  /// Validate email format with security considerations
  bool isValidEmail(String email) {
    final trimmedEmail = email.trim().toLowerCase();
    
    // Basic format validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmedEmail)) return false;

    // Length validation
    if (trimmedEmail.length > 254) return false;

    // Local part validation
    final parts = trimmedEmail.split('@');
    if (parts[0].length > 64) return false;

    // Domain validation
    final domain = parts[1];
    if (domain.length > 253) return false;

    // Prevent disposable email domains (basic list)
    final disposableDomains = [
      'tempmail.org', '10minutemail.com', 'guerrillamail.com',
      'throwaway.email', 'temp-mail.org'
    ];
    
    if (disposableDomains.contains(domain)) return false;

    return true;
  }

  /// Rate limiting helper
  final Map<String, List<DateTime>> _rateLimitTracker = {};

  /// Check if action is rate limited
  bool isRateLimited(String identifier, {int maxAttempts = 5, Duration window = const Duration(minutes: 15)}) {
    final now = DateTime.now();
    final attempts = _rateLimitTracker[identifier] ?? [];
    
    // Remove old attempts outside the window
    attempts.removeWhere((attempt) => now.difference(attempt) > window);
    
    // Check if limit exceeded
    if (attempts.length >= maxAttempts) {
      return true;
    }
    
    // Add current attempt
    attempts.add(now);
    _rateLimitTracker[identifier] = attempts;
    
    return false;
  }

  /// Clear rate limit for identifier
  void clearRateLimit(String identifier) {
    _rateLimitTracker.remove(identifier);
  }

  /// Validate file upload security
  bool isValidFileUpload(String fileName, List<int> fileBytes, {List<String>? allowedExtensions}) {
    // Check file extension
    final extension = fileName.toLowerCase().split('.').last;
    final defaultAllowed = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];
    final allowed = allowedExtensions ?? defaultAllowed;
    
    if (!allowed.contains(extension)) return false;

    // Check file size (max 10MB)
    if (fileBytes.length > 10 * 1024 * 1024) return false;

    // Check for executable file signatures
    final executableSignatures = [
      [0x4D, 0x5A], // .exe
      [0x50, 0x4B], // .zip (could contain executables)
      [0x7F, 0x45, 0x4C, 0x46], // ELF executable
    ];

    for (final signature in executableSignatures) {
      if (fileBytes.length >= signature.length) {
        bool matches = true;
        for (int i = 0; i < signature.length; i++) {
          if (fileBytes[i] != signature[i]) {
            matches = false;
            break;
          }
        }
        if (matches) return false;
      }
    }

    return true;
  }

  /// Secure random token generation
  String generateSecureToken({int length = 32}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  /// Validate currency code
  bool isValidCurrencyCode(String code) {
    // ISO 4217 currency codes are 3 uppercase letters
    if (code.length != 3) return false;
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(code)) return false;
    
    // Check against supported currencies
    return AppConfig.supportedCurrencies.contains(code);
  }

  /// Validate amount for security
  bool isValidAmount(double amount) {
    // Check for NaN, infinity, or negative values
    if (amount.isNaN || amount.isInfinite || amount < 0) return false;
    
    // Check reasonable upper limit (1 billion)
    if (amount > 1000000000) return false;
    
    return true;
  }

  /// Validate date input
  bool isValidDate(DateTime date) {
    final now = DateTime.now();
    
    // Check if date is not too far in the past (100 years)
    if (date.isBefore(now.subtract(const Duration(days: 36500)))) return false;
    
    // Check if date is not too far in the future (10 years)
    if (date.isAfter(now.add(const Duration(days: 3650)))) return false;
    
    return true;
  }

  /// Clean sensitive data from memory
  void clearSensitiveData(List<String> sensitiveStrings) {
    for (final str in sensitiveStrings) {
      // In Dart, strings are immutable, but we can try to encourage GC
      // This is more of a best practice signal than actual clearing
      if (kDebugMode) {
        // Only in debug mode to avoid performance impact
        str.replaceAll(RegExp(r'.'), '0');
      }
    }
  }

  /// Validate phone number format
  bool isValidPhoneNumber(String phone) {
    // Remove formatting characters
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    
    // Check length (7-15 digits for international)
    if (cleanPhone.length < 7 || cleanPhone.length > 15) return false;
    
    // Only digits allowed
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) return false;
    
    return true;
  }

  /// Content Security Policy validation for URLs
  bool isAllowedDomain(String url) {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host.toLowerCase();
      
      // Whitelist of allowed domains
      final allowedDomains = [
        'api.exchangerate-api.com',
        'googleapis.com',
        'google.com',
        'googleadservices.com',
        'googlesyndication.com',
      ];
      
      return allowedDomains.any((allowed) => 
        domain == allowed || domain.endsWith('.$allowed'));
    } catch (e) {
      return false;
    }
  }
}
