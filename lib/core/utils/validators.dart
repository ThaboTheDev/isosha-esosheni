/// Client-side validation. Messages match the product copy exactly.
/// The server remains the authority; these exist for friendliness.
library;

class Validators {
  Validators._();

  static final membershipNumberRe = RegExp(r'^[A-Za-z0-9\-/ ]{3,40}$');
  static final phoneRe = RegExp(r'^\+?[0-9 ()-]{7,20}$');

  static String? fullName(String v) {
    final t = v.trim();
    if (t.length < 2 || t.length > 120) {
      return 'Enter your full name (2 to 120 characters).';
    }
    return null;
  }

  static String? preferredName(String v) {
    final t = v.trim();
    if (t.length > 60) return 'Preferred names are at most 60 characters.';
    return null;
  }

  /// Returns an error message for a date of birth, or null when fine.
  static String? dateOfBirth(DateTime? dob, DateTime now) {
    if (dob == null) return 'Enter your date of birth.';
    final age = ageInYears(dob, now);
    if (age < 18) {
      return 'Isosha Esosheni is open to members aged 18 and older.';
    }
    if (age > 110) return 'Check your date of birth.';
    return null;
  }

  static int ageInYears(DateTime dob, DateTime now) {
    var age = now.year - dob.year;
    final beforeBirthday =
        now.month < dob.month || (now.month == dob.month && now.day < dob.day);
    if (beforeBirthday) age -= 1;
    return age;
  }

  static String? email(String v) {
    final t = v.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[a-z]{2,}$', caseSensitive: false)
        .hasMatch(t)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Password rules with the exact per-rule messages.
  static String? password(String v) {
    if (v.length < 10) return 'Password must be at least 10 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(v)) {
      return 'Password must include an uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(v)) {
      return 'Password must include a lowercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(v)) {
      return 'Password must include a number.';
    }
    return null;
  }

  static String? confirm(String password, String confirm) {
    if (password != confirm) return 'Passwords do not match.';
    return null;
  }

  static String? membershipNumber(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    if (!membershipNumberRe.hasMatch(t)) {
      return 'Membership numbers are 3 to 40 letters, numbers, dashes, '
          'slashes or spaces.';
    }
    return null;
  }

  static String? phone(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    if (!phoneRe.hasMatch(t)) return 'Enter a valid phone number.';
    return null;
  }

  static String? ageRange(int min, int max) {
    if (max < min) return 'Maximum age must be at least the minimum age.';
    return null;
  }
}
