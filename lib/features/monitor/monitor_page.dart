// A server's live monitor: facts, then the dashboard cards
// (MonitorPage.swift, MonitorDashboard.swift, MonitorCards.swift).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/store.dart';
import '../../monitor/server_status.dart';
import '../../sessions/monitor_session.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../menubar/tray.dart';
import '../servers/server_actions.dart';

class MonitorPage extends StatelessWidget {
  const MonitorPage({super.key, required this.session});
  final MonitorSession session;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatusshStore>();
    final saved = store.machine(session.machine.id);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final ready = session.phase is MonitorConnected && session.status.hasData;
        return PageScaffold(
          center: saved == null ? null : ServerToolSwitcher(machine: saved, current: ServerTool.monitor),
          actions: [
            if (session.isRefreshing)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            IconButton(
              tooltip: 'Show in Tray',
              onPressed: TrayController.instance.available ? () => TrayController.instance.show(session.machine) : null,
              icon: const Icon(Icons.pets),
            ),
            IconButton(
              tooltip: 'Close Monitor',
              onPressed: () => AppRouter.shared.closeMonitor(session),
              icon: const Icon(Icons.close),
            ),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(store.machineRedacted == RedactedLevel.all ? 'Server' : session.machine.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: RX.s5),
              _Facts(session: session, redactAddress: store.machineRedacted != RedactedLevel.none),
              const SizedBox(height: RX.s5),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ready
                    ? MonitorDashboard(key: const ValueKey('dash'), session: session)
                    : _Placeholder(key: const ValueKey('wait'), session: session),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.session, required this.redactAddress});
  final MonitorSession session;
  final bool redactAddress;

  @override
  Widget build(BuildContext context) {
    final system = session.status.system;
    final theme = Theme.of(context);
    Widget fact(String title, String value, {bool mono = false, bool redacted = false}) => Padding(
          padding: const EdgeInsets.only(right: RX.s6 * 1.5, bottom: RX.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CapsLabel(title),
              const SizedBox(height: 4),
              RedactableText(value,
                  redacted: redacted,
                  style: mono ? RX.code(context, size: 14) : theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        );
    return Wrap(
      children: [
        fact('Hostname', system.hostname.isEmpty ? '—' : system.hostname),
        fact('OS', system.releaseName.isEmpty ? '—' : system.releaseName),
        fact('Uptime', RXFormat.duration(system.uptimeSec)),
        fact('Address', session.machine.remoteAddress, mono: true, redacted: redactAddress),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({super.key, required this.session});
  final MonitorSession session;

  @override
  Widget build(BuildContext context) {
    final phase = session.phase;
    return RXCard(
      child: switch (phase) {
        MonitorFailed(:final message) => EmptyStateView("Can't connect",
            icon: Icons.warning_amber_rounded, message: message, actionTitle: 'Try Again', action: session.retry),
        MonitorClosed() => const EmptyStateView('Monitor closed', icon: Icons.monitor_heart_outlined),
        _ => const Padding(
            padding: EdgeInsets.all(RX.s6),
            child: Column(children: [
              CircularProgressIndicator(),
              SizedBox(height: RX.s3),
              Text('Connecting…'),
            ]),
          ),
      },
    );
  }
}

class MonitorDashboard extends StatelessWidget {
  const MonitorDashboard({super.key, required this.session});
  final MonitorSession session;

  @override
  Widget build(BuildContext context) {
    final left = [
      _LoadCard(session: session),
      _ProcessorCard(session: session),
      _MemoryCard(session: session),
      _DiskCard(session: session),
    ];
    final right = [
      Row(children: [
        Expanded(child: _ThroughputCard(session: session, receive: true)),
        const SizedBox(width: RX.s4),
        Expanded(child: _ThroughputCard(session: session, receive: false)),
      ]),
      _NetworkCard(session: session),
      if (session.status.graphics?.units.isNotEmpty ?? false) _GraphicsCard(graphics: session.status.graphics!),
    ];
    Widget column(List<Widget> cards) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final c in cards) Padding(padding: const EdgeInsets.only(bottom: RX.s4), child: c)],
        );
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 760) return column([...left, ...right]);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: column(left)),
          const SizedBox(width: RX.s4),
          Expanded(child: column(right)),
        ],
      );
    });
  }
}

// MARK: - Card parts

class _CardHead extends StatelessWidget {
  const _CardHead(this.title, {this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const Spacer(),
        ?trailing,
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.unit);
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value,
            style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(width: 6),
        Text(unit, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _SubMetric {
  const _SubMetric(this.title, this.value, {this.unit, this.swatch});
  final String title;
  final String value;
  final String? unit;
  final Color? swatch;
}

class _SubMetricRow extends StatelessWidget {
  const _SubMetricRow(this.items);
  final List<_SubMetric> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: RX.s6,
      runSpacing: RX.s3,
      children: [
        for (final i in items)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (i.swatch != null) ...[
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: i.swatch, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 5),
                ],
                CapsLabel(i.title),
              ]),
              const SizedBox(height: 2),
              Text.rich(TextSpan(children: [
                TextSpan(
                    text: i.value,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])),
                if (i.unit != null)
                  TextSpan(text: ' ${i.unit}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ])),
            ],
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.title, this.value, this.color);
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
      ),
      const SizedBox(width: 6),
      Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(width: 6),
      Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }
}

/// A segmented toggle like RXSegmented in a card head.
class _Toggle extends StatelessWidget {
  const _Toggle({required this.options, required this.value, required this.onChanged});
  final List<String> options;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity(horizontal: -3, vertical: -3)),
      segments: [for (final (i, o) in options.indexed) ButtonSegment(value: i, label: Text(o))],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

String _kB(double kb) => RXFormat.bytesString(kb * 1024);

// MARK: - Cards

class _LoadCard extends StatelessWidget {
  const _LoadCard({required this.session});
  final MonitorSession session;

  @override
  Widget build(BuildContext context) {
    final system = session.status.system;
    return RXCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _CardHead('Load'),
        _Metric(system.load1.toStringAsFixed(2), '1 min'),
        const SizedBox(height: RX.s5),
        _SubMetricRow([
          _SubMetric('5 min', system.load5.toStringAsFixed(2)),
          _SubMetric('15 min', system.load15.toStringAsFixed(2)),
          _SubMetric('Processes', '${system.runningProcs}', unit: '/ ${system.totalProcs} running'),
        ]),
      ]),
    );
  }
}

class _ProcessorCard extends StatefulWidget {
  const _ProcessorCard({required this.session});
  final MonitorSession session;

  @override
  State<_ProcessorCard> createState() => _ProcessorCardState();
}

class _ProcessorCardState extends State<_ProcessorCard> {
  int _view = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final processor = widget.session.status.processor;
    final s = processor.summary;
    final count = processor.cores.length;
    final nice = scheme.outline;
    return RXCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _CardHead(
          count == 0 ? 'Processor' : 'Processor · $count ${count == 1 ? 'core' : 'cores'}',
          trailing: _Toggle(options: const ['Summary', 'Cores'], value: _view, onChanged: (v) => setState(() => _view = v)),
        ),
        _Metric(RXFormat.oneDecimal(s.sumUsed), '%'),
        if (_view == 1) ...[
          const SizedBox(height: RX.s4),
          _CoreGrid(cores: processor.cores),
        ] else ...[
          const SizedBox(height: RX.s3),
          UsageBar(height: 10, segments: [
            (s.sumUser / 100, scheme.primary),
            (s.sumSystem / 100, scheme.series2),
            (s.sumIOWait / 100, scheme.warning),
            (s.sumNice / 100, nice),
          ]),
          const SizedBox(height: RX.s5),
          _SubMetricRow([
            _SubMetric('User', RXFormat.oneDecimal(s.sumUser), unit: '%', swatch: scheme.primary),
            _SubMetric('System', RXFormat.oneDecimal(s.sumSystem), unit: '%', swatch: scheme.series2),
            _SubMetric('IO wait', RXFormat.oneDecimal(s.sumIOWait), unit: '%', swatch: scheme.warning),
            _SubMetric('Nice', RXFormat.oneDecimal(s.sumNice), unit: '%', swatch: nice),
          ]),
        ],
      ]),
    );
  }
}

class _CoreGrid extends StatelessWidget {
  const _CoreGrid({required this.cores});
  final List<ProcessPercentInfo> cores;

  @override
  Widget build(BuildContext context) {
    if (cores.isEmpty) return const Text('No data');
    final scheme = Theme.of(context).colorScheme;
    final perRow = cores.length > 64 ? 16 : 8;
    final height = cores.length > 64 ? 28.0 : 44.0;
    return LayoutBuilder(builder: (context, c) {
      final width = (c.maxWidth - 6 * (perRow - 1)) / perRow;
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final (i, core) in cores.indexed)
            Tooltip(
              message: '${core.name}: ${RXFormat.percent(core.sumUsed)}%',
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Color.lerp(scheme.surfaceContainerHighest, scheme.primary, (core.sumUsed / 100).clamp(0, 1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: height > 30
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('$i', style: TextStyle(fontSize: 9, color: core.sumUsed > 55 ? scheme.onPrimary : scheme.onSurfaceVariant)),
                        Text(RXFormat.percent(core.sumUsed),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: core.sumUsed > 55 ? scheme.onPrimary : scheme.onSurface)),
                      ])
                    : null,
              ),
            ),
        ],
      );
    });
  }
}

class _MemoryCard extends StatefulWidget {
  const _MemoryCard({required this.session});
  final MonitorSession session;

  @override
  State<_MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<_MemoryCard> {
  int _view = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = widget.session.status;
    final memory = status.memory;
    final total = memory.memTotal;
    final free = scheme.surfaceContainerHighest;
    List<Widget> body;
    if (_view == 1) {
      final swapTotal = memory.swapTotal;
      final swapUsed = math.max(0.0, swapTotal - memory.swapFree);
      body = [
        _Metric(RXFormat.percent(swapTotal > 0 ? swapUsed / swapTotal * 100 : 0), '%'),
        const SizedBox(height: RX.s3),
        UsageBar(height: 10, segments: [(swapTotal > 0 ? swapUsed / swapTotal : 0, scheme.primary)]),
        const SizedBox(height: RX.s3),
        Wrap(spacing: RX.s4, runSpacing: RX.s2, children: [
          _Legend('Used', _kB(swapUsed), scheme.primary),
          _Legend('Free', _kB(memory.swapFree), free),
        ]),
        if (swapTotal <= 0) ...[const SizedBox(height: RX.s3), const Text('No swap')],
      ];
    } else {
      body = [
        _Metric(RXFormat.oneDecimal(status.memoryUsedPercent), '%'),
        const SizedBox(height: RX.s3),
        UsageBar(height: 10, segments: [
          (total > 0 ? status.memoryUsedKB / total : 0, scheme.primary),
          (total > 0 ? status.memoryCacheKB / total : 0, scheme.series2),
        ]),
        const SizedBox(height: RX.s3),
        Wrap(spacing: RX.s4, runSpacing: RX.s2, children: [
          _Legend('Used', _kB(status.memoryUsedKB), scheme.primary),
          _Legend('Cache', _kB(status.memoryCacheKB), scheme.series2),
          _Legend('Free', _kB(memory.memFree), free),
        ]),
      ];
    }
    return RXCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _CardHead(
          total > 0 ? 'Memory · ${_kB(total)}' : 'Memory',
          trailing: _Toggle(options: const ['RAM', 'Swap'], value: _view, onChanged: (v) => setState(() => _view = v)),
        ),
        ...body,
      ]),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.name, required this.value, required this.detail, required this.bar});
  final String name;
  final String value;
  final String detail;
  final Widget bar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text(name, overflow: TextOverflow.ellipsis, style: RX.code(context, size: 13))),
        Text(value, style: theme.textTheme.labelLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        if (detail.isNotEmpty)
          Text(' · $detail',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
      const SizedBox(height: 6),
      bar,
    ]);
  }
}

Color _threshold(ColorScheme scheme, double percent, Color normal) =>
    percent >= 90 ? scheme.error : (percent >= 75 ? scheme.warning : normal);

class _DiskCard extends StatelessWidget {
  const _DiskCard({required this.session});
  final MonitorSession session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final elements = session.status.fileSystem.elements;
    return RXCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _CardHead('Disks'),
        if (elements.isEmpty) const Text('No data'),
        for (final e in elements)
          Padding(
            padding: const EdgeInsets.only(top: RX.s3),
            child: _UsageRow(
              name: e.mountPoint,
              value: '${RXFormat.percent(e.percent)}%',
              detail: '${e.used} of ${e.size}',
              bar: UsageBar(segments: [(e.percent / 100, _threshold(scheme, e.percent, scheme.primary))]),
            ),
          ),
      ]),
    );
  }
}

class _ThroughputCard extends StatelessWidget {
  const _ThroughputCard({required this.session, required this.receive});
  final MonitorSession session;
  final bool receive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final samples = receive ? session.history.receive : session.history.transmit;
    final current = (receive ? session.status.totalReceivePerSecond : session.status.totalTransmitPerSecond).toDouble();
    final peak = samples.isEmpty ? 0.0 : samples.reduce(math.max);
    final (value, unit) = RXFormat.rate(current);
    final color = receive ? scheme.series2 : scheme.primary;
    return Card(
      child: SizedBox(
        height: 200,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(RX.s4, RX.s4, RX.s4, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _CardHead(
                receive ? 'Receive' : 'Transmit',
                trailing: peak > 0
                    ? Text('peak ${RXFormat.rateString(peak)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))
                    : null,
              ),
              _Metric(value, unit),
            ]),
          ),
          const Spacer(),
          SizedBox(height: 84, child: CustomPaint(painter: _Sparkline(samples, color))),
        ]),
      ),
    );
  }
}

class _Sparkline extends CustomPainter {
  _Sparkline(this.samples, this.color);
  final List<double> samples;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;
    final peak = math.max(1.0, samples.reduce(math.max));
    final step = size.width / (MonitorHistory.capacity - 1);
    final start = size.width - step * (samples.length - 1);
    final path = Path();
    for (final (i, v) in samples.indexed) {
      final x = start + i * step;
      final y = size.height - (v / peak) * (size.height - 6) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(start, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.02)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_Sparkline old) => true;
}

class _NetworkCard extends StatelessWidget {
  const _NetworkCard({required this.session});
  final MonitorSession session;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final elements = session.status.network.elements.toList()
      ..sort((a, b) => (b.rxBytesPerSec + b.txBytesPerSec).compareTo(a.rxBytesPerSec + a.txBytesPerSec));
    final peak = math.max(1, elements.fold<int>(1, (m, e) => math.max(m, math.max(e.rxBytesPerSec, e.txBytesPerSec)))).toDouble();
    return RXCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _CardHead('Network'),
        if (elements.isEmpty) const Text('No data'),
        for (final e in elements)
          Padding(
            padding: const EdgeInsets.only(top: RX.s3),
            child: _UsageRow(
              name: e.device,
              value: '↓ ${RXFormat.rateString(e.rxBytesPerSec.toDouble())}',
              detail: '↑ ${RXFormat.rateString(e.txBytesPerSec.toDouble())}',
              bar: UsageBar(segments: [
                (e.rxBytesPerSec / peak / 2, scheme.series2),
                (e.txBytesPerSec / peak / 2, scheme.primary),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _GraphicsCard extends StatelessWidget {
  const _GraphicsCard({required this.graphics});
  final GraphicsInfo graphics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    Widget bar(String title, double percent, Color color) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(children: [
            SizedBox(width: 44, child: CapsLabel(title)),
            Expanded(child: UsageBar(segments: [(percent / 100, _threshold(scheme, percent, color))])),
            SizedBox(
                width: 44,
                child: Text('${RXFormat.percent(percent)}%',
                    textAlign: TextAlign.right, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600))),
          ]),
        );
    final n = graphics.units.length;
    return RXCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _CardHead('Graphics · $n ${n == 1 ? 'GPU' : 'GPUs'}',
            trailing: Text('CUDA ${graphics.version}', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
        for (final u in graphics.units)
          Padding(
            padding: const EdgeInsets.only(top: RX.s3),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text(u.name, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall)),
                Text('Fan ${u.fanSpeed}', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ]),
              bar('GPU', u.gpuUtil, scheme.primary),
              bar('VRAM', u.memoryTotal > 0 ? u.memoryUsed / u.memoryTotal * 100 : 0, scheme.series2),
            ]),
          ),
      ]),
    );
  }
}
