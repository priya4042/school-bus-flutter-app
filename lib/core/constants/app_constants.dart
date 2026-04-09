class AppConstants {
  static const String supabaseUrl = 'https://pjovjynubnrvhwpnfnlw.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBqb3ZqeW51Ym5ydmh3cG5mbmx3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIwNzEwNjcsImV4cCI6MjA4NzY0NzA2N30.SkEOaLUY6o1MrmGXgilW_hNA0fi6fvKWURES82UVp8M';
  static const String apiBaseUrl = 'https://busway-backend-9maw.onrender.com';
  static const String appUrl = 'https://school-bus-fee-management-system.vercel.app';
  static const String paymentApiBaseUrl = 'https://school-bus-fee-management-system.vercel.app';
  static const String payuMerchantKey = String.fromEnvironment(
    'PAYU_MERCHANT_KEY',
    defaultValue: '',
  );

  static const int defaultCutoffDay = 10;
  static const int defaultGracePeriod = 2;
  static const double defaultDailyPenalty = 50.0;
  static const double defaultMaxPenalty = 500.0;
  static const bool defaultStrictNoSkip = true;

  static const String appName = 'BusWay Pro';
  static const String currency = '₹';

  static const List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
}
