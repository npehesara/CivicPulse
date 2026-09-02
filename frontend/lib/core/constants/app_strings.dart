class AppStrings {
  AppStrings._();

  static const String appName = 'CivicPulse';
  static const String appTagline = 'Citizen Issue Reporting & Public Action';

  // Auth Strings
  static const String loginTitle = 'Welcome back';
  static const String loginSubtitle = 'Sign in to track and report civic issues in your area.';
  static const String registerTitle = 'Create an Account';
  static const String registerSubtitle = 'Join CivicPulse to report and improve community infrastructure.';

  static const String emailLabel = 'Email Address';
  static const String emailHint = 'e.g. john@example.com';

  static const String passwordLabel = 'Password';
  static const String passwordHint = '••••••••';

  static const String confirmPasswordLabel = 'Confirm Password';
  static const String confirmPasswordHint = '••••••••';

  static const String fullNameLabel = 'Full Name';
  static const String fullNameHint = 'e.g. John Doe';

  static const String phoneLabel = 'Phone Number (Optional)';
  static const String phoneHint = 'e.g. 0771234567';

  static const String signInButton = 'Sign In';
  static const String registerButton = 'Create Account';
  static const String logoutButton = 'Sign Out';

  static const String noAccountPrompt = "Don't have an account? ";
  static const String registerLink = 'Register';
  static const String hasAccountPrompt = 'Already have an account? ';
  static const String loginLink = 'Sign In';

  // Home Strings
  static const String homeWelcome = 'Welcome';
  static const String homeTitle = 'Civic Dashboard';
  static const String homeSubtitle = 'Explore community reports and stay updated on resolutions.';

  // Error & Feedback Strings
  static const String errInvalidCredentials = 'Invalid email or password.';
  static const String errDuplicateEmail = 'An account with this email already exists.';
  static const String errAccountSuspended = 'Your account is suspended. Please contact support.';
  static const String errNetwork = 'Unable to connect to CivicPulse. Please check your network connection.';
  static const String errServer = 'Something went wrong on the server. Please try again.';
  static const String errUnknown = 'An unexpected error occurred. Please try again.';

  static const String registrationSuccess = 'Account created successfully! Please sign in.';
}
