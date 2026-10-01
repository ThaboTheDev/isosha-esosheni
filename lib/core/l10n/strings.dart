import 'package:flutter/widgets.dart';

/// App strings (en-ZA). The v1 app ships English only; this class is the
/// single source of truth for user-facing copy so strings stay consistent
/// with the web platform. `l10n/app_en_ZA.arb` mirrors these keys for the
/// eventual `flutter gen-l10n` migration.
class S {
  const S._();

  static const S instance = S._();

  static S of(BuildContext context) => instance;

  // ---- App shell ----
  String get appName => 'Isosha Esosheni';
  String get tabHome => 'Home';
  String get tabDiscover => 'Discover';
  String get tabCommunity => 'Community';
  String get tabMessages => 'Messages';
  String get tabProfile => 'Profile';
  String get more => 'More';
  String get back => 'Back';
  String get cancel => 'Cancel';
  String get save => 'Save';
  String get saving => 'Saving…';
  String get done => 'Done';
  String get confirm => 'Confirm';
  String get close => 'Close';
  String get next => 'Next';
  String get skip => 'Skip';
  String get retry => 'Retry';
  String get search => 'Search';
  String get loading => 'Loading…';
  String get error => 'Something went wrong';
  String get tryAgain => 'Try again';
  String get seeAll => 'See all';
  String get notFound => 'Not found';

  // ---- Auth ----
  String get signIn => 'Sign in';
  String get signInTitle => 'Welcome back';
  String get signInSubtitle =>
      'Sign in with the same email you use on the web platform.';
  String get email => 'Email address';
  String get password => 'Password';
  String get forgotPassword => 'Forgot your password?';
  String get createAccount => 'Create account';
  String get signUp => 'Register';
  String get registerTitle => 'Begin your journey';
  String get registerSubtitle =>
      'Isosha Esosheni is the governed courtship and marriage platform of The Revelation Spiritual Home Kingdom. It is not a casual dating app.';
  String get firstName => 'First name';
  String get surname => 'Surname';
  String get continueAsGuest => 'Continue as guest';
  String get alreadyHaveAccount => 'Already registered? Sign in';
  String get verifyEmailSent =>
      'We sent a confirmation link to your email. Open it to activate your account.';
  String get emailConfirmed => 'Email confirmed';
  String get emailConfirmedBody =>
      'Your address is confirmed. Sign in to continue your journey.';
  String get passwordResetSent => 'Reset link sent. Check your inbox.';
  String get resetPassword => 'Reset password';
  String get newPassword => 'New password';
  String get confirmPassword => 'Confirm password';
  String get mfaTitle => 'Two-step verification';
  String get mfaSubtitle => 'Enter the 6-digit code to continue.';
  String get mfaCode => 'Verification code';
  String get verify => 'Verify';
  String get agreement =>
      'By continuing you agree to our Terms of Service and acknowledge the Privacy Policy.';
  String get guestBanner =>
      'You are browsing as a guest. Create an account to begin your journey.';

  // ---- Errors / notices ----
  String get errEmail => 'Enter a valid email address.';
  String get errPasswordShort => 'At least 8 characters.';
  String get errPasswordMatch => 'Passwords do not match.';
  String get errRequired => 'This field is required.';
  String errMinLength(String label, int n) =>
      '$label needs at least $n characters.';
  String get errWeakPassword =>
      'That password is too weak. Use at least 8 characters with letters and numbers.';
  String get errCredentials => 'That email and password do not match.';
  String get errEmailTaken => 'An account with that email already exists.';
  String get errConfirmFirst =>
      'Please confirm your email using the link we sent you.';
  String get errSuspended =>
      'Your account is suspended. Appeal from the web platform.';
  String get errDeactivated =>
      'Your account is deactivated. Sign in on the web to reactivate it.';
  String get friendlyGeneric =>
      'Something went wrong. Please check your connection and try again.';

  // ---- Profile ----
  String get myProfile => 'My profile';
  String get editProfile => 'Edit profile';
  String get completeProfile => 'Complete your profile';
  String get profileCompletion => 'Profile completion';
  String get about => 'About you';
  String get lookingFor => 'What you are looking for';
  String get profileGuarded =>
      'Sign in and complete your own profile to view members.';
  String get videoIntro => 'Video introduction';

  // ---- Discover ----
  String get discover => 'Discover';
  String get recommendations => 'Recommended for you';
  String get sendInterest => 'Send interest';
  String get interestSent => 'Interest sent';
  String get withdrawInterest => 'Withdraw interest';
  String get pass => 'Pass';
  String get save_ => 'Save';
  String get likedByYou => 'Liked by you';
  String get savedByYou => 'Saved by you';
  String get mutualMatches => 'Mutual matches';
  String get endMatch => 'End match';
  String get matchEnded => 'Match ended';

  // ---- Relationships ----
  String get relationships => 'Relationships';
  String get myJourney => 'My journey';
  String get stages => 'Journey stages';
  String get stage1 => 'Introduction';
  String get stage2 => 'Friendship';
  String get stage3 => 'Courtship';
  String get stage4 => 'Commitment';
  String get proposeNextStage => 'Propose next stage';
  String get proposalSent => 'Proposal sent';
  String get consult => 'Consultation';
  String get requestConsultation => 'Request consultation';

  // ---- Household ----
  String get households => 'Households';
  String get householdProfile => 'Household profile';

  // ---- Community ----
  String get community => 'Community';
  String get stories => 'Stories';
  String get posts => 'Posts';
  String get sharePost => 'Share a word…';
  String get comment => 'Comment';
  String get report => 'Report';
  String get reportSent => 'Report sent. Our shepherds will review it.';

  // ---- Conferences ----
  String get conferences => 'Conferences';
  String get liveNow => 'Live now';
  String get register => 'Register';
  String get registered => 'Registered';

  // ---- Messaging ----
  String get messages => 'Messages';
  String get typeMessage => 'Type a message…';
  String get messageDeleted => 'This message was deleted.';
  String get contactBlockedNotice =>
      'Sharing phone numbers, emails or social handles before commitment is not allowed. Shepherds oversee all conversations.';
  String get typing => 'typing…';
  String get readReceipt => 'Read';

  // ---- Notifications ----
  String get notifications => 'Notifications';
  String get markAllRead => 'Mark all as read';

  // ---- Account ----
  String get account => 'Account';
  String get settings => 'Settings';
  String get security => 'Security';
  String get signOut => 'Sign out';
  String get deleteAccount => 'Request account closure';
  String get deleteAccountBody =>
      'Account closure is handled by our team. Email shepherds@isosha with your request, or use the web platform.';
  String get openOnWeb => 'Open on web';
  String get adminOnWeb => 'Administration is available on the web';
  String get suspendedTitle => 'Account suspended';
  String get suspendedBody =>
      'Your account has been suspended by the shepherds. You may appeal from the web platform.';

  // ---- Privacy / legal ----
  String get privacyPolicy => 'Privacy Policy';
  String get terms => 'Terms of Service';
  String get dataExport => 'Export my data';
  String get dataExportBody =>
      'Request a copy of your personal data. We will email it to you.';

  // ---- Demo banner ----
  String get demoBanner =>
      'Demo environment — accounts and data here are synthetic.';
}
