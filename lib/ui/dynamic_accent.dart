// The platform's dynamic color, as a seed. Linux: the XDG portal's
// accent-color (or the GTK theme's selection color); Android 12+: the
// wallpaper palette's primary. Read through dynamic_color's plugin, which
// hands back plain colors; schemes are then built with Flutter's own
// ColorScheme.fromSeed.

import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

class DynamicAccent {
  static final ValueNotifier<Color?> seed = ValueNotifier(null);

  static Future<void> load() async {
    try {
      if (Platform.isAndroid) {
        final palette = await DynamicColorPlugin.getCorePalette();
        if (palette != null) seed.value = Color(palette.primary.get(40));
        return;
      }
      final accent = await DynamicColorPlugin.getAccentColor();
      if (accent != null) seed.value = Color(accent.toARGB32());
    } catch (_) {
      seed.value = null;
    }
  }
}
