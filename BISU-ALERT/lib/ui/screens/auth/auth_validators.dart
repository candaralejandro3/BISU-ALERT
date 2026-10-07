/// Form validators shared by the sign-in and registration screens.
class AuthValidators {
  const AuthValidators._();

  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final RegExp _digit = RegExp(r'\d');

  static String? notEmpty(String? value, String message) {
    return (value ?? '').trim().isEmpty ? message : null;
  }

  static String? email(String? value) {
    final String email = (value ?? '').trim();
    if (email.isEmpty) {
      return 'Enter your email address.';
    }
    if (!_emailPattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) {
      return 'Enter your password.';
    }
    if (password.length < 8) {
      return 'Use at least 8 characters.';
    }
    return null;
  }

  static String? phoneNumber(String? value) {
    final String phone = (value ?? '').trim();
    if (phone.isEmpty) {
      return 'Enter a mobile number responders can reach.';
    }
    if (_digit.allMatches(phone).length < 7) {
      return 'Enter a complete mobile number.';
    }
    return null;
  }
}
