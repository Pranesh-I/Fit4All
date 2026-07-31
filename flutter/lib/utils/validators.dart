// lib/utils/validators.dart
// SAI Sports Talent Assessment - Input Validators

class Validators {
  Validators._();

  static final _mobileRegex = RegExp(r'^\+91[6-9]\d{9}$');
  static final _passwordUppercase = RegExp(r'[A-Z]');
  static final _passwordLowercase = RegExp(r'[a-z]');
  static final _passwordDigit = RegExp(r'\d');
  static final _passwordSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 255) {
      return 'Name is too long';
    }
    return null;
  }

  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final formatted = value.trim().startsWith('+91')
        ? value.trim()
        : '+91${value.trim()}';
    if (!_mobileRegex.hasMatch(formatted)) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!_passwordUppercase.hasMatch(value)) {
      return 'Must contain at least one uppercase letter';
    }
    if (!_passwordLowercase.hasMatch(value)) {
      return 'Must contain at least one lowercase letter';
    }
    if (!_passwordDigit.hasMatch(value)) {
      return 'Must contain at least one digit';
    }
    if (!_passwordSpecial.hasMatch(value)) {
      return 'Must contain at least one special character';
    }
    return null;
  }

  static String? validateDateOfBirth(DateTime? value) {
    if (value == null) {
      return 'Date of birth is required';
    }
    final now = DateTime.now();
    final age = now.year - value.year -
        (now.isBefore(DateTime(now.year, value.month, value.day)) ? 1 : 0);
    if (age < 10 || age > 50) {
      return 'Athlete must be between 10 and 50 years old';
    }
    return null;
  }

  static String? validateHeight(String? value) {
    if (value == null || value.isEmpty) return 'Height is required';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Enter a valid height';
    if (parsed < 50 || parsed > 300) return 'Height must be between 50–300 cm';
    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) return 'Weight is required';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Enter a valid weight';
    if (parsed < 10 || parsed > 500) return 'Weight must be between 10–500 kg';
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Format mobile number to +91 format for API
  static String formatMobile(String mobile) {
    final cleaned = mobile.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.startsWith('+91')) return cleaned;
    if (cleaned.startsWith('91') && cleaned.length == 12) return '+$cleaned';
    return '+91$cleaned';
  }
}
