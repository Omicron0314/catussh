import 'package:catussh/core/strings.dart';
import 'package:catussh/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => S.setLocale(const Locale('en')));

  test('a Chinese system resolves to the Chinese strings', () {
    final locale = basicLocaleListResolution(
      const [Locale('zh', 'CN')],
      L10n.supportedLocales,
    );
    expect(locale.languageCode, 'zh');
    S.setLocale(locale);
    expect(S.l.newServer, '新建服务器');
    expect(S.l.navServers, '服务器');
    expect(S.l.copied('命令'), '已复制命令');
  });

  test('every English string has a Chinese one', () {
    final en = lookupL10n(const Locale('en'));
    final zh = lookupL10n(const Locale('zh'));
    // A few getters that read the same in both.
    final same = {'appName', 'cpu', 'ssh'};
    for (final probe in _probes(en, zh)) {
      final name = probe.$1;
      if (same.contains(name)) continue;
      expect(probe.$2.isEmpty, isFalse, reason: '$name is empty in Chinese');
      expect(probe.$3.isEmpty, isFalse, reason: '$name is empty in English');
    }
  });

  test('an unknown locale falls back to English', () {
    S.setLocale(const Locale('fr'));
    expect(S.l.newServer, 'New Server');
  });

  test('relative times are localized', () {
    final now = DateTime(2026, 1, 1, 12);
    final past = now.subtract(const Duration(minutes: 5));
    S.setLocale(const Locale('en'));
    expect(S.l.minutesAgo(5), '5 minutes ago');
    S.setLocale(const Locale('zh'));
    expect(S.l.minutesAgo(5), '5 分钟前');
    expect(past.isBefore(now), isTrue);
  });
}

/// Every message, as (name, English, Chinese). The generated class has no
/// reflection, so the list is written out; `flutter gen-l10n` fails on a key
/// missing from an ARB file, which is the check that matters at build time.
Iterable<(String, String, String)> _probes(L10n en, L10n zh) sync* {
  yield ('newServer', en.newServer, zh.newServer);
  yield ('navServers', en.navServers, zh.navServers);
  yield ('navIdentities', en.navIdentities, zh.navIdentities);
  yield ('navSnippets', en.navSnippets, zh.navSnippets);
  yield ('navPortForward', en.navPortForward, zh.navPortForward);
  yield ('settingsSection', en.general, zh.general);
  yield ('toolTerminal', en.toolTerminal, zh.toolTerminal);
  yield ('toolFiles', en.toolFiles, zh.toolFiles);
  yield ('toolEditor', en.toolEditor, zh.toolEditor);
  yield ('toolMonitor', en.toolMonitor, zh.toolMonitor);
  yield ('connect', en.connect, zh.connect);
  yield ('cancel', en.cancel, zh.cancel);
  yield ('save', en.save, zh.save);
  yield ('delete', en.delete, zh.delete);
  yield ('language', en.language, zh.language);
  yield ('appearance', en.appearance, zh.appearance);
  yield ('keyboard', en.keyboard, zh.keyboard);
  yield ('never', en.never, zh.never);
  yield ('now', en.now, zh.now);
  yield ('connectionClosed', en.connectionClosed, zh.connectionClosed);
}
