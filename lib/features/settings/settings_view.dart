// Settings: the app sections of SettingsView.swift, plus the terminal's
// text and colors (which the Swift app took from its Ghostty configuration
// editor).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xterm/xterm.dart';

import '../../app/router.dart';
import '../../core/store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'agreement.dart';

const _categories = [
  ('general', 'General', Icons.tune),
  ('terminal', 'Terminal', Icons.terminal),
  ('connection', 'Connection', Icons.lan_outlined),
  ('about', 'About', Icons.info_outline),
];

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final router = context.watch<AppRouter>();
    final category = router.settingsCategory;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 220,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(RX.s3, 72, RX.s3, RX.s3),
            child: Column(children: [
              for (final (id, title, icon) in _categories)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: ListTile(
                    selected: id == category,
                    selectedTileColor: scheme.secondaryContainer,
                    selectedColor: scheme.onSecondaryContainer,
                    shape: const StadiumBorder(),
                    leading: Icon(icon),
                    title: Text(title),
                    onTap: () {
                      router.settingsCategory = id;
                      router.go(Place.settings);
                    },
                  ),
                ),
            ]),
          ),
        ),
        Expanded(
          child: PageScaffold(
            title: _categories.firstWhere((c) => c.$1 == category, orElse: () => _categories.first).$2,
            body: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: switch (category) {
                'terminal' => const _TerminalSettings(),
                'connection' => const _ConnectionSettings(),
                'about' => const _AboutSettings(),
                _ => const _GeneralSettings(),
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: RX.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: RX.s2),
            child: Text(title, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
          ),
          Card(
            child: Column(
              children: [
                for (final (i, c) in children.indexed) ...[
                  if (i > 0) const Divider(indent: 16, endIndent: 16),
                  c,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.title, {this.description, required this.trailing});
  final String title;
  final String? description;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title),
      subtitle: description == null ? null : Text(description!),
      trailing: trailing,
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch(this.title, {this.description, required this.value, required this.onChanged});
  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title),
      subtitle: description == null ? null : Text(description!),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.min, required this.max, required this.onChanged, this.unit});
  final int value;
  final int min;
  final int max;
  final String? unit;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton.outlined(
        visualDensity: VisualDensity.compact,
        onPressed: onChanged == null || value <= min ? null : () => onChanged!(value - 1),
        icon: const Icon(Icons.remove, size: 18),
      ),
      SizedBox(
        width: 56,
        child: Text(unit == null ? '$value' : '$value $unit',
            textAlign: TextAlign.center, style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
      ),
      IconButton.outlined(
        visualDensity: VisualDensity.compact,
        onPressed: onChanged == null || value >= max ? null : () => onChanged!(value + 1),
        icon: const Icon(Icons.add, size: 18),
      ),
    ]);
  }
}

// MARK: - General

const _seeds = [
  Color(0xFF4B49C8), // catussh indigo
  Color(0xFF006A6A),
  Color(0xFF386A20),
  Color(0xFF8B5000),
  Color(0xFFB3261E),
  Color(0xFF984061),
  Color(0xFF6750A4),
  Color(0xFF0061A4),
];

class _GeneralSettings extends StatelessWidget {
  const _GeneralSettings();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section('Appearance', [
          _Row(
            'Light or dark',
            description: 'Terminal colors are set under Terminal.',
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {store.appearance},
              onSelectionChanged: (s) => store.update((st) => st.appearance = s.first),
            ),
          ),
          _Switch(
            'Use the desktop accent color',
            description: 'Material You: colors follow your desktop theme when it provides an accent.',
            value: store.dynamicColor,
            onChanged: (v) => store.update((s) => s.dynamicColor = v),
          ),
          ListTile(
            enabled: !store.dynamicColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: const Text('Accent color'),
            subtitle: const Text('Used when the desktop accent is off or unavailable.'),
            trailing: Wrap(spacing: 6, children: [
              for (final c in _seeds)
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => store.update((s) {
                    s.seedColor = c;
                    s.dynamicColor = false;
                  }),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: !store.dynamicColor && store.seedColor.toARGB32() == c.toARGB32() ? scheme.onSurface : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
        _Section('Sessions', [
          _Switch(
            'Show a session when it connects',
            description: 'Switch to a terminal as soon as it opens.',
            value: store.openInterfaceAutomatically,
            onChanged: (v) => store.update((s) => s.openInterfaceAutomatically = v),
          ),
          _Switch(
            'Ask before closing a session',
            description: 'Confirm before closing a connected terminal or deleting.',
            value: !store.disableConformation,
            onChanged: (v) => store.update((s) => s.disableConformation = !v),
          ),
        ]),
        _Section('Recent', [
          _Switch(
            'Remember recent servers',
            description: 'Listed under Quick Connect on Home.',
            value: store.storeRecent,
            onChanged: (v) => store.update((s) => s.storeRecent = v),
          ),
          _Row(
            'Number to keep',
            trailing: _Stepper(
              value: store.maxRecentRecordCount,
              min: 1,
              max: 50,
              onChanged: store.storeRecent
                  ? (v) => store.update((s) {
                        s.maxRecentRecordCount = v;
                        s.trimRecent();
                      })
                  : null,
            ),
          ),
          _Switch(
            'Include Quick Connect commands',
            description: 'Also remember user@host commands typed on Home.',
            value: store.saveTemporarySession,
            onChanged: store.storeRecent ? (v) => store.update((s) => s.saveTemporarySession = v) : null,
          ),
        ]),
      ],
    );
  }
}

// MARK: - Terminal

class _TerminalSettings extends StatefulWidget {
  const _TerminalSettings();

  @override
  State<_TerminalSettings> createState() => _TerminalSettingsState();
}

class _TerminalSettingsState extends State<_TerminalSettings> {
  List<String> _fonts = const ['monospace'];
  final _preview = Terminal(maxLines: 100);

  @override
  void initState() {
    super.initState();
    _loadFonts();
    _preview.write(
      '\x1b[1;32mroot@web-01\x1b[0m:\x1b[1;34m~\x1b[0m\$ ls --color\r\n'
      '\x1b[1;34mbin\x1b[0m  \x1b[1;34metc\x1b[0m  \x1b[1;32mdeploy.sh\x1b[0m  notes.txt  \x1b[1;36mlink\x1b[0m\r\n'
      '\x1b[1;32mroot@web-01\x1b[0m:\x1b[1;34m~\x1b[0m\$ echo -e "\x1b[31mred \x1b[33myellow \x1b[32mgreen \x1b[36mcyan \x1b[34mblue \x1b[35mmagenta\x1b[0m"\r\n'
      '\x1b[31mred \x1b[33myellow \x1b[32mgreen \x1b[36mcyan \x1b[34mblue \x1b[35mmagenta\x1b[0m\r\n'
      '\x1b[1;32mroot@web-01\x1b[0m:\x1b[1;34m~\x1b[0m\$ ',
    );
  }

  /// The installed monospace families, from fontconfig.
  Future<void> _loadFonts() async {
    if (!Platform.isLinux) return;
    try {
      final result = await Process.run('fc-list', [':spacing=mono', 'family']);
      final families = (result.stdout as String)
          .split('\n')
          .map((l) => l.split(',').first.trim())
          .where((l) => l.isNotEmpty && !l.contains('Emoji'))
          .toSet()
          .toList()
        ..sort();
      if (mounted) setState(() => _fonts = ['monospace', ...families]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final scheme = Theme.of(context).colorScheme;
    final theme = resolveTerminalTheme(store.terminalTheme, scheme);
    final fonts = _fonts.contains(store.terminalFontFamily) ? _fonts : [..._fonts, store.terminalFontFamily];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: RX.s5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 150,
              color: theme.background,
              padding: const EdgeInsets.all(RX.s3),
              child: TerminalView(
                _preview,
                theme: theme,
                readOnly: true,
                hardwareKeyboardOnly: true,
                textStyle: TerminalStyle(
                  fontSize: store.terminalFontSize.toDouble(),
                  fontFamily: store.terminalFontFamily,
                  fontFamilyFallback: RX.monoFallback,
                ),
              ),
            ),
          ),
        ),
        _Section('Text', [
          _Row(
            'Font',
            description: 'Installed monospace fonts.',
            trailing: DropdownButton<String>(
              value: store.terminalFontFamily,
              underline: const SizedBox(),
              borderRadius: BorderRadius.circular(12),
              items: [
                for (final f in fonts)
                  DropdownMenuItem(value: f, child: Text(f, style: TextStyle(fontFamily: f, fontFamilyFallback: RX.monoFallback))),
              ],
              onChanged: (v) => v == null ? null : store.update((s) => s.terminalFontFamily = v),
            ),
          ),
          _Row(
            'Size',
            description: 'Ctrl+= and Ctrl+- change it in a terminal.',
            trailing: _Stepper(
              value: store.terminalFontSize,
              min: 4,
              max: 30,
              unit: 'pt',
              onChanged: (v) => store.update((s) => s.terminalFontSize = v),
            ),
          ),
        ]),
        _Section('Colors', [
          Padding(
            padding: const EdgeInsets.all(RX.s4),
            child: Wrap(
              spacing: RX.s3,
              runSpacing: RX.s3,
              children: [
                _ThemeSwatch(id: 'material', title: 'Material You', theme: materialTerminalTheme(scheme)),
                for (final t in terminalThemes) _ThemeSwatch(id: t.id, title: t.title, theme: t.theme),
              ],
            ),
          ),
        ]),
        _Section('Keyboard', const [
          _Row('Copy', trailing: Text('Ctrl+Shift+C')),
          _Row('Paste', trailing: Text('Ctrl+V')),
          _Row('New terminal on this server', trailing: Text('Ctrl+Shift+T')),
          _Row('Close terminal', trailing: Text('Ctrl+Shift+W')),
          _Row('Settings', trailing: Text('Ctrl+,')),
          _Row('New server', trailing: Text('Ctrl+Shift+N')),
          _Row('Show or hide the sidebar', trailing: Text('Ctrl+\\')),
        ]),
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.id, required this.title, required this.theme});
  final String id;
  final String title;
  final TerminalTheme theme;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final selected = store.terminalTheme == id;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => store.update((s) => s.terminalTheme = id),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 3 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: theme.foreground, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          Row(children: [
            for (final c in [theme.red, theme.green, theme.yellow, theme.blue, theme.magenta, theme.cyan])
              Expanded(child: Container(height: 10, margin: const EdgeInsets.only(right: 3), color: c)),
          ]),
        ]),
      ),
    );
  }
}

// MARK: - Connection

class _ConnectionSettings extends StatelessWidget {
  const _ConnectionSettings();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final count = store.knownHosts.count;
    const intervals = [5, 10, 15, 30, 60];
    final interval = store.monitorInterval < 5 ? 5 : store.monitorInterval;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section('SSH', [
          _Row(
            'Connection timeout',
            description: 'How long to wait for a server before giving up.',
            trailing: _Stepper(
              value: store.timeout,
              min: 2,
              max: 30,
              unit: 's',
              onChanged: (v) => store.update((s) => s.timeout = v),
            ),
          ),
          _Row(
            'Saved host keys',
            description:
                "A server's key is saved the first time you connect; a server that later presents another key is refused. $count saved.",
            trailing: OutlinedButton(
              onPressed: count == 0
                  ? null
                  : () async {
                      final ok = await requiresConfirmation(
                        context,
                        message: 'Forget all saved host keys?',
                        informative: 'The key each server presents on its next connection is saved as its key.',
                        confirmTitle: 'Forget All',
                      );
                      if (ok) store.update((s) => s.knownHosts.forgetAll());
                    },
              child: const Text('Forget All…'),
            ),
          ),
        ]),
        _Section('Monitor', [
          _Row(
            'Refresh',
            description: 'How often an open monitor reads the server.',
            trailing: DropdownButton<int>(
              value: interval,
              underline: const SizedBox(),
              borderRadius: BorderRadius.circular(12),
              items: [
                for (final s in {...intervals, interval}) DropdownMenuItem(value: s, child: Text('Every $s s')),
              ],
              onChanged: (v) => v == null ? null : store.update((s) => s.monitorInterval = v),
            ),
          ),
        ]),
        _Section('Storage', [
          _Row(
            'Where your servers are kept',
            description: store.vault.problem ??
                'Servers, identities and snippets are encrypted (AES-256-GCM) in ${store.vault.directory.path}; the key is kept in the system keyring.',
            trailing: const SizedBox(),
          ),
        ]),
      ],
    );
  }
}

// MARK: - About

class _AboutSettings extends StatelessWidget {
  const _AboutSettings();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: RX.s5),
          child: Row(children: [
            Image.asset('assets/icon/catussh.png', width: 72, height: 72),
            const SizedBox(width: RX.s4),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('catussh', style: Theme.of(context).textTheme.headlineSmall),
              const Text('SSH terminal, files and monitor for your servers.'),
            ]),
          ]),
        ),
        _Section('catussh', [
          const _Row('Version', trailing: SelectableText('3.0.0 (Flutter) · Linux')),
          _Row(
            'Source code',
            description: 'Omicron0314/catussh on GitHub',
            trailing: OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse('https://github.com/Omicron0314/catussh')),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('GitHub'),
            ),
          ),
          _Row(
            'Report a problem',
            description: "Bugs and ideas go to the project's issue tracker.",
            trailing: OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse('https://github.com/Omicron0314/catussh/issues')),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Issues'),
            ),
          ),
          _Row(
            'Legal',
            trailing: Wrap(spacing: RX.s2, children: [
              OutlinedButton(onPressed: () => showDocument(context, AboutDocument.license), child: const Text('License…')),
              OutlinedButton(onPressed: () => showDocument(context, AboutDocument.agreement), child: const Text('Agreement…')),
            ]),
          ),
        ]),
        const _Section('Acknowledgements', [
          _Row('Based on', description: 'catussh by mizorewww, the continuation of Rayon by Lakr Aream (@Lakr233) and contributors. This version is not affiliated with or endorsed by them.', trailing: SizedBox()),
          _Row('Libraries', description: 'Flutter · dartssh2 · xterm.dart · re_editor · dynamic_color · tray_manager · cryptography', trailing: SizedBox()),
        ]),
      ],
    );
  }
}
