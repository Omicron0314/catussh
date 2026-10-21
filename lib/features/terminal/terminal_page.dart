// A terminal session page: tabs for the server's terminals, the terminal,
// and a status bar with live figures (TerminalPage.swift).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';

import '../../app/router.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/store.dart';
import '../../core/strings.dart';
import '../../sessions/monitor_session.dart';
import '../../sessions/terminal_session.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../servers/server_actions.dart';
import '../shell/main_view.dart';
import '../shell/sidebar.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key, required this.session});
  final TerminalSession session;

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final _focus = FocusNode();
  bool _wasActive = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _setFontSize(CatusshStore store, int size) {
    store.update((s) => s.terminalFontSize = size.clamp(4, 30));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final session = widget.session;
    final active = ActivePage.of(context);
    if (active && !_wasActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
    _wasActive = active;
    final scheme = Theme.of(context).colorScheme;
    final terminalTheme = resolveTerminalTheme(store.terminalTheme, scheme);
    final saved = session.remoteType == RemoteType.machine ? store.machine(session.machine.id) : null;

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.minus, control: true): () =>
              _setFontSize(store, store.terminalFontSize - 1),
          const SingleActivator(LogicalKeyboardKey.equal, control: true): () =>
              _setFontSize(store, store.terminalFontSize + 1),
          const SingleActivator(LogicalKeyboardKey.equal, control: true, shift: true): () =>
              _setFontSize(store, store.terminalFontSize + 1),
          const SingleActivator(LogicalKeyboardKey.keyT, control: true, shift: true): () => _newTerminal(),
          const SingleActivator(LogicalKeyboardKey.keyW, control: true, shift: true): () =>
              closeTerminalAsking(context, session),
        },
        child: PageScaffold(
          scrollable: false,
          padding: const EdgeInsets.fromLTRB(RX.s6, 0, RX.s6, 0),
          leading: _SessionTabs(current: session, onNew: _newTerminal),
          center: saved == null ? null : ServerToolSwitcher(machine: saved, current: ServerTool.terminal),
          actions: [
            if (session.closed)
              FilledButton.icon(
                onPressed: session.reconnect,
                icon: const Icon(Icons.refresh),
                label: Text(S.l.reconnect),
              ),
            IconButton(
              tooltip: S.l.smallerText,
              onPressed: store.terminalFontSize <= 4 ? null : () => _setFontSize(store, store.terminalFontSize - 1),
              icon: const Icon(Icons.text_decrease),
            ),
            IconButton(
              tooltip: S.l.largerText,
              onPressed: store.terminalFontSize >= 30 ? null : () => _setFontSize(store, store.terminalFontSize + 1),
              icon: const Icon(Icons.text_increase),
            ),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ColoredBox(
                    color: terminalTheme.background,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (session.closed)
                          Container(
                            height: 36,
                            color: Colors.black.withValues(alpha: 0.35),
                            padding: const EdgeInsets.symmetric(horizontal: RX.s3),
                            alignment: Alignment.centerLeft,
                            child: Text(S.l.connectionClosed, style: TextStyle(color: terminalTheme.foreground)),
                          ),
                        Expanded(
                          child: GestureDetector(
                            onSecondaryTapUp: (d) => _contextMenu(context, d.globalPosition),
                            child: TerminalView(
                              session.terminal,
                              controller: session.controller,
                              focusNode: _focus,
                              autofocus: true,
                              theme: terminalTheme,
                              padding: const EdgeInsets.all(10),
                              textStyle: TerminalStyle(
                                fontSize: store.terminalFontSize.toDouble(),
                                fontFamily: store.terminalFontFamily,
                                fontFamilyFallback: RX.monoFallback,
                              ),
                              cursorType: TerminalCursorType.block,
                              keyboardAppearance: scheme.brightness,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _StatusBar(session: session),
            ],
          ),
        ),
      ),
    );
  }

  void _newTerminal() {
    final router = AppRouter.shared;
    final session = widget.session;
    final opened = session.remoteType == RemoteType.machine
        ? router.openTerminal(session.machine)
        : router.openTerminalCommand(session.command!);
    router.route = SessionRoute(ServerTool.terminal, opened.id);
  }

  Future<void> _contextMenu(BuildContext context, Offset position) async {
    final session = widget.session;
    final selection = session.controller.selection;
    await runMenu(context, position, [
      menuItem(S.l.copy, Icons.content_copy, () {
        if (selection != null) {
          Clipboard.setData(ClipboardData(text: session.terminal.buffer.getText(selection)));
        }
      }, enabled: selection != null),
      menuItem(S.l.paste, Icons.content_paste, () async {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (data?.text != null) session.terminal.paste(data!.text!);
      }),
      menuItem(S.l.selectAllText, Icons.select_all, () {
        final buffer = session.terminal.buffer;
        session.controller.setSelection(
          buffer.createAnchor(0, 0),
          buffer.createAnchor(session.terminal.viewWidth, buffer.height - 1),
        );
      }),
      menuItem(S.l.clearScrollback, Icons.clear_all, () {
        session.terminal.buffer.clear();
        session.terminal.buffer.setCursor(0, 0);
        session.terminal.write('\x0c');
      }),
      const PopupMenuDivider(),
      if (session.closed) menuItem(S.l.reconnect, Icons.refresh, session.reconnect),
      menuItem(S.l.closeSession, Icons.close, () => closeTerminalAsking(context, session)),
    ]);
  }
}

class _SessionTabs extends StatelessWidget {
  const _SessionTabs({required this.current, required this.onNew});
  final TerminalSession current;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final router = context.watch<AppRouter>();
    final siblings = current.remoteType == RemoteType.machine
        ? router.terminals.where((t) => t.remoteType == RemoteType.machine && t.machine.id == current.machine.id).toList()
        : [current];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (index, t) in siblings.indexed)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _SessionTab(session: t, selected: t.id == current.id, number: siblings.length > 1 ? index + 1 : null),
              ),
            IconButton(tooltip: S.l.newTerminalShortcut, icon: const Icon(Icons.add, size: 20), onPressed: onNew),
          ],
        ),
      ),
    );
  }
}

class _SessionTab extends StatelessWidget {
  const _SessionTab({required this.session, required this.selected, this.number});
  final TerminalSession session;
  final bool selected;
  final int? number;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = session.navigationSubtitle.isNotEmpty
        ? session.navigationSubtitle
        : (number != null
            ? S.l.terminalTab(number!)
            : (session.remoteType == RemoteType.machine ? S.l.toolTerminal : session.displayName));
    return Hoverable(
      builder: (context, hovered) => GestureDetector(
        onSecondaryTapUp: (d) => runMenu(context, d.globalPosition, [
          if (session.closed) menuItem(S.l.reconnect, Icons.refresh, session.reconnect),
          menuItem(S.l.closeSession, Icons.close, () => closeTerminalAsking(context, session)),
        ]),
        child: Material(
          color: selected ? scheme.secondaryContainer : (hovered ? scheme.surfaceContainerHighest : Colors.transparent),
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => AppRouter.shared.route = SessionRoute(ServerTool.terminal, session.id),
            child: Padding(
              padding: const EdgeInsets.only(left: 14, right: 4),
              child: SizedBox(
                height: 36,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (session.closed) ...[
                      Icon(Icons.link_off, size: 14, color: scheme.error),
                      const SizedBox(width: 6),
                    ],
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
                          )),
                    ),
                    AnimatedOpacity(
                      opacity: selected || hovered ? 1 : 0,
                      duration: const Duration(milliseconds: 120),
                      child: IconButton(
                        tooltip: S.l.closeTitle(session.navigationTitle),
                        iconSize: 14,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close),
                        onPressed: () => closeTerminalAsking(context, session),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.session});
  final TerminalSession session;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final router = context.watch<AppRouter>();
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final endpoint = session.command?.command ??
        session.machine.getCommand(store.usernameFor(session.machine), insertLeadingSSH: false);
    final monitor = router.monitorForMachine(session.machine.id);
    return SizedBox(
      height: 34,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: RX.s1),
        child: Row(
          children: [
            Expanded(
              child: RedactableText(endpoint,
                  redacted: store.machineRedacted != RedactedLevel.none, style: RX.code(context, size: 11, color: style?.color)),
            ),
            if (monitor != null)
              ListenableBuilder(
                listenable: monitor,
                builder: (context, _) {
                  if (monitor.phase is! MonitorConnected || !monitor.status.hasData) return const SizedBox();
                  final s = monitor.status;
                  return Text(
                    S.l.liveFigures(
                      RXFormat.percent(s.processor.summary.sumUsed),
                      RXFormat.percent(s.memoryUsedPercent),
                      RXFormat.rateString(s.totalReceivePerSecond.toDouble()),
                      RXFormat.rateString(s.totalTransmitPerSecond.toDouble()),
                    ),
                    style: style,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
