import 'package:flutter/material.dart';

// Exact colors from tailwind.config.js
class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E3A8A);

  // Secondary
  static const Color secondary = Color(0xFF64748B);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Slate palette (exact Tailwind)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // Emerald
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);

  // Red
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red400 = Color(0xFFF87171);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);

  // Amber
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);

  // Blue
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue800 = Color(0xFF1E40AF);

  // Indigo
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo600 = Color(0xFF4F46E5);

  // Orange
  static const Color orange50 = Color(0xFFFFF7ED);
  static const Color orange100 = Color(0xFFFFEDD5);
  static const Color orange600 = Color(0xFFEA580C);

  // Green
  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green600 = Color(0xFF16A34A);
  static const Color green700 = Color(0xFF15803D);

  // Cyan
  static const Color cyan500 = Color(0xFF06B6D4);

  // Purple
  static const Color purple50 = Color(0xFFFAF5FF);
  static const Color purple600 = Color(0xFF9333EA);

  // Surface
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Colors.white;

  // Backward-compat aliases used by pages
  static const Color error = danger;
  static const Color info = blue500;
  static const Color accent = primaryDark;
  static const Color accentLight = indigo500;
  static const Color paid = success;
  static const Color unpaid = warning;
  static const Color overdue = danger;
  static const Color pending = orange600;
  static const Color partial = purple600;
  static const Color textPrimary = slate800;
  static const Color textSecondary = slate500;
  static const Color border = slate200;
  static const Color divider = slate100;
}

class AppTheme {
  // Use bundled PlusJakartaSans font (loaded from assets/fonts/)
  // This works offline and never fails - same font as React app
  static const String fontFamily = 'PlusJakartaSans';

  static const TextStyle _baseTextStyle = TextStyle(fontFamily: fontFamily);

  // Exact label style: text-[10px] font-black uppercase tracking-widest
  static TextStyle get labelStyle => _baseTextStyle.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.0,
    color: AppColors.slate400,
  );

  // text-[9px] font-black uppercase tracking-widest
  static TextStyle get labelSmall => _baseTextStyle.copyWith(
    fontSize: 9,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.0,
    color: AppColors.slate400,
  );

  // text-[8px] font-black uppercase tracking-widest
  static TextStyle get labelXs => _baseTextStyle.copyWith(
    fontSize: 8,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.0,
    color: AppColors.slate400,
  );

  // Heading: font-black tracking-tighter
  static TextStyle get headingLarge => _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.5,
    color: AppColors.slate800,
  );

  static TextStyle get headingMedium => _baseTextStyle.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    color: AppColors.slate800,
  );

  static TextStyle get headingSmall => _baseTextStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: AppColors.slate800,
  );

  // Premium shadow
  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 40,
      offset: const Offset(0, 10),
      spreadRadius: -10,
    ),
  ];

  static List<BoxShadow> primaryButtonShadow([double opacity = 0.2]) => [
    BoxShadow(
      color: AppColors.primary.withOpacity(opacity),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Card decoration: rounded-2xl border border-slate-200 shadow-premium
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.slate200),
    boxShadow: premiumShadow,
  );

  // Large card: rounded-[2.5rem]
  static BoxDecoration get cardLargeDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: AppColors.slate200),
    boxShadow: premiumShadow,
  );

  // Extra large card: rounded-[3rem]
  static BoxDecoration get cardXlDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(32),
    border: Border.all(color: AppColors.slate100),
    boxShadow: premiumShadow,
  );

  // Input: bg-primary/5 border border-primary/20 rounded-2xl
  static InputDecoration inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label.toUpperCase(),
      labelStyle: labelSmall.copyWith(color: AppColors.slate400),
      filled: true,
      fillColor: AppColors.primary.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.slate400, size: 20) : null,
    );
  }

  // Admin input: bg-slate-50 border border-slate-200
  static InputDecoration adminInputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label.toUpperCase(),
      labelStyle: labelSmall.copyWith(color: AppColors.slate400),
      filled: true,
      fillColor: AppColors.slate50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.slate200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.slate400, size: 20) : null,
    );
  }

  // Primary button style: bg-primary text-white rounded-2xl shadow-xl shadow-primary/20
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: _baseTextStyle.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 2.0,
    ),
  );

  // Dark button: bg-slate-900
  static ButtonStyle get darkButton => ElevatedButton.styleFrom(
    backgroundColor: AppColors.slate900,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: _baseTextStyle.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 2.0,
    ),
  );

  // Secondary button: bg-slate-100
  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
    backgroundColor: AppColors.slate100,
    foregroundColor: AppColors.slate600,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: _baseTextStyle.copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 2.0,
    ),
  );

  static ThemeData get lightTheme {
    // Use bundled PlusJakartaSans font from assets/fonts/
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.slate50,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate800,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: AppColors.slate800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.slate200),
        ),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.primary.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.slate400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
        unselectedLabelStyle: TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.slate100,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.slate100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(fontFamily: 'PlusJakartaSans', 
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}
