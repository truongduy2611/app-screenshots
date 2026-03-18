import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';

class AppTheme {
  AppTheme._();

  // Creative Indigo — primary seed
  static const seedColor = Color(0xFF6366F1);

  // Custom dark surface colors (neutral charcoal, Apple-style)
  static const _darkSurface = Color(0xFF1C1C1E);
  static const _darkSurfaceContainer = Color(0xFF2C2C2E);
  static const _darkSurfaceContainerHigh = Color(0xFF3A3A3C);

  // TECH_DEBT: Workaround for Flutter macOS bug #145892:
  // SystemMouseCursors.click doesn't change on hover — only while
  // the mouse button is held down. Setting an explicit mouseCursor
  // via theme forces the correct hand cursor on all button types.
  static final _clickCursor = WidgetStateProperty.resolveWith<MouseCursor>(
    (states) => states.contains(WidgetState.disabled)
        ? SystemMouseCursors.basic
        : SystemMouseCursors.click,
  );

  static final _buttonCursorStyle = ButtonStyle(mouseCursor: _clickCursor);

  /// Merges Sora (display/headline/title) + Inter (body/label)
  static TextTheme _buildTextTheme(Brightness brightness) {
    final base = ThemeData(brightness: brightness).textTheme;
    final sora = GoogleFonts.soraTextTheme(base);
    final inter = GoogleFonts.interTextTheme(base);

    return inter.copyWith(
      // Display — Sora
      displayLarge: sora.displayLarge,
      displayMedium: sora.displayMedium,
      displaySmall: sora.displaySmall,
      // Headline — Sora
      headlineLarge: sora.headlineLarge,
      headlineMedium: sora.headlineMedium,
      headlineSmall: sora.headlineSmall,
      // Title — Sora
      titleLarge: sora.titleLarge,
      titleMedium: sora.titleMedium,
      titleSmall: sora.titleSmall,
      // Body — Inter (already from base)
      // Label — Inter (already from base)
    );
  }

  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: seedColor,
    splashFactory: InkSparkle.splashFactory,
    textTheme: _buildTextTheme(Brightness.light),
    iconTheme: const IconThemeData(weight: 300),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ).surface,
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (_) =>
          const Icon(Symbols.arrow_back_ios_new_rounded),
      closeButtonIconBuilder: (_) => const Icon(Symbols.close_rounded),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: seedColor, width: 1),
      ),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIconColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? seedColor
            : const Color(0xFF9CA3AF),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      menuStyle: MenuStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        elevation: const WidgetStatePropertyAll(4),
      ),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    // TECH_DEBT: Button cursor workarounds (Flutter #145892) ──
    iconButtonTheme: IconButtonThemeData(style: _buttonCursorStyle),
    textButtonTheme: TextButtonThemeData(style: _buttonCursorStyle),
    filledButtonTheme: FilledButtonThemeData(style: _buttonCursorStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: _buttonCursorStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonCursorStyle),
    segmentedButtonTheme: SegmentedButtonThemeData(style: _buttonCursorStyle),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: seedColor,
    splashFactory: InkSparkle.splashFactory,
    scaffoldBackgroundColor: _darkSurface,
    textTheme: _buildTextTheme(Brightness.dark),
    iconTheme: const IconThemeData(weight: 300),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _darkSurface,
      surfaceTintColor: Colors.transparent,
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (_) =>
          const Icon(Symbols.arrow_back_ios_new_rounded),
      closeButtonIconBuilder: (_) => const Icon(Symbols.close_rounded),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: _darkSurfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _darkSurface,
      indicatorColor: seedColor.withValues(alpha: 0.2),
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: _darkSurfaceContainer),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _darkSurfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: seedColor, width: 1),
      ),
      filled: true,
      fillColor: _darkSurfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIconColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? seedColor
            : const Color(0xFF6B7280),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: _darkSurfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(_darkSurfaceContainer),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        elevation: const WidgetStatePropertyAll(8),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _darkSurfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    // TECH_DEBT: Button cursor workarounds (Flutter #145892) ──
    iconButtonTheme: IconButtonThemeData(style: _buttonCursorStyle),
    textButtonTheme: TextButtonThemeData(style: _buttonCursorStyle),
    filledButtonTheme: FilledButtonThemeData(style: _buttonCursorStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: _buttonCursorStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonCursorStyle),
    segmentedButtonTheme: SegmentedButtonThemeData(style: _buttonCursorStyle),
  );
}
