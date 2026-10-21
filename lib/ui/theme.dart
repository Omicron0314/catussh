// Material You: the color scheme comes from the desktop accent (via
// dynamic_color: XDG portal / GTK theme on Linux, wallpaper on Android 12+),
// or from catussh's indigo accent when that is off or unavailable.

import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

class RX {
  // Spacing, as RX.Space in CatusshDesign.
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;

  static const sidebarWidth = 232.0;
  static const tableRowHeight = 44.0;

  /// catussh's accent, the seed when the desktop gives none.
  static const accent = Color(0xFF4B49C8);

  static const mono = 'monospace';
  static const monoFallback = ['DejaVu Sans Mono', 'Liberation Mono', 'Noto Sans Mono', 'Noto Color Emoji'];

  static TextStyle code(BuildContext context, {double? size, Color? color, FontWeight? weight}) =>
      TextStyle(
        fontFamily: mono,
        fontFamilyFallback: monoFallback,
        fontSize: size ?? 13,
        color: color,
        fontWeight: weight,
      );
}

ThemeData buildTheme(ColorScheme scheme) {
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
  );
  // Arrows (↑↓→) and CJK names from servers render even where the UI font
  // lacks them.
  const fallback = ['Noto Sans CJK SC', 'Noto Sans', 'DejaVu Sans', 'Noto Color Emoji'];
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamilyFallback: fallback),
    scaffoldBackgroundColor: scheme.surfaceContainerLow,
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(backgroundColor: scheme.surfaceContainerHigh),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    tooltipTheme: const TooltipThemeData(waitDuration: Duration(milliseconds: 600)),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.6), space: 1),
    listTileTheme: const ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(visualDensity: VisualDensity.compact, textStyle: WidgetStatePropertyAll(base.textTheme.labelMedium)),
    ),
  );
}

/// Colors beyond the scheme, matched to the Swift palette's roles.
extension RXColors on ColorScheme {
  /// The second chart series (Swift: rxSeries2, a sky blue), harmonized.
  Color get series2 => brightness == Brightness.dark ? const Color(0xFF6CBCF2) : const Color(0xFF3B94D6);
  Color get success => brightness == Brightness.dark ? const Color(0xFF34D158) : const Color(0xFF24A148);
  Color get warning => brightness == Brightness.dark ? const Color(0xFFFFB340) : const Color(0xFFA86400);
}

// MARK: - Terminal colors

class TerminalThemeChoice {
  const TerminalThemeChoice(this.id, this.title, this.theme);
  final String id;
  final String title;
  final TerminalTheme theme;
}

TerminalTheme _t({
  required int bg,
  required int fg,
  required int cursor,
  required int selection,
  required List<int> ansi,
}) =>
    TerminalTheme(
      cursor: Color(cursor),
      selection: Color(selection),
      foreground: Color(fg),
      background: Color(bg),
      black: Color(ansi[0]),
      red: Color(ansi[1]),
      green: Color(ansi[2]),
      yellow: Color(ansi[3]),
      blue: Color(ansi[4]),
      magenta: Color(ansi[5]),
      cyan: Color(ansi[6]),
      white: Color(ansi[7]),
      brightBlack: Color(ansi[8]),
      brightRed: Color(ansi[9]),
      brightGreen: Color(ansi[10]),
      brightYellow: Color(ansi[11]),
      brightBlue: Color(ansi[12]),
      brightMagenta: Color(ansi[13]),
      brightCyan: Color(ansi[14]),
      brightWhite: Color(ansi[15]),
      searchHitBackground: const Color(0xFFFFDF5D),
      searchHitBackgroundCurrent: const Color(0xFFFF9632),
      searchHitForeground: const Color(0xFF000000),
    );

/// A handful of well-known themes. Ghostty's 600-theme gallery is not
/// available here; these cover the common choices.
final terminalThemes = <TerminalThemeChoice>[
  // The Swift app's terminal tokens (rxTerminalBackground and friends).
  TerminalThemeChoice('catussh', 'catussh', _t(
    bg: 0xFF121316, fg: 0xFFE6E7EA, cursor: 0xFFE6E7EA, selection: 0x664B49C8,
    ansi: [0xFF1D1E22, 0xFFFF7B72, 0xFF5FD383, 0xFFE8C26A, 0xFF7CB7FF, 0xFFC4A7FF, 0xFF6CD6E0, 0xFFE6E7EA,
           0xFF8B8E96, 0xFFFF9A93, 0xFF86E4A4, 0xFFF2D68E, 0xFFA3CDFF, 0xFFD8C4FF, 0xFF95E6EE, 0xFFFFFFFF],
  )),
  TerminalThemeChoice('tokyo-night', 'Tokyo Night', _t(
    bg: 0xFF1A1B26, fg: 0xFFC0CAF5, cursor: 0xFFC0CAF5, selection: 0x6633467C,
    ansi: [0xFF15161E, 0xFFF7768E, 0xFF9ECE6A, 0xFFE0AF68, 0xFF7AA2F7, 0xFFBB9AF7, 0xFF7DCFFF, 0xFFA9B1D6,
           0xFF414868, 0xFFF7768E, 0xFF9ECE6A, 0xFFE0AF68, 0xFF7AA2F7, 0xFFBB9AF7, 0xFF7DCFFF, 0xFFC0CAF5],
  )),
  TerminalThemeChoice('catppuccin-mocha', 'Catppuccin Mocha', _t(
    bg: 0xFF1E1E2E, fg: 0xFFCDD6F4, cursor: 0xFFF5E0DC, selection: 0x66585B70,
    ansi: [0xFF45475A, 0xFFF38BA8, 0xFFA6E3A1, 0xFFF9E2AF, 0xFF89B4FA, 0xFFF5C2E7, 0xFF94E2D5, 0xFFBAC2DE,
           0xFF585B70, 0xFFF38BA8, 0xFFA6E3A1, 0xFFF9E2AF, 0xFF89B4FA, 0xFFF5C2E7, 0xFF94E2D5, 0xFFA6ADC8],
  )),
  TerminalThemeChoice('catppuccin-latte', 'Catppuccin Latte', _t(
    bg: 0xFFEFF1F5, fg: 0xFF4C4F69, cursor: 0xFFDC8A78, selection: 0x66ACB0BE,
    ansi: [0xFF5C5F77, 0xFFD20F39, 0xFF40A02B, 0xFFDF8E1D, 0xFF1E66F5, 0xFFEA76CB, 0xFF179299, 0xFFACB0BE,
           0xFF6C6F85, 0xFFD20F39, 0xFF40A02B, 0xFFDF8E1D, 0xFF1E66F5, 0xFFEA76CB, 0xFF179299, 0xFFBCC0CC],
  )),
  TerminalThemeChoice('dracula', 'Dracula', _t(
    bg: 0xFF282A36, fg: 0xFFF8F8F2, cursor: 0xFFF8F8F2, selection: 0x6644475A,
    ansi: [0xFF21222C, 0xFFFF5555, 0xFF50FA7B, 0xFFF1FA8C, 0xFFBD93F9, 0xFFFF79C6, 0xFF8BE9FD, 0xFFF8F8F2,
           0xFF6272A4, 0xFFFF6E6E, 0xFF69FF94, 0xFFFFFFA5, 0xFFD6ACFF, 0xFFFF92DF, 0xFFA4FFFF, 0xFFFFFFFF],
  )),
  TerminalThemeChoice('gruvbox-dark', 'Gruvbox Dark', _t(
    bg: 0xFF282828, fg: 0xFFEBDBB2, cursor: 0xFFEBDBB2, selection: 0x66504945,
    ansi: [0xFF282828, 0xFFCC241D, 0xFF98971A, 0xFFD79921, 0xFF458588, 0xFFB16286, 0xFF689D6A, 0xFFA89984,
           0xFF928374, 0xFFFB4934, 0xFFB8BB26, 0xFFFABD2F, 0xFF83A598, 0xFFD3869B, 0xFF8EC07C, 0xFFEBDBB2],
  )),
  TerminalThemeChoice('solarized-dark', 'Solarized Dark', _t(
    bg: 0xFF002B36, fg: 0xFF839496, cursor: 0xFF93A1A1, selection: 0x66073642,
    ansi: [0xFF073642, 0xFFDC322F, 0xFF859900, 0xFFB58900, 0xFF268BD2, 0xFFD33682, 0xFF2AA198, 0xFFEEE8D5,
           0xFF002B36, 0xFFCB4B16, 0xFF586E75, 0xFF657B83, 0xFF839496, 0xFF6C71C4, 0xFF93A1A1, 0xFFFDF6E3],
  )),
  TerminalThemeChoice('github-light', 'GitHub Light', _t(
    bg: 0xFFFFFFFF, fg: 0xFF24292F, cursor: 0xFF0969DA, selection: 0x4454AEFF,
    ansi: [0xFF24292F, 0xFFCF222E, 0xFF116329, 0xFF4D2D00, 0xFF0969DA, 0xFF8250DF, 0xFF1B7C83, 0xFF6E7781,
           0xFF57606A, 0xFFA40E26, 0xFF1A7F37, 0xFF633C01, 0xFF218BFF, 0xFFA475F9, 0xFF3192AA, 0xFF8C959F],
  )),
];

TerminalThemeChoice terminalThemeFor(String id) =>
    terminalThemes.firstWhere((t) => t.id == id, orElse: () => terminalThemes.first);

/// "Material You" terminal: background and accents from the app's scheme.
TerminalTheme materialTerminalTheme(ColorScheme scheme) {
  final base = terminalThemes.first.theme;
  final dark = scheme.brightness == Brightness.dark;
  return TerminalTheme(
    cursor: scheme.primary,
    selection: scheme.primary.withValues(alpha: 0.35),
    foreground: scheme.onSurface,
    background: dark ? scheme.surfaceContainerLowest : scheme.surfaceContainerLowest,
    black: dark ? base.black : const Color(0xFF3B3B3B),
    red: scheme.error,
    green: dark ? base.green : const Color(0xFF1A7F37),
    yellow: dark ? base.yellow : const Color(0xFF8A6100),
    blue: scheme.primary,
    magenta: scheme.tertiary,
    cyan: scheme.secondary,
    white: dark ? base.white : const Color(0xFF6E7781),
    brightBlack: scheme.outline,
    brightRed: scheme.error,
    brightGreen: dark ? base.brightGreen : const Color(0xFF1A7F37),
    brightYellow: dark ? base.brightYellow : const Color(0xFF8A6100),
    brightBlue: scheme.primary,
    brightMagenta: scheme.tertiary,
    brightCyan: scheme.secondary,
    brightWhite: scheme.onSurface,
    searchHitBackground: scheme.tertiaryContainer,
    searchHitBackgroundCurrent: scheme.primaryContainer,
    searchHitForeground: scheme.onPrimaryContainer,
  );
}

TerminalTheme resolveTerminalTheme(String id, ColorScheme scheme) =>
    id == 'material' ? materialTerminalTheme(scheme) : terminalThemeFor(id).theme;
