import 'package:flutter/material.dart';

class FreshCycleTheme {
  FreshCycleTheme._();

  // Brand colors
  static const Color primary = Color(0xFF1D9E75);
  static const Color primaryLight = Color(0xFFE1F5EE);
  static const Color primaryDark = Color(0xFF085041);

  static const Color accent = Color(0xFF0F6E56);

  // Urgency colors
  static const Color urgencyCritical = Color(0xFFE24B4A);
  static const Color urgencyCriticalBg = Color(0xFFFCEBEB);
  static const Color urgencySoon = Color(0xFFBA7517);
  static const Color urgencySoonBg = Color(0xFFFAEEDA);
  static const Color urgencySafe = Color(0xFF639922);
  static const Color urgencySafeBg = Color(0xFFEAF3DE);

  // Request badge
  static const Color requestColor = Color(0xFF534AB7);
  static const Color requestBg = Color(0xFFEEEDFE);

  // Neutral
  static const Color surfaceGray = Color(0xFFF8F8F6);
  static const Color borderColor = Color(0xFFE8E6E0);
  static const Color textPrimary = Color(0xFF1A1A18);
  static const Color textSecondary = Color(0xFF6B6966);
  static const Color textHint = Color(0xFFADAB9A);

  // Shared food categories
  static const List<String> foodCategories = [
    'All',
    'Produce',
    'Dairy',
    'Bakery',
    'Meat & fish',
    'Meals & leftovers',
    'Snacks',
    'Beverages',
    'Other',
  ];

  // Avatar palette
  static const List<Color> avatarBgs = [
    Color(0xFFE1F5EE),
    Color(0xFFEEEDFE),
    Color(0xFFFAEEDA),
    Color(0xFFE6F1FB),
    Color(0xFFFBEAF0),
    Color(0xFFEAF3DE),
  ];
  static const List<Color> avatarFgs = [
    Color(0xFF085041),
    Color(0xFF3C3489),
    Color(0xFF633806),
    Color(0xFF0C447C),
    Color(0xFF72243E),
    Color(0xFF27500A),
  ];

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: surfaceGray,
        fontFamily: 'SF Pro Display',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: primary,
          unselectedLabelColor: textSecondary,
          indicatorColor: primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: primaryLight,
          side: const BorderSide(color: borderColor, width: 0.5),
          labelStyle: const TextStyle(fontSize: 12, color: textSecondary),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderColor, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderColor, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primary, width: 1),
          ),
          hintStyle: const TextStyle(color: textHint, fontSize: 14),
        ),
      );
}

Color urgencyColor(dynamic urgency) {
  switch (urgency.toString()) {
    case 'UrgencyLevel.critical':
      return FreshCycleTheme.urgencyCritical;
    case 'UrgencyLevel.soon':
      return FreshCycleTheme.urgencySoon;
    default:
      return FreshCycleTheme.urgencySafe;
  }
}

Color urgencyBgColor(dynamic urgency) {
  switch (urgency.toString()) {
    case 'UrgencyLevel.critical':
      return FreshCycleTheme.urgencyCriticalBg;
    case 'UrgencyLevel.soon':
      return FreshCycleTheme.urgencySoonBg;
    default:
      return FreshCycleTheme.urgencySafeBg;
  }
}
