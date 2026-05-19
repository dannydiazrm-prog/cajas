import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PALETA
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  // Acento principal — verde profundo original
  static const primary = Color(0xFF0c6246);

  // Variantes del acento
  static const primaryLight = Color(0xFF1a8a61);   // hover / énfasis
  static const primaryMuted = Color(0xFF0c624680); // 50 % opacidad para bordes

  // Fondos oscuros (nueva paleta dark)
  static const background = Color(0xFF0a1f17);     // fondo global
  static const surface    = Color(0xFF112d1f);     // cards, inputs
  static const surfaceAlt = Color(0xFF163826);     // cards elevadas / hover

  // Textos
  static const onPrimary     = Colors.white;
  static const onBackground  = Color(0xFFe8f5ee);  // blanco verdoso suave
  static const onSurface     = Color(0xFFb8d4c0);  // texto secundario
  static const onSurfaceDim  = Color(0xFF6a9479);  // texto tenue / hints

  // Estados
  static const error   = Color(0xFFFF6B6B);
  static const warning = Color(0xFFFFB347);
  static const success = Color(0xFF4CAF82);

  // Borde sutil global
  static const border = Color(0xFF1e4a32);
}

// ─────────────────────────────────────────────────────────────────────────────
// TEMA
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get theme {
    final base = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,

      // ── Scaffold ──────────────────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.background,

      // ── Color scheme ──────────────────────────────────────────────────────
      colorScheme: const ColorScheme.dark(
        primary:          AppColors.primary,
        onPrimary:        AppColors.onPrimary,
        secondary:        AppColors.primaryLight,
        onSecondary:      AppColors.onPrimary,
        surface:          AppColors.surface,
        onSurface:        AppColors.onBackground,
        error:            AppColors.error,
        onError:          Colors.white,
        outline:          AppColors.border,
        surfaceContainerHighest: AppColors.surfaceAlt,
      ),

      // ── Tipografía ────────────────────────────────────────────────────────
      textTheme: base.copyWith(
        displayLarge:  GoogleFonts.inter(color: AppColors.onBackground, fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.inter(color: AppColors.onBackground, fontWeight: FontWeight.w700),
        headlineLarge: GoogleFonts.inter(color: AppColors.onBackground, fontWeight: FontWeight.w700),
        headlineMedium:GoogleFonts.inter(color: AppColors.onBackground, fontWeight: FontWeight.w600),
        titleLarge:    GoogleFonts.inter(color: AppColors.onBackground, fontWeight: FontWeight.w600),
        titleMedium:   GoogleFonts.inter(color: AppColors.onBackground, fontWeight: FontWeight.w500),
        bodyLarge:     GoogleFonts.inter(color: AppColors.onBackground),
        bodyMedium:    GoogleFonts.inter(color: AppColors.onSurface),
        bodySmall:     GoogleFonts.inter(color: AppColors.onSurfaceDim),
        labelLarge:    GoogleFonts.inter(color: AppColors.onBackground, fontWeight: FontWeight.w600),
        labelMedium:   GoogleFonts.inter(color: AppColors.onSurface,    fontWeight: FontWeight.w500),
        labelSmall:    GoogleFonts.inter(color: AppColors.onSurfaceDim, letterSpacing: 1.1),
      ),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:  AppColors.surface,
        foregroundColor:  AppColors.onBackground,
        elevation:        0,
        scrolledUnderElevation: 0,
        centerTitle:      false,
        titleTextStyle:   GoogleFonts.inter(
          color:      AppColors.onBackground,
          fontSize:   20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.onBackground),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor:           Colors.transparent,
          statusBarIconBrightness:  Brightness.light,
          statusBarBrightness:      Brightness.dark,
        ),
      ),

      // ── ElevatedButton ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:   AppColors.primary,
          foregroundColor:   AppColors.onPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.onSurfaceDim,
          elevation:         0,
          shadowColor:       Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontSize:    15,
            fontWeight:  FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      // ── TextField / Input ─────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: AppColors.surface,
        hintStyle: GoogleFonts.inter(
          color:    AppColors.onSurfaceDim,
          fontSize: 14,
        ),
        prefixIconColor: AppColors.onSurfaceDim,
        suffixIconColor: AppColors.onSurfaceDim,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle:  GoogleFonts.inter(color: AppColors.onSurface),
        floatingLabelStyle: GoogleFonts.inter(color: AppColors.primary),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:        AppColors.surface,
        elevation:    0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:       AppColors.surface,
        selectedColor:         AppColors.primary,
        disabledColor:         AppColors.border,
        labelStyle:            GoogleFonts.inter(color: AppColors.onSurface, fontSize: 13),
        secondaryLabelStyle:   GoogleFonts.inter(color: AppColors.onPrimary, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // ── BottomNavigationBar ───────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      AppColors.surface,
        selectedItemColor:    AppColors.primary,
        unselectedItemColor:  AppColors.onSurfaceDim,
        elevation:            0,
        type:                 BottomNavigationBarType.fixed,
        selectedLabelStyle:   GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
      ),

      // ── NavigationBar (Material 3) ────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:    AppColors.surface,
        indicatorColor:     AppColors.primary.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.onSurfaceDim);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.inter(
            color: AppColors.onSurfaceDim,
            fontSize: 11,
          );
        }),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color:     AppColors.border,
        thickness: 1,
        space:     1,
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor:  AppColors.surfaceAlt,
        contentTextStyle: GoogleFonts.inter(color: AppColors.onBackground),
        actionTextColor:  AppColors.primaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation:       0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: GoogleFonts.inter(
          color:      AppColors.onBackground,
          fontSize:   18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(
          color:   AppColors.onSurface,
          fontSize: 14,
        ),
      ),

      // ── PopupMenu ─────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceAlt,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        textStyle: GoogleFonts.inter(color: AppColors.onBackground, fontSize: 14),
      ),

      // ── ListTile ──────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor:         Colors.transparent,
        iconColor:         AppColors.onSurface,
        textColor:         AppColors.onBackground,
        subtitleTextStyle: GoogleFonts.inter(color: AppColors.onSurface, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
            ? AppColors.onPrimary
            : AppColors.onSurfaceDim,
        ),
        trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.border,
        ),
      ),

      // ── CircularProgressIndicator ─────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:            AppColors.primary,
        linearTrackColor: AppColors.border,
      ),

      // ── FloatingActionButton ──────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation:       0,
        shape: CircleBorder(),
      ),

      // ── IconButton ────────────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.onSurface,
        ),
      ),

      // ── TabBar ────────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor:         AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceDim,
        indicatorColor:     AppColors.primary,
        indicatorSize:      TabBarIndicatorSize.label,
        labelStyle:         GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
        dividerColor:       AppColors.border,
      ),
    );
  }
}
