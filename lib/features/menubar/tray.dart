// "Show in Tray": the running cat of the Swift app's menu bar, as a system
// tray icon (StatusNotifierItem on Linux). One icon per server; the cat runs
// faster as CPU use rises, its tooltip shows CPU, memory and network, and its
// menu opens the server's tools. Without a tray host it is unavailable.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:window_manager/window_manager.dart';

import '../../core/strings.dart';
import '../../app/router.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../sessions/monitor_session.dart';

/// Seconds per frame, as CatSpeed in the Swift app; null stops the cat.
double? catFrameInterval(MonitorSession session) {
  if (session.phase is! MonitorConnected || !session.status.hasData) return null;
  final cpu = session.status.processor.summary.sumUsed;
  if (cpu < 5) return 1;
  if (cpu < 20) return 0.5;
  if (cpu < 50) return 0.25;
  if (cpu < 80) return 0.1;
  return 0.05;
}

class TrayController {
  TrayController._();
  static final TrayController instance = TrayController._();

  AppRouter? _router;
  final Map<String, _TrayCat> _cats = {};

  bool get available {
    if (!(Platform.isLinux || Platform.isWindows || Platform.isMacOS)) return false;
    try {
      return tray.TrayManager.instance.isSupported();
    } catch (_) {
      return false;
    }
  }

  void attach(AppRouter router) => _router = router;

  bool isShowing(String machineId) => _cats.containsKey(machineId);

  void show(Machine machine) {
    final router = _router;
    if (router == null || !available || _cats.containsKey(machine.id)) return;
    final session = router.beginMonitor(machine);
    try {
      _cats[machine.id] = _TrayCat(machine, session, router, onClose: () => removeIfShowing(machine.id));
    } catch (error) {
      debugPrint('tray icon could not be created: $error');
    }
  }

  void removeIfShowing(String machineId) {
    _cats.remove(machineId)?.dispose();
  }
}

class _TrayCat {
  _TrayCat(this.machine, this.session, this.router, {required this.onClose}) {
    final icon = tray.TrayIcon.create();
    if (icon == null) throw StateError('no tray icon');
    _icon = icon;
    _images = [for (var i = 0; i < 5; i++) tray.ImageAsset.fromAsset('assets/cat/cat${i}_light.png')];
    _broken = tray.ImageAsset.fromAsset('assets/cat/cat_crash_light.png');
    _icon.icon = _broken ?? _images.first;
    _icon.setVisible(true);
    _icon.setContextMenuTrigger(tray.ContextMenuTrigger.rightClicked);
    _icon.addListener((event) {
      if (event is tray.TrayIconClickedEvent) _focus(ServerTool.monitor);
    });
    _buildMenu();
    session.addListener(_refresh);
    _refresh();
  }

  final Machine machine;
  final MonitorSession session;
  final AppRouter router;
  final VoidCallback onClose;
  late final tray.TrayIcon _icon;
  late final List<tray.Image?> _images;
  tray.Image? _broken;
  tray.Menu? _menu;
  final List<tray.MenuItem> _items = [];
  Timer? _timer;
  double? _interval;
  int _frame = 0;

  Future<void> _focus(ServerTool tool) async {
    router.show(tool, machine);
    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (_) {}
  }

  void _buildMenu() {
    final menu = tray.Menu.create();
    if (menu == null) return;
    tray.MenuItem? add(String label, VoidCallback action) {
      final item = tray.MenuItem.createWithLabelAndType(label, tray.MenuItemType.normal);
      if (item == null) return null;
      item.addListener((event) {
        if (event is tray.MenuItemClickedEvent) action();
      });
      menu.addItem(item);
      _items.add(item);
      return item;
    }

    add(machine.name, () => _focus(ServerTool.monitor))?.isEnabled = false;
    menu.addSeparator();
    add(S.l.openTerminal, () => _focus(ServerTool.terminal));
    add(S.l.openFiles, () => _focus(ServerTool.files));
    add(S.l.openMonitor, () => _focus(ServerTool.monitor));
    menu.addSeparator();
    add(S.l.removeFromTray, onClose);
    _icon.setContextMenu(menu);
    _menu = menu;
  }

  void _refresh() {
    final interval = catFrameInterval(session);
    if (interval != _interval) {
      _interval = interval;
      _timer?.cancel();
      _timer = null;
      if (interval == null) {
        _icon.icon = _broken;
      } else {
        _timer = Timer.periodic(Duration(milliseconds: (interval * 1000).round()), (_) {
          _frame = (_frame + 1) % _images.length;
          _icon.icon = _images[_frame];
        });
      }
    }
    final s = session.status;
    final tooltip = session.phase is MonitorConnected && s.hasData
        ? '${machine.name}\n'
            '${S.l.trayTooltipFigures(RXFormat.percent(s.processor.summary.sumUsed), RXFormat.percent(s.memoryUsedPercent))}\n'
            '${S.l.trayTooltipRates(RXFormat.rateString(s.totalTransmitPerSecond.toDouble()), RXFormat.rateString(s.totalReceivePerSecond.toDouble()))}'
        : '${machine.name}\n${session.phase is MonitorFailed ? S.l.cannotConnect : S.l.connecting}';
    _icon.setTooltip(tooltip);
  }

  void dispose() {
    session.removeListener(_refresh);
    _timer?.cancel();
    _icon.setVisible(false);
    _icon.setContextMenu(null);
    for (final item in _items) {
      item.dispose();
    }
    _menu?.dispose();
    _icon.dispose();
  }
}
