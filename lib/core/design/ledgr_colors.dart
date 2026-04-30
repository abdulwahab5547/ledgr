import 'package:flutter/material.dart';

/// Design tokens — Ledgr design system.
/// Source of truth for every color in the app. Mirrors `LEDGR` in the design
/// bundle (project/screens/shared.jsx).
class LedgrColors {
  const LedgrColors._();

  // base
  static const Color bg = Color(0xFF0A0B0D);
  static const Color bg2 = Color(0xFF101115);
  static const Color rootBg = Color(0xFF050507);
  static const Color surface = Color(0x0AFFFFFF); // rgba(255,255,255,0.04)
  static const Color surfaceHi = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const Color hairline = Color(0x12FFFFFF); // rgba(255,255,255,0.07)
  static const Color hairline2 = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)

  // text
  static const Color text = Color(0xFFF4F4EC);
  static const Color textDim = Color(0x9EF4F4EC); // 0.62
  static const Color textMute = Color(0x61F4F4EC); // 0.38
  static const Color textFaint = Color(0x38F4F4EC); // 0.22

  // accent
  static const Color lime = Color(0xFFC9FF5E);
  static const Color limeDeep = Color(0xFFA8E03E);
  static const Color limeGlow = Color(0x29C9FF5E); // 0.16

  // semantic
  static const Color pos = Color(0xFF9BE36A); // lent / incoming
  static const Color neg = Color(0xFFFF8A6E); // borrowed / outgoing
  static const Color posBg = Color(0x1A9BE36A); // 0.10
  static const Color negBg = Color(0x1AFF8A6E); // 0.10

  // tints used by account icon chips
  static const Color tintBlue = Color(0xFF5B7CFF);
  static const Color tintViolet = Color(0xFF7E5BFF);
  static const Color tintTeal = Color(0xFF5EEAD4);
  static const Color tintAmber = Color(0xFFE8A87C);
}
