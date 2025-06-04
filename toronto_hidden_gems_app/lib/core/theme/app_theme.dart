import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class TorontoAppTheme {
  // Toronto Flag Colors & Apple-inspired palette
  static const Color torontoRed = Color(0xFFE31837);
  static const Color torontoBlue = Color(0xFF003F7F);
  static const Color mapLeafGreen = Color(0xFF2E7D32);
  static const Color cnTowerGrey = Color(0xFF424242);
  
  // Apple-style grays and backgrounds
  static const Color iosSystemGray = Color(0xFF8E8E93);
  static const Color iosSystemGray2 = Color(0xFFAEAEB2);
  static const Color iosSystemGray3 = Color(0xFFC7C7CC);
  static const Color iosSystemGray4 = Color(0xFFD1D1D6);
  static const Color iosSystemGray5 = Color(0xFFE5E5EA);
  static const Color iosSystemGray6 = Color(0xFFF2F2F7);
  
  // Apple-style semantic colors
  static const Color iosBlue = Color(0xFF007AFF);
  static const Color iosGreen = Color(0xFF34C759);
  static const Color iosOrange = Color(0xFFFF9500);
  static const Color iosRed = Color(0xFFFF3B30);
  static const Color iosYellow = Color(0xFFFFCC00);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SFProDisplay',
      
      // Color scheme inspired by Toronto flag + Apple colors
      colorScheme: ColorScheme.fromSeed(
        seedColor: torontoBlue,
        brightness: Brightness.light,
        primary: torontoBlue,
        secondary: torontoRed,
        tertiary: mapLeafGreen,
        surface: Colors.white,
        background: iosSystemGray6,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
      ),
      
      // Apple-style scaffold background
      scaffoldBackgroundColor: iosSystemGray6,
      
      // Apple-style app bar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          fontFamily: 'SFProDisplay',
        ),
        iconTheme: IconThemeData(
          color: torontoBlue,
          size: 22,
        ),
      ),
      
      // Apple-style cards
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Apple-style buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: torontoBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'SFProDisplay',
          ),
        ),
      ),
      
      // Apple-style text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: torontoBlue,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'SFProDisplay',
          ),
        ),
      ),
      
      // Apple-style outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: torontoBlue,
          side: const BorderSide(color: torontoBlue, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'SFProDisplay',
          ),
        ),
      ),
      
      // Apple-style floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: torontoRed,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: CircleBorder(),
      ),
      
      // Apple-style bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: torontoBlue,
        unselectedItemColor: iosSystemGray,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          fontFamily: 'SFProDisplay',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          fontFamily: 'SFProDisplay',
        ),
      ),
      
      // Apple-style input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: iosSystemGray6,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: torontoBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(
          color: iosSystemGray,
          fontSize: 16,
          fontFamily: 'SFProDisplay',
        ),
      ),
      
      // Apple-style list tile
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.white,
        selectedTileColor: iosSystemGray6,
        iconColor: iosSystemGray,
        textColor: Colors.black87,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'SFProDisplay',
          color: Colors.black87,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          fontFamily: 'SFProDisplay',
          color: iosSystemGray,
        ),
      ),
      
      // Apple-style text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: 'SFProDisplay',
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: 'SFProDisplay',
        ),
        displaySmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: 'SFProDisplay',
        ),
        headlineLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontFamily: 'SFProDisplay',
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontFamily: 'SFProDisplay',
        ),
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontFamily: 'SFProDisplay',
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontFamily: 'SFProDisplay',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
          fontFamily: 'SFProDisplay',
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
          fontFamily: 'SFProDisplay',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black87,
          fontFamily: 'SFProDisplay',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.black87,
          fontFamily: 'SFProDisplay',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: iosSystemGray,
          fontFamily: 'SFProDisplay',
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: torontoBlue,
          fontFamily: 'SFProDisplay',
        ),
        labelMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: torontoBlue,
          fontFamily: 'SFProDisplay',
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: iosSystemGray,
          fontFamily: 'SFProDisplay',
        ),
      ),
      
      // Apple-style divider
      dividerTheme: const DividerThemeData(
        color: iosSystemGray4,
        thickness: 0.5,
        space: 1,
      ),
    );
  }
}

// Toronto-themed custom colors extension
extension TorontoColors on ColorScheme {
  Color get torontoRed => TorontoAppTheme.torontoRed;
  Color get torontoBlue => TorontoAppTheme.torontoBlue;
  Color get mapLeafGreen => TorontoAppTheme.mapLeafGreen;
  Color get cnTowerGrey => TorontoAppTheme.cnTowerGrey;
  Color get iosSystemGray => TorontoAppTheme.iosSystemGray;
  Color get iosBlue => TorontoAppTheme.iosBlue;
  Color get iosGreen => TorontoAppTheme.iosGreen;
} 