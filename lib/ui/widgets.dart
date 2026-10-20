// Shared building blocks: the Material counterparts of CatusshDesign's
// PageScaffold, rxCard, EmptyStateView, SectionTitle, CapsLabel, UsageBar,
// RedactableText and UIBridge's confirmation and error alerts.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/store.dart';
import 'theme.dart';

/// A page with a top bar (title, search, actions) and scrolling content.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    this.title,
    this.actions = const [],
    this.search,
    this.searchHint,
    this.center,
    this.leading,
    required this.body,
    this.scrollable = true,
    this.padding = const EdgeInsets.fromLTRB(RX.s6, 0, RX.s6, RX.s6),
  });

  final String? title;
  final List<Widget> actions;
  final TextEditingController? search;
  final String? searchHint;
  final Widget? center;
  final Widget? leading;
  final Widget body;
  final bool scrollable;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bar = SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: RX.s4),
        child: Row(
          children: [
            ?leading,
            Expanded(
              child: center == null
                  ? const SizedBox()
                  : Align(alignment: Alignment.center, child: center),
            ),
            ...actions.expand((w) => [w, const SizedBox(width: RX.s2)]),
            if (search != null) SizedBox(width: 240, child: SearchField(controller: search!, hint: searchHint ?? 'Search')),
          ],
        ),
      ),
    );
    final heading = title == null
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(RX.s6, RX.s1, RX.s6, RX.s4),
            child: Text(title!, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
          );
    if (!scrollable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [bar, ?heading, Expanded(child: Padding(padding: padding, child: body))],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bar,
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [?heading, Padding(padding: padding, child: body)],
            ),
          ),
        ),
      ],
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: controller,
      hintText: hint,
      leading: const Icon(Icons.search, size: 20),
      elevation: const WidgetStatePropertyAll(0),
      constraints: const BoxConstraints(minHeight: 40, maxHeight: 40),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
      trailing: [
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.text.isEmpty
              ? const SizedBox()
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Clear',
                  onPressed: controller.clear,
                ),
        ),
      ],
    );
  }
}

/// A rounded surface, like `.rxCard()`.
class RXCard extends StatelessWidget {
  const RXCard({super.key, required this.child, this.padding = const EdgeInsets.all(RX.s4), this.color});
  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(padding: padding, child: child),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView(
    this.title, {
    super.key,
    required this.icon,
    this.message,
    this.actionTitle,
    this.action,
  });

  final String title;
  final IconData icon;
  final String? message;
  final String? actionTitle;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(RX.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: theme.colorScheme.primary),
          const SizedBox(height: RX.s3),
          Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: RX.s1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
          if (actionTitle != null && action != null) ...[
            const SizedBox(height: RX.s4),
            FilledButton.tonal(onPressed: action, child: Text(actionTitle!)),
          ],
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.count, this.trailing});
  final String title;
  final int? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        if (count != null) ...[
          const SizedBox(width: RX.s2),
          Text('$count', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

/// The small upper-case label ("LAST USED", "IDENTITY").
class CapsLabel extends StatelessWidget {
  const CapsLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        letterSpacing: 0.8,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class UsageBar extends StatelessWidget {
  const UsageBar({super.key, required this.segments, this.height = 6});

  /// (fraction 0–1, color) pairs, drawn left to right.
  final List<(double, Color)> segments;
  final double height;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, c) {
            var left = 0.0;
            return Stack(
              children: [
                Container(color: track),
                for (final (fraction, color) in segments)
                  () {
                    final f = fraction.isFinite ? fraction.clamp(0.0, 1.0 - left) : 0.0;
                    final w = Positioned(
                      left: left * c.maxWidth,
                      width: f * c.maxWidth,
                      top: 0,
                      bottom: 0,
                      child: AnimatedContainer(duration: const Duration(milliseconds: 300), color: color),
                    );
                    left += f;
                    return w;
                  }(),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Text that is blurred when the Privacy toggle hides it.
class RedactableText extends StatelessWidget {
  const RedactableText(this.text, {super.key, required this.redacted, this.style, this.maxLines = 1});
  final String text;
  final bool redacted;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final child = Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    if (!redacted) return child;
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: ExcludeSemantics(child: child),
    );
  }
}

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, this.color, this.size = 8});
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.success;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 0, spreadRadius: 3)],
      ),
    );
  }
}

// MARK: - Alerts (UIBridge)

/// Asks before doing something. Skipped (answers yes) when "Ask before
/// closing" is off, unless [always].
Future<bool> requiresConfirmation(
  BuildContext context, {
  required String message,
  String? informative,
  String confirmTitle = 'Continue',
  bool destructive = false,
  bool always = false,
}) async {
  if (CatusshStore.shared.disableConformation && !always) return true;
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(message),
      content: informative == null ? null : ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Text(informative),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError)
              : null,
          autofocus: true,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmTitle),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> presentError(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.error_outline),
      title: const Text('Error'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SelectableText(message),
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ),
  );
}

/// Asks for one line of text (New Folder, Rename, Go to Folder).
Future<String?> promptText(
  BuildContext context, {
  required String title,
  String initial = '',
  String? hint,
  String confirmTitle = 'OK',
  String? Function(String value)? validate,
  bool monospace = false,
}) {
  final controller = TextEditingController(text: initial);
  controller.selection = TextSelection(baseOffset: 0, extentOffset: initial.length);
  String? error;
  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        void submit() {
          final value = controller.text;
          final problem = validate?.call(value);
          if (problem != null) {
            setState(() => error = problem);
            return;
          }
          Navigator.pop(context, value);
        }

        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: controller,
              autofocus: true,
              style: monospace ? RX.code(context, size: 14) : null,
              decoration: InputDecoration(hintText: hint, errorText: error),
              onSubmitted: (_) => submit(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: submit, child: Text(confirmTitle)),
          ],
        );
      },
    ),
  );
}

void copyToClipboard(BuildContext context, String text, {String? what}) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(content: Text(what == null ? 'Copied' : '$what copied'), duration: const Duration(seconds: 2)),
  );
}

/// A labelled form field, like RXField.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        child,
      ],
    );
  }
}

/// A dialog laid out like the Swift app's SheetScaffold: title, content,
/// footer buttons.
class SheetDialog extends StatelessWidget {
  const SheetDialog({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
    this.width = 520,
    this.leadingActions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final List<Widget> leadingActions;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(RX.s6, RX.s6, RX.s6, RX.s4),
              child: Text(title, style: theme.textTheme.headlineSmall),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: RX.s6),
                child: child,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(RX.s4),
              child: Row(
                children: [
                  ...leadingActions,
                  const Spacer(),
                  ...actions.expand((w) => [const SizedBox(width: RX.s2), w]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hover feedback for tiles and rows.
class Hoverable extends StatefulWidget {
  const Hoverable({super.key, required this.builder});
  final Widget Function(BuildContext context, bool hovered) builder;

  @override
  State<Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<Hoverable> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.builder(context, _hovered),
    );
  }
}

/// Opens a popup menu where the pointer was right-clicked.
Future<T?> showContextMenuAt<T>(BuildContext context, Offset position, List<PopupMenuEntry<T>> items) {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  return showMenu<T>(
    context: context,
    position: RelativeRect.fromRect(position & const Size(1, 1), Offset.zero & overlay.size),
    items: items,
  );
}

PopupMenuItem<VoidCallback> menuItem(String label, IconData icon, VoidCallback action,
    {bool enabled = true, bool destructive = false, BuildContext? context}) {
  final color = destructive && context != null ? Theme.of(context).colorScheme.error : null;
  return PopupMenuItem<VoidCallback>(
    value: action,
    enabled: enabled,
    height: 40,
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: RX.s3),
        Text(label, style: color == null ? null : TextStyle(color: color)),
      ],
    ),
  );
}

/// Shows a menu built from [menuItem]s and runs the chosen action.
Future<void> runMenu(BuildContext context, Offset position, List<PopupMenuEntry<VoidCallback>> items) async {
  final action = await showContextMenuAt<VoidCallback>(context, position, items);
  action?.call();
}
