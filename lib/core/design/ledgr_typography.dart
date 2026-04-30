import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ledgr_colors.dart';

/// Typography — three families:
/// - serif (Instrument Serif) for hero numbers and editorial headings
/// - sans (Inter Tight) for body
/// - mono (JetBrains Mono) for technical / tabular numerics
class LedgrType {
  const LedgrType._();

  static TextStyle serif({
    double fontSize = 26,
    double? height,
    FontWeight fontWeight = FontWeight.w400,
    FontStyle fontStyle = FontStyle.normal,
    Color color = LedgrColors.text,
    double letterSpacing = -0.5,
  }) =>
      GoogleFonts.instrumentSerif(
        fontSize: fontSize,
        height: height == null ? null : height / fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle sans({
    double fontSize = 14,
    double? height,
    FontWeight fontWeight = FontWeight.w400,
    Color color = LedgrColors.text,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.interTight(
        fontSize: fontSize,
        height: height == null ? null : height / fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w500,
    Color color = LedgrColors.text,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // Common presets — keep call sites short and consistent.
  static TextStyle heroSerif({Color color = LedgrColors.text}) => serif(
        fontSize: 52,
        height: 52,
        letterSpacing: -1.5,
        color: color,
      );

  static TextStyle headlineSerif({Color color = LedgrColors.text}) => serif(
        fontSize: 26,
        height: 30,
        color: color,
      );

  /// Editorial italic used in screen titles ("Good evening,", "Net", "Settle with")
  static TextStyle editorialItalic({Color color = LedgrColors.textDim}) =>
      serif(
        fontSize: 26,
        height: 30,
        fontStyle: FontStyle.italic,
        color: color,
      );

  /// All-caps small label e.g. "TRUE LIQUIDITY", "ASSETS", section labels
  static TextStyle eyebrow({
    Color color = LedgrColors.textDim,
    double fontSize = 11,
    double letterSpacing = 1.2,
  }) =>
      sans(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle bodySmall({Color color = LedgrColors.textDim}) =>
      sans(fontSize: 12, color: color);

  static TextStyle listTitle({Color color = LedgrColors.text}) => sans(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: -0.1,
      );

  static TextStyle amountMono({Color color = LedgrColors.text}) =>
      mono(fontSize: 13.5, color: color);
}
