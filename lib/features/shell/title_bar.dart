// The window's own title bar, since the GTK one is turned off: a draggable
// strip with the sidebar toggle at the leading edge and minimize, maximize and
// close at the trailing edge (drawn in the app's colors, on every desktop).

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/strings.dart';
import 'sidebar_toggle.dart';

class TitleBar extends StatefulWidget {
  const TitleBar({super.key, required this.sidebarVisible, required this.onToggleSidebar});

  final bool sidebarVisible;
  final VoidCallback onToggleSidebar;

  static const height = 40.0;

  @override
  State<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<TitleBar> with WindowListener {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    // The plugin is absent in widget tests and on platforms without a window.
    windowManager.isMaximized().then((v) {
      if (mounted) setState(() => _maximized = v);
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  Future<void> _toggleMaximize() async {
    try {
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    } catch (_) {}
  }

  void _guard(Future<void> Function() action) {
    action().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: TitleBar.height,
      child: Row(
        children: [
          // Empty space drags the window; a double click maximizes, as on
          // every desktop.
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => _guard(windowManager.startDragging),
              onDoubleTap: _toggleMaximize,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  children: [
                    SidebarToggle(visible: widget.sidebarVisible, onPressed: widget.onToggleSidebar),
                    const SizedBox(width: 4),
                    Text('catussh', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
          _WindowButton(
            tooltip: S.l.minimizeWindow,
            icon: Icons.remove,
            onPressed: () => _guard(windowManager.minimize),
          ),
          _WindowButton(
            tooltip: _maximized ? S.l.restoreWindow : S.l.maximizeWindow,
            icon: _maximized ? Icons.filter_none : Icons.crop_square,
            iconSize: 15,
            onPressed: _toggleMaximize,
          ),
          _WindowButton(
            tooltip: S.l.closeWindow,
            icon: Icons.close,
            close: true,
            onPressed: () => _guard(windowManager.close),
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.close = false,
    this.iconSize = 17,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool close;
  final double iconSize;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = !_hovered
        ? Colors.transparent
        : widget.close
            ? scheme.error
            : scheme.onSurface.withValues(alpha: 0.08);
    final foreground = _hovered && widget.close ? scheme.onError : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Tooltip(
        message: widget.tooltip,
        waitDuration: const Duration(milliseconds: 600),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 40,
              decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
              child: Icon(widget.icon, size: widget.iconSize, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
