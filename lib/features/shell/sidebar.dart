// Home · Manage · Sessions, with Settings pinned to the bottom (SidebarView).
// One row per server with open sessions; small icons show which tools are
// open, and its context menu closes them.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/models.dart';
import '../../core/store.dart';
import '../../sessions/terminal_session.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key, required this.onHide});
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final router = context.watch<AppRouter>();
    final store = context.watch<CatusshStore>();
    final theme = Theme.of(context);
    final route = router.route;
    final selectedOwner = route.isSession ? router.ownerOf(route) : null;

    Widget place(Place p, String title, IconData icon, IconData selectedIcon, {int badge = 0}) {
      return _SidebarRow(
        selected: route == PlaceRoute(p),
        icon: icon,
        selectedIcon: selectedIcon,
        title: Text(title),
        badge: badge,
        onTap: () => router.go(p),
      );
    }

    final owners = router.openOwners;
    return SizedBox(
      width: RX.sidebarWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Image.asset('assets/icon/catussh.png', width: 28, height: 28),
                const SizedBox(width: 10),
                Text('catussh', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  tooltip: 'Hide Sidebar (Ctrl+\\)',
                  icon: const Icon(Icons.view_sidebar_outlined, size: 20),
                  onPressed: onHide,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                place(Place.home, 'Home', Icons.home_outlined, Icons.home),
                const _SidebarHeader('Manage'),
                place(Place.servers, 'Servers', Icons.dns_outlined, Icons.dns, badge: store.machines.length),
                place(Place.identities, 'Identities', Icons.badge_outlined, Icons.badge, badge: store.identities.length),
                place(Place.snippets, 'Snippets', Icons.code, Icons.code, badge: store.snippets.length),
                place(Place.portForward, 'Port Forward', Icons.swap_horiz, Icons.swap_horiz,
                    badge: store.portForwards.length),
                if (owners.isNotEmpty) ...[
                  const _SidebarHeader('Sessions'),
                  for (final owner in owners)
                    _OwnerRow(owner: owner, selected: owner == selectedOwner),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: Tooltip(
              message: 'Settings (Ctrl+,)',
              child: place(Place.settings, 'Settings', Icons.settings_outlined, Icons.settings),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 8, 6),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// A Material 3 navigation-drawer style row: a pill in secondaryContainer
/// when selected.
class _SidebarRow extends StatelessWidget {
  const _SidebarRow({
    required this.selected,
    required this.icon,
    required this.title,
    required this.onTap,
    this.selectedIcon,
    this.badge = 0,
    this.trailing,
    this.onSecondaryTap,
  });

  final bool selected;
  final IconData icon;
  final IconData? selectedIcon;
  final Widget title;
  final int badge;
  final Widget? trailing;
  final VoidCallback onTap;
  final void Function(Offset position)? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onSecondaryTapUp: onSecondaryTap == null ? null : (d) => onSecondaryTap!(d.globalPosition),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(selected ? (selectedIcon ?? icon) : icon, size: 22, color: fg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DefaultTextStyle(
                      style: text.labelLarge!.copyWith(
                        color: selected ? scheme.onSecondaryContainer : scheme.onSurface,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: title,
                    ),
                  ),
                  ?trailing,
                  if (badge > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('$badge', style: text.labelMedium?.copyWith(color: fg)),
                    ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerRow extends StatelessWidget {
  const _OwnerRow({required this.owner, required this.selected});
  final SessionOwner owner;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final router = context.watch<AppRouter>();
    final store = context.watch<CatusshStore>();
    final scheme = Theme.of(context).colorScheme;
    final routes = router.routesOf(owner);

    final String title;
    final IconData icon;
    switch (owner) {
      case ServerOwner(:final machineId):
        title = store.machine(machineId)?.name ?? _sessionMachineName(router, machineId);
        icon = Icons.dns_outlined;
      case CommandOwner(:final terminalId):
        title = router.terminals.where((t) => t.id == terminalId).firstOrNull?.displayName ?? 'Terminal';
        icon = Icons.terminal;
    }
    final openTools = ServerTool.values.where((tool) => routes.any((r) => r.tool == tool)).toList();

    return Tooltip(
      message: '${openTools.map((t) => t.title).join(', ')} open',
      waitDuration: const Duration(seconds: 1),
      child: _SidebarRow(
        selected: selected,
        icon: icon,
        title: RedactableText(title, redacted: store.machineRedacted == RedactedLevel.all),
        trailing: owner is ServerOwner
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final tool in openTools)
                    Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Icon(tool.icon, size: 14, color: scheme.onSurfaceVariant),
                    ),
                ],
              )
            : null,
        onTap: () => router.showOwner(owner),
        onSecondaryTap: (position) => _menu(context, router, routes, title, position),
      ),
    );
  }

  String _sessionMachineName(AppRouter router, String machineId) {
    for (final t in router.transfers) {
      if (t.machine.id == machineId) return t.machine.name;
    }
    for (final m in router.monitors) {
      if (m.machine.id == machineId) return m.machine.name;
    }
    return 'Server';
  }

  Future<void> _menu(
    BuildContext context,
    AppRouter router,
    List<SessionRoute> routes,
    String title,
    Offset position,
  ) async {
    final items = <PopupMenuEntry<VoidCallback>>[];
    for (final r in routes) {
      switch (r.tool) {
        case ServerTool.terminal:
          final t = router.terminals.where((t) => t.id == r.id).firstOrNull;
          if (t == null) continue;
          if (t.closed) items.add(menuItem('Reconnect Terminal', Icons.refresh, t.reconnect));
          items.add(menuItem('Close Terminal', Icons.close, () => closeTerminalAsking(context, t)));
        case ServerTool.files:
          items.add(menuItem('Close Files', Icons.close, () => router.closeRoute(r)));
        case ServerTool.editor:
          items.add(menuItem('Close Editor', Icons.close, () async {
            final workspace = router.editorFor(r.id);
            if (workspace != null && workspace.hasUnsavedChanges) {
              final ok = await requiresConfirmation(
                context,
                message: 'Close the editor on $title?',
                informative: 'Unsaved changes are lost.',
                confirmTitle: 'Discard Changes and Close',
                destructive: true,
                always: true,
              );
              if (!ok) return;
            }
            router.closeRoute(r);
          }));
        case ServerTool.monitor:
          items.add(menuItem('Close Monitor', Icons.close, () => router.closeRoute(r)));
      }
    }
    if (routes.length > 1) {
      items.add(const PopupMenuDivider());
      items.add(menuItem('Close All', Icons.clear_all, () async {
        final unsaved = routes.any((r) => r.tool == ServerTool.editor && (router.editorFor(r.id)?.hasUnsavedChanges ?? false));
        final ok = await requiresConfirmation(
          context,
          message: 'Close everything open on $title?',
          informative: unsaved ? 'Unsaved changes in the editor will be lost.' : null,
          confirmTitle: unsaved ? 'Discard Changes and Close' : 'Close All',
          destructive: true,
          always: unsaved,
        );
        if (ok) router.closeAll(owner);
      }, destructive: true, context: context));
    }
    await runMenu(context, position, items);
  }
}

Future<void> closeTerminalAsking(BuildContext context, TerminalSession session) async {
  if (!session.closed) {
    final ok = await requiresConfirmation(
      context,
      message: 'Close the session on ${session.displayName}?',
      confirmTitle: 'Close Session',
      destructive: true,
    );
    if (!ok) return;
  }
  AppRouter.shared.closeTerminal(session);
}
