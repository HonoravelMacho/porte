import 'package:flutter/material.dart';
import 'porte_colors.dart';
import 'chamfered.dart';

/// Tema exclusivo PORTE: substitui o Material plano por HUD translúcido,
/// neon ciano/âmbar, chanfros e textura tátil (gradientes + scanlines via decor).
ThemeData buildPorteTheme() {
  const chamfer = ChamferedBorder(
    chamfer: 12,
    side: BorderSide(color: PorteColors.cyanDim, width: 1.2),
  );
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: PorteColors.abyss,
    colorScheme: const ColorScheme.dark(
      primary: PorteColors.cyanNeon,
      secondary: PorteColors.amberNeon,
      surface: PorteColors.hull,
      error: PorteColors.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: PorteColors.textMain,
      titleTextStyle: TextStyle(
        color: PorteColors.cyanNeon,
        fontSize: 17,
        letterSpacing: 2.2,
        fontWeight: FontWeight.w700,
        fontFamily: 'monospace',
      ),
    ),
    cardTheme: CardThemeData(
      color: PorteColors.hull.withValues(alpha: 0.82),
      margin: const EdgeInsets.all(8),
      shape: chamfer,
      elevation: 6,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: PorteColors.cyanNeon,
      textColor: PorteColors.textMain,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: PorteColors.hull,
      shape: chamfer,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: PorteColors.hull,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: PorteColors.hullLight,
      contentTextStyle: TextStyle(color: PorteColors.textMain, fontFamily: 'monospace'),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: PorteColors.textMain,
      displayColor: PorteColors.textMain,
      fontFamily: 'monospace',
    ),
  );
}

/// Decoração padrão de painel HUD: gradiente metálico + borda neon + sombra.
BoxDecoration hudDecoration({Color edge = PorteColors.cyanDim, bool amber = false}) {
  final e = amber ? PorteColors.amberDim : edge;
  return BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xE6142138), Color(0xE60B1220)],
    ),
    border: Border.all(color: e, width: 1.2),
    boxShadow: [
      BoxShadow(color: e.withValues(alpha: 0.35), blurRadius: 14, spreadRadius: -4),
      const BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
    ],
  );
}
