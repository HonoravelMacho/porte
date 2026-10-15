import 'package:flutter/material.dart';

/// Paleta oficial PORTE — HUD Sci-Fi / Skeuomorphic tátil.
/// Ciano = energia/sistema · Âmbar = alerta/ação · Fundo = casco espacial.
abstract final class PorteColors {
  static const abyss = Color(0xFF05090F); // fundo base
  static const hull = Color(0xFF0B1220); // painéis
  static const hullLight = Color(0xFF131E33);
  static const grid = Color(0xFF1B2947);

  static const cyanNeon = Color(0xFF22E6FF);
  static const cyanDim = Color(0xFF0E7F99);
  static const amberNeon = Color(0xFFFFB020);
  static const amberDim = Color(0xFF8A5A00);

  static const textMain = Color(0xFFD9F6FF);
  static const textDim = Color(0xFF7D93B2);

  static const danger = Color(0xFFFF4D5E);
  static const ok = Color(0xFF3DFFA2);

  static const scanline = Color(0x0AFFFFFF);
}
