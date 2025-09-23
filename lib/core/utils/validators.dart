/// Enhanced validation utilities for the Invoice App
class AppValidators {
  AppValidators._();

  /// Email validation with comprehensive checks
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final trimmedValue = value.trim();
    
    // Basic format validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmedValue)) {
      return 'Please enter a valid email address';
    }

    // Length validation
    if (trimmedValue.length > 254) {
      return 'Email address is too long (max 254 characters)';
    }

    // Local part validation (before @)
    final parts = trimmedValue.split('@');
    if (parts[0].length > 64) {
      return 'Email local part is too long (max 64 characters)';
    }

    return null;
  }

  /// Phone validation with international format support
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final trimmedValue = value.trim();
    
    // Remove common formatting characters
    final cleanedPhone = trimmedValue.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    
    // Basic length validation (7-15 digits for international numbers)
    if (cleanedPhone.length < 7 || cleanedPhone.length > 15) {
      return 'Phone number must be 7-15 digits';
    }

    // Only digits allowed after cleaning
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanedPhone)) {
      return 'Phone number can only contain digits, spaces, hyphens, and parentheses';
    }

    return null;
  }

  /// Business name validation
  static String? businessName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Business name is required';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return 'Business name must be at least 2 characters';
    }

    if (trimmedValue.length > 100) {
      return 'Business name cannot exceed 100 characters';
    }

    // Allow letters, numbers, spaces, and common business symbols
    if (!RegExp(r'^[a-zA-Z0-9\s\-&.,()]+$').hasMatch(trimmedValue)) {
      return 'Business name contains invalid characters';
    }

    return null;
  }

  /// Address validation
  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 5) {
      return 'Address must be at least 5 characters';
    }

    if (trimmedValue.length > 200) {
      return 'Address cannot exceed 200 characters';
    }

    return null;
  }

  /// Amount validation for invoice items and totals
  static String? amount(String? value, {double? min, double? max}) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }

    final trimmedValue = value.trim();
    final amount = double.tryParse(trimmedValue);

    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount < 0) {
      return 'Amount cannot be negative';
    }

    if (min != null && amount < min) {
      return 'Amount must be at least ${min.toStringAsFixed(2)}';
    }

    if (max != null && amount > max) {
      return 'Amount cannot exceed ${max.toStringAsFixed(2)}';
    }

    // Check for too many decimal places
    final decimalPlaces = trimmedValue.contains('.') 
        ? trimmedValue.split('.')[1].length 
        : 0;
    if (decimalPlaces > 2) {
      return 'Amount can have maximum 2 decimal places';
    }

    return null;
  }

  /// Required field validation
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Client name validation
  static String? clientName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Client name is required';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return 'Client name must be at least 2 characters';
    }

    if (trimmedValue.length > 100) {
      return 'Client name cannot exceed 100 characters';
    }

    return null;
  }

  /// Description validation
  static String? description(String? value, {int maxLength = 500}) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return 'Description must be at least 2 characters';
    }

    if (trimmedValue.length > maxLength) {
      return 'Description cannot exceed $maxLength characters';
    }

    return null;
  }

  /// Combine multiple validators
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}