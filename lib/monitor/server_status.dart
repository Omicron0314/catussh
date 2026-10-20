// What the monitor reads from a server, and the parsers that read it.
//
// A port of the Swift MachineStatus package: ProcParsers, DarwinParsers and
// the ServerStatus models. Linux reads /proc; macOS hosts use their native
// tools. Nothing is installed on the server.

import 'dart:math' as math;

import 'package:xml/xml.dart';

// MARK: - Models

class ProcessInfoElement {
  const ProcessInfoElement({
    required this.user,
    required this.nice,
    required this.system,
    required this.idle,
    required this.iowait,
    required this.irq,
    required this.softIrq,
    required this.steal,
    required this.guest,
  });

  final double user, nice, system, idle, iowait, irq, softIrq, steal, guest;

  double get total =>
      user + nice + system + idle + iowait + irq + softIrq + steal + guest;
  double get used => user + nice + system + iowait;
}

class ProcessPercentInfo {
  const ProcessPercentInfo({
    this.name = '',
    this.sumSystem = 0,
    this.sumUser = 0,
    this.sumIOWait = 0,
    this.sumNice = 0,
    this.sumUsed = 0,
  });

  final String name;
  final double sumSystem, sumUser, sumIOWait, sumNice, sumUsed;

  ProcessPercentInfo named(String name) => ProcessPercentInfo(
        name: name,
        sumSystem: sumSystem,
        sumUser: sumUser,
        sumIOWait: sumIOWait,
        sumNice: sumNice,
        sumUsed: sumUsed,
      );
}

class ProcessorInfo {
  const ProcessorInfo({
    this.summary = const ProcessPercentInfo(),
    this.cores = const [],
  });

  final ProcessPercentInfo summary;
  final List<ProcessPercentInfo> cores;

  /// Cores ordered cpu0, cpu1, … cpu10 (numerically, not as text).
  factory ProcessorInfo.withCores(
    ProcessPercentInfo summary,
    Map<String, ProcessPercentInfo> cores,
  ) {
    final keys = cores.keys.toList()
      ..sort((a, b) {
        if (a.length < 3 || b.length < 3) return a.compareTo(b);
        final na = int.tryParse(a.substring(3));
        final nb = int.tryParse(b.substring(3));
        if (na != null && nb != null) return na.compareTo(nb);
        return a.compareTo(b);
      });
    return ProcessorInfo(
      summary: summary,
      cores: [for (final key in keys) cores[key]!.named(key)],
    );
  }

  static ProcessorInfo? fromStat(String? before, String? after) {
    if (before == null || after == null) return null;
    final priv = ProcParsers.parseProcStat(before);
    final curr = ProcParsers.parseProcStat(after);
    if (priv.summary == null || curr.summary == null) return null;
    final sum = ProcParsers.calculatePercent(priv.summary!, curr.summary!);
    final perCore = <String, ProcessPercentInfo>{};
    priv.cores.forEach((key, value) {
      final next = curr.cores[key];
      if (next != null) perCore[key] = ProcParsers.calculatePercent(value, next);
    });
    return ProcessorInfo.withCores(sum, perCore);
  }

  static ProcessorInfo? fromDarwinTop(String? top) {
    if (top == null) return null;
    final summary = ProcParsers.parseDarwinCPU(top);
    return summary == null ? null : ProcessorInfo(summary: summary);
  }
}

class MemoryInfo {
  const MemoryInfo.empty()
      : memTotal = 0,
        memFree = 0,
        memBuffers = 0,
        memCached = 0,
        swapTotal = 0,
        swapFree = 0,
        phyUsed = 0,
        swapUsed = 0;

  /// Values in kB.
  MemoryInfo({
    required double total,
    required double free,
    required double buffers,
    required double cached,
    required this.swapTotal,
    required this.swapFree,
  })  : memTotal = total,
        memFree = free,
        memBuffers = buffers,
        memCached = cached,
        phyUsed = total != 0 ? (total - free - cached - buffers) / total : 0,
        swapUsed = swapTotal != 0 ? (swapTotal - swapFree) / swapTotal : 0;

  factory MemoryInfo.fromMeminfo(String raw) {
    final info = ProcParsers.parseMeminfo(raw);
    return MemoryInfo(
      total: info['MEMTOTAL'] ?? 0,
      free: info['MEMFREE'] ?? 0,
      buffers: info['BUFFERS'] ?? 0,
      cached: info['CACHED'] ?? 0,
      swapTotal: info['SWAPTOTAL'] ?? 0,
      swapFree: info['SWAPFREE'] ?? 0,
    );
  }

  factory MemoryInfo.fromDarwin(String raw) {
    final info = ProcParsers.parseDarwinMemory(raw);
    return MemoryInfo(
      total: info.total,
      free: info.free,
      buffers: 0,
      cached: info.cached,
      swapTotal: info.swapTotal,
      swapFree: info.swapFree,
    );
  }

  final double memTotal, memFree, memBuffers, memCached, swapTotal, swapFree;
  final double phyUsed, swapUsed;
}

class FileSystemElement {
  const FileSystemElement({
    required this.mountPoint,
    required this.size,
    required this.used,
    required this.free,
    required this.percent,
  });

  final String mountPoint, size, used, free;
  final double percent;
}

class FileSystemInfo {
  const FileSystemInfo([this.elements = const []]);

  factory FileSystemInfo.fromDfPk(String raw) => FileSystemInfo(
        ProcParsers.parseDfPk(raw)
          ..sort((a, b) => a.mountPoint.compareTo(b.mountPoint)),
      );

  final List<FileSystemElement> elements;
}

class NetworkElement {
  const NetworkElement(this.device, this.rxBytesPerSec, this.txBytesPerSec);
  final String device;
  final int rxBytesPerSec, txBytesPerSec;
}

class NetworkInfo {
  const NetworkInfo([this.elements = const []]);

  final List<NetworkElement> elements;

  static NetworkInfo? fromNetDev(String? before, String? after) {
    if (before == null || after == null) return null;

    Map<String, (int, int)> build(String raw) {
      final result = <String, (int, int)>{};
      for (final item in raw.split('\n')) {
        if (!item.contains(':')) continue;
        final sep = item.split(':');
        if (sep.length != 2) continue;
        final key = sep.first.trim();
        final split = ProcParsers.splitWhitespaceRuns(sep.last);
        if (split.length < 10) continue;
        final rx = int.tryParse(split[0]);
        final tx = int.tryParse(split[8]);
        if (rx == null || tx == null) continue;
        // A device named twice is ambiguous: drop it.
        if (result.containsKey(key)) {
          result.remove(key);
          continue;
        }
        result[key] = (rx, tx);
      }
      return result;
    }

    return _delta(build(before), build(after));
  }

  static NetworkInfo? fromNetstat(String? before, String? after) {
    if (before == null || after == null) return null;
    return _delta(
      ProcParsers.parseDarwinNetstat(before),
      ProcParsers.parseDarwinNetstat(after),
    );
  }

  static NetworkInfo _delta(
    Map<String, (int, int)> priv,
    Map<String, (int, int)> curr,
  ) {
    final result = <NetworkElement>[];
    priv.forEach((device, previous) {
      final current = curr[device];
      if (current == null) return;
      final rx = current.$1 - previous.$1;
      final tx = current.$2 - previous.$2;
      // A counter that went backwards wrapped or reset; skip it this round.
      if (rx < 0 || tx < 0) return;
      result.add(NetworkElement(device, rx, tx));
    });
    result.sort((a, b) => a.device.compareTo(b.device));
    return NetworkInfo(result);
  }
}

class SystemInfo {
  const SystemInfo({
    this.releaseName = '',
    this.uptimeSec = 0,
    this.hostname = '',
    this.runningProcs = 0,
    this.totalProcs = 0,
    this.load1 = 0,
    this.load5 = 0,
    this.load15 = 0,
  });

  final String releaseName;
  final double uptimeSec;
  final String hostname;
  final int runningProcs, totalProcs;
  final double load1, load5, load15;
}

class SystemLoad {
  const SystemLoad({
    this.runningProcess = 0,
    this.totalProcess = 0,
    this.load1avg = 0,
    this.load5avg = 0,
    this.load15avg = 0,
  });

  final int runningProcess, totalProcess;
  final double load1avg, load5avg, load15avg;

  @override
  bool operator ==(Object other) =>
      other is SystemLoad &&
      other.runningProcess == runningProcess &&
      other.totalProcess == totalProcess &&
      other.load1avg == load1avg &&
      other.load5avg == load5avg &&
      other.load15avg == load15avg;

  @override
  int get hashCode =>
      Object.hash(runningProcess, totalProcess, load1avg, load5avg, load15avg);
}

class GraphicsUnit {
  const GraphicsUnit({
    required this.uuid,
    required this.name,
    required this.memoryTotal,
    required this.memoryUsed,
    required this.memoryFree,
    required this.fanSpeed,
    required this.gpuUtil,
    required this.memoryUtil,
    required this.encoderUtil,
    required this.decoderUtil,
  });

  final String uuid, name, fanSpeed;
  /// MiB, as nvidia-smi reports.
  final double memoryTotal, memoryUsed, memoryFree;
  final double gpuUtil, memoryUtil, encoderUtil, decoderUtil;
}

class GraphicsInfo {
  const GraphicsInfo({required this.version, required this.units});

  /// The CUDA version, like '12.4'.
  final String version;
  final List<GraphicsUnit> units;

  /// Parses `nvidia-smi -q -x`; null when there is no NVIDIA GPU.
  static GraphicsInfo? fromNvidiaSmi(String raw) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(raw.trim());
    } catch (_) {
      return null;
    }
    final root = document.rootElement;
    if (root.name.local != 'nvidia_smi_log') return null;
    String text(XmlElement? node, String name) =>
        node?.getElement(name)?.innerText.trim() ?? '';
    double number(XmlElement? node, String name) =>
        double.tryParse(text(node, name).split(' ').first) ?? 0;
    final units = <GraphicsUnit>[];
    for (final gpu in root.findElements('gpu')) {
      final memory = gpu.getElement('fb_memory_usage');
      final util = gpu.getElement('utilization');
      units.add(GraphicsUnit(
        uuid: text(gpu, 'uuid'),
        name: text(gpu, 'product_name'),
        memoryTotal: number(memory, 'total'),
        memoryUsed: number(memory, 'used'),
        memoryFree: number(memory, 'free'),
        fanSpeed: text(gpu, 'fan_speed'),
        gpuUtil: number(util, 'gpu_util'),
        memoryUtil: number(util, 'memory_util'),
        encoderUtil: number(util, 'encoder_util'),
        decoderUtil: number(util, 'decoder_util'),
      ));
    }
    return GraphicsInfo(version: text(root, 'cuda_version'), units: units);
  }
}

/// One complete reading of a server.
class ServerStatus {
  const ServerStatus({
    this.processor = const ProcessorInfo(),
    this.fileSystem = const FileSystemInfo(),
    this.memory = const MemoryInfo.empty(),
    this.system = const SystemInfo(),
    this.network = const NetworkInfo(),
    this.graphics,
  });

  final ProcessorInfo processor;
  final FileSystemInfo fileSystem;
  final MemoryInfo memory;
  final SystemInfo system;
  final NetworkInfo network;
  final GraphicsInfo? graphics;

  int get totalReceivePerSecond =>
      network.elements.fold(0, (sum, e) => sum + e.rxBytesPerSec);
  int get totalTransmitPerSecond =>
      network.elements.fold(0, (sum, e) => sum + e.txBytesPerSec);

  double get memoryUsedKB => math.max(
        0,
        memory.memTotal - memory.memFree - memory.memCached - memory.memBuffers,
      );
  double get memoryCacheKB => math.max(0, memory.memCached + memory.memBuffers);
  double get memoryUsedPercent =>
      memory.memTotal > 0 ? memoryUsedKB / memory.memTotal * 100 : 0;

  bool get hasData => system.hostname.isNotEmpty || memory.memTotal > 0;

  // MARK: Scripts

  /// The merged monitor script echoes this marker on its own line ahead of
  /// each section; only a full-line match opens a section.
  static const sectionMarkerPrefix = '<<<CATUSSH-SECTION:';
  static const sectionMarkerSuffix = '>>>';

  /// `nvidia-smi` stays a command of its own: it is slow and missing on most
  /// machines, and its failure must not cost the other sections.
  static const graphicsScript =
      'nvidia-smi -q -x | tr -d "[\\t\\n]" || echo "no nvidia gpu available"';

  /// One remote run that samples the CPU and network counters twice one
  /// second apart and reads every other payload behind markers.
  static String monitorScript({required bool includeStatic}) {
    final sections = <(String, String)>[
      ('platform', 'echo "\$CATUSSH_KERNEL"'),
      ('cpu-a', 'if [ "\$CATUSSH_KERNEL" != Darwin ]; then /bin/cat /proc/stat; fi'),
      ('net-a', 'if [ "\$CATUSSH_KERNEL" = Darwin ]; then /usr/sbin/netstat -ibn; else /bin/cat /proc/net/dev; fi'),
      ('darwin-top', 'if [ "\$CATUSSH_KERNEL" = Darwin ]; then /usr/bin/top -l 2 -n 0 -s 1; fi'),
      ('wait', 'if [ "\$CATUSSH_KERNEL" != Darwin ]; then /bin/sleep 1; fi'),
      ('cpu-b', 'if [ "\$CATUSSH_KERNEL" != Darwin ]; then /bin/cat /proc/stat; fi'),
      ('net-b', 'if [ "\$CATUSSH_KERNEL" = Darwin ]; then /usr/sbin/netstat -ibn; else /bin/cat /proc/net/dev; fi'),
      ('mem', 'if [ "\$CATUSSH_KERNEL" = Darwin ]; then /usr/sbin/sysctl hw.memsize hw.pagesize vm.swapusage; /usr/bin/vm_stat; else /bin/cat /proc/meminfo; fi'),
      ('df', '/bin/df -Pk'),
      ('uptime', 'if [ "\$CATUSSH_KERNEL" = Darwin ]; then /bin/date +%s; /usr/sbin/sysctl -n kern.boottime; else /bin/cat /proc/uptime; fi'),
      ('loadavg', 'if [ "\$CATUSSH_KERNEL" != Darwin ]; then /bin/cat /proc/loadavg; fi'),
      if (includeStatic) ...[
        // Arch and other minimal systems ship no `hostname`; uname -n always exists.
        ('hostname', '/bin/hostname 2>/dev/null || hostname 2>/dev/null || /usr/bin/uname -n 2>/dev/null || echo "localhost"'),
        ('os-release', 'if [ "\$CATUSSH_KERNEL" = Darwin ]; then /usr/bin/sw_vers; else /bin/cat /etc/os-release; fi'),
      ],
    ];
    final commands = sections.map(
      (s) => "echo '$sectionMarkerPrefix${s.$1}$sectionMarkerSuffix'\n${s.$2}",
    );
    return ['CATUSSH_KERNEL="\$(/usr/bin/uname -s)"', ...commands].join('\n');
  }

  /// Builds a reading from the merged script's output and the GPU probe's.
  /// [hostname] and [releaseName] are the once-per-connection readings.
  static ({ServerStatus status, String? hostname, String? releaseName}) parse({
    required String merged,
    required String graphics,
    String? cachedHostname,
    String? cachedRelease,
  }) {
    final sections = ProcParsers.splitMonitorSections(merged);
    final isDarwin = sections['platform']?.trim() == 'Darwin';

    var hostname = cachedHostname;
    var release = cachedRelease;
    final freshHost = (sections['hostname'] ?? '').replaceAll('\n', '');
    if (freshHost.isNotEmpty) hostname = freshHost;
    final releasePayload = (sections['os-release'] ?? '').trim();
    if (releasePayload.isNotEmpty) {
      release = isDarwin
          ? ProcParsers.parseDarwinReleaseName(releasePayload)
          : ProcParsers.parseOsReleaseName(releasePayload);
    }

    final ProcessorInfo processor;
    final NetworkInfo network;
    final MemoryInfo memory;
    final SystemLoad load;
    final double uptime;
    if (isDarwin) {
      processor = ProcessorInfo.fromDarwinTop(sections['darwin-top']) ?? const ProcessorInfo();
      network = NetworkInfo.fromNetstat(sections['net-a'], sections['net-b']) ?? const NetworkInfo();
      memory = MemoryInfo.fromDarwin(sections['mem'] ?? '');
      load = ProcParsers.parseDarwinTopLoad(sections['darwin-top'] ?? '');
      uptime = ProcParsers.parseDarwinUptime(sections['uptime'] ?? '');
    } else {
      processor = ProcessorInfo.fromStat(sections['cpu-a'], sections['cpu-b']) ?? const ProcessorInfo();
      network = NetworkInfo.fromNetDev(sections['net-a'], sections['net-b']) ?? const NetworkInfo();
      memory = MemoryInfo.fromMeminfo(sections['mem'] ?? '');
      load = ProcParsers.parseLoadavg(sections['loadavg'] ?? '');
      uptime = ProcParsers.parseUptime(sections['uptime'] ?? '');
    }
    final status = ServerStatus(
      processor: processor,
      network: network,
      memory: memory,
      fileSystem: FileSystemInfo.fromDfPk(sections['df'] ?? ''),
      system: SystemInfo(
        releaseName: release ?? '',
        uptimeSec: uptime,
        hostname: hostname ?? '',
        runningProcs: load.runningProcess,
        totalProcs: load.totalProcess,
        load1: load.load1avg,
        load5: load.load5avg,
        load15: load.load15avg,
      ),
      graphics: GraphicsInfo.fromNvidiaSmi(graphics),
    );
    return (status: status, hostname: hostname, releaseName: release);
  }
}

// MARK: - Parsers

class ProcParsers {
  static List<String> splitWhitespaceRuns(String line) =>
      line.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

  /// `/proc/meminfo` into upper-cased keys (values in kB).
  static Map<String, double> parseMeminfo(String raw) {
    final info = <String, double>{};
    for (var line in raw.split('\n')) {
      if (line.isEmpty) continue;
      line = line.replaceAll(':', '');
      final cut = splitWhitespaceRuns(line);
      if (cut.length != 3 || cut[2].toUpperCase() != 'KB') continue;
      final value = double.tryParse(cut[1]);
      if (value != null) info[cut[0].toUpperCase()] = value;
    }
    return info;
  }

  static ({ProcessInfoElement? summary, Map<String, ProcessInfoElement> cores})
      parseProcStat(String raw) {
    ProcessInfoElement? summary;
    final cores = <String, ProcessInfoElement>{};
    for (var line in raw.split('\n')) {
      line = line.trim();
      if (!line.startsWith('cpu')) continue;
      final e = splitWhitespaceRuns(line);
      if (e.length != 11) continue;
      double f(int i) => double.tryParse(e[i]) ?? 0;
      final element = ProcessInfoElement(
        user: f(1),
        nice: f(2),
        system: f(3),
        idle: f(4),
        iowait: f(5),
        irq: f(6),
        softIrq: f(7),
        steal: f(8),
        guest: f(9),
      );
      if (e[0] == 'cpu') {
        summary = element;
      } else {
        cores[e[0]] = element;
      }
    }
    return (summary: summary, cores: cores);
  }

  /// Zeros, not NaN, when the counters did not move.
  static ProcessPercentInfo calculatePercent(
    ProcessInfoElement priv,
    ProcessInfoElement curr,
  ) {
    final total = curr.total - priv.total;
    if (total <= 0) return const ProcessPercentInfo();
    return ProcessPercentInfo(
      sumSystem: (curr.system - priv.system) / total * 100,
      sumUser: (curr.user - priv.user) / total * 100,
      sumIOWait: (curr.iowait - priv.iowait) / total * 100,
      sumNice: (curr.nice - priv.nice) / total * 100,
      sumUsed: (curr.used - priv.used) / total * 100,
    );
  }

  static Map<String, String> splitMonitorSections(String raw) {
    final sections = <String, String>{};
    String? current;
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith(ServerStatus.sectionMarkerPrefix) &&
          trimmed.endsWith(ServerStatus.sectionMarkerSuffix)) {
        current = trimmed.substring(
          ServerStatus.sectionMarkerPrefix.length,
          trimmed.length - ServerStatus.sectionMarkerSuffix.length,
        );
        sections[current] = '';
        continue;
      }
      if (current != null) sections[current] = '${sections[current]}$line\n';
    }
    return sections;
  }

  static double parseUptime(String raw) {
    final fields = splitWhitespaceRuns(raw);
    return fields.isEmpty ? 0 : double.tryParse(fields.first) ?? 0;
  }

  static String stripSurroundingQuotes(String str) {
    if (str.length <= 2) return str;
    final quoted = (str.startsWith('"') && str.endsWith('"')) ||
        (str.startsWith("'") && str.endsWith("'"));
    return quoted ? str.substring(1, str.length - 1) : str;
  }

  static String parseOsReleaseName(String raw) {
    String? pretty;
    String? name;
    for (final item in raw.split('\n')) {
      if (item.startsWith('PRETTY_NAME=')) {
        pretty = item.substring('PRETTY_NAME='.length);
        break;
      }
      if (item.startsWith('NAME=')) name = item.substring('NAME='.length);
    }
    if (pretty != null) return stripSurroundingQuotes(pretty);
    if (name != null) return stripSurroundingQuotes(name);
    return 'Generic Linux';
  }

  static SystemLoad parseLoadavg(String raw) {
    final cut = splitWhitespaceRuns(raw);
    if (cut.length != 5) return const SystemLoad();
    final l1 = double.tryParse(cut[0]);
    final l5 = double.tryParse(cut[1]);
    final l15 = double.tryParse(cut[2]);
    final process = cut[3].split('/');
    if (l1 == null || l5 == null || l15 == null || process.length != 2) {
      return const SystemLoad();
    }
    final running = int.tryParse(process[0]);
    final total = int.tryParse(process[1]);
    if (running == null || total == null) return const SystemLoad();
    return SystemLoad(
      load1avg: l1,
      load5avg: l5,
      load15avg: l15,
      runningProcess: running,
      totalProcess: total,
    );
  }

  /// A 1024-block count the way `df -h` prints it ("935M", "98G", "1.8T").
  static String formatKilobytes(int kilobytes) {
    const units = ['K', 'M', 'G', 'T', 'P'];
    var value = kilobytes.toDouble();
    var index = 0;
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024;
      index += 1;
    }
    if (index == 0 || value >= 10) return '${value.round()}${units[index]}';
    return '${value.toStringAsFixed(1)}${units[index]}';
  }

  static List<FileSystemElement> parseDfPk(String raw) {
    final result = <FileSystemElement>[];
    for (final line in raw.split('\n').skip(1)) {
      if (line.isEmpty) continue;
      final cut = splitWhitespaceRuns(line);
      if (cut.length < 6) continue;
      final size = int.tryParse(cut[1]);
      final used = int.tryParse(cut[2]);
      final free = int.tryParse(cut[3]);
      if (size == null || used == null || free == null) continue;
      if (!cut[4].endsWith('%')) continue;
      final percent = double.tryParse(cut[4].substring(0, cut[4].length - 1));
      if (percent == null) continue;
      final mount = cut.sublist(5).join(' ');
      // Skip pseudo and empty filesystems (udev reports 0 available).
      if (!mount.startsWith('/') || free <= 0) continue;
      result.add(FileSystemElement(
        mountPoint: mount,
        size: formatKilobytes(size),
        used: formatKilobytes(used),
        free: formatKilobytes(free),
        percent: percent,
      ));
    }
    return result;
  }

  // MARK: Darwin

  static String? _lastLine(String raw, String prefix) {
    String? found;
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith(prefix)) found = trimmed;
    }
    return found;
  }

  static String _trimCommas(String s) => s.replaceAll(RegExp(r'^,+|,+$'), '');

  static ProcessPercentInfo? parseDarwinCPU(String raw) {
    final line = _lastLine(raw, 'CPU usage:');
    if (line == null) return null;
    final percentages = <String, double>{};
    for (final component in line.substring('CPU usage:'.length).split(',')) {
      final fields = splitWhitespaceRuns(component);
      if (fields.length != 2 || !fields[0].endsWith('%')) continue;
      final value = double.tryParse(fields[0].substring(0, fields[0].length - 1));
      if (value != null) percentages[fields[1]] = value;
    }
    final user = percentages['user'];
    final system = percentages['sys'];
    final idle = percentages['idle'];
    if (user == null || system == null || idle == null) return null;
    return ProcessPercentInfo(
      sumSystem: system,
      sumUser: user,
      sumUsed: math.max(0, 100 - idle),
    );
  }

  static SystemLoad parseDarwinTopLoad(String raw) {
    final loadLine = _lastLine(raw, 'Load Avg:');
    final processesLine = _lastLine(raw, 'Processes:');
    if (loadLine == null || processesLine == null) return const SystemLoad();
    final loads = splitWhitespaceRuns(loadLine.substring('Load Avg:'.length));
    final processes = splitWhitespaceRuns(processesLine);
    if (loads.length != 3 || processes.length < 5) return const SystemLoad();
    final l1 = double.tryParse(_trimCommas(loads[0]));
    final l5 = double.tryParse(_trimCommas(loads[1]));
    final l15 = double.tryParse(_trimCommas(loads[2]));
    final total = int.tryParse(processes[1]);
    final running = int.tryParse(processes[3]);
    if (l1 == null || l5 == null || l15 == null || total == null || running == null) {
      return const SystemLoad();
    }
    return SystemLoad(
      load1avg: l1,
      load5avg: l5,
      load15avg: l15,
      runningProcess: running,
      totalProcess: total,
    );
  }

  static double parseDarwinUptime(String raw) {
    final fields = splitWhitespaceRuns(raw);
    if (fields.isEmpty) return 0;
    final now = double.tryParse(fields.first);
    final secIndex = fields.indexOf('sec');
    if (now == null || secIndex < 0 || secIndex + 2 >= fields.length) return 0;
    if (fields[secIndex + 1] != '=') return 0;
    final boot = double.tryParse(_trimCommas(fields[secIndex + 2]));
    if (boot == null) return 0;
    return math.max(0, now - boot);
  }

  static String parseDarwinReleaseName(String raw) {
    String? productName;
    String? productVersion;
    for (final line in raw.split('\n')) {
      final colon = line.indexOf(':');
      if (colon < 0) continue;
      final key = line.substring(0, colon).trim();
      final value = line.substring(colon + 1).trim();
      if (key == 'ProductName') productName = value;
      if (key == 'ProductVersion') productVersion = value;
    }
    if (productName != null && productVersion != null) {
      return '$productName $productVersion';
    }
    return productName ?? 'macOS';
  }

  static double _darwinKilobytes(String token) {
    final text = token.trim();
    if (text.isEmpty) return 0;
    const scales = {'K': 1.0, 'M': 1024.0, 'G': 1048576.0, 'T': 1073741824.0};
    final scale = scales[text[text.length - 1].toUpperCase()];
    if (scale != null) {
      final value = double.tryParse(text.substring(0, text.length - 1));
      if (value != null) return value * scale;
    }
    return double.tryParse(text) ?? 0;
  }

  static ({double total, double free, double cached, double swapTotal, double swapFree})
      parseDarwinMemory(String raw) {
    var total = 0.0;
    var pageSize = 0.0;
    final pages = <String, double>{};
    var swapTotal = 0.0;
    var swapFree = 0.0;
    final lines = raw.split('\n');
    for (final line in lines) {
      final colon = line.indexOf(':');
      if (colon < 0) continue;
      final key = line.substring(0, colon).trim();
      final value = line.substring(colon + 1).trim();
      switch (key) {
        case 'hw.memsize':
          total = (double.tryParse(value) ?? 0) / 1024;
        case 'hw.pagesize':
          pageSize = double.tryParse(value) ?? 0;
        case 'vm.swapusage':
          final f = splitWhitespaceRuns(value);
          final t = f.indexOf('total');
          if (t >= 0 && t + 2 < f.length) swapTotal = _darwinKilobytes(f[t + 2]);
          final fr = f.indexOf('free');
          if (fr >= 0 && fr + 2 < f.length) swapFree = _darwinKilobytes(f[fr + 2]);
        case 'Pages free' || 'Pages speculative' || 'File-backed pages':
          final v = double.tryParse(value.replaceAll(RegExp(r'^\.+|\.+$'), ''));
          if (v != null) pages[key] = v;
      }
    }
    if (pageSize == 0) {
      for (final header in lines) {
        if (!header.contains('page size of')) continue;
        final f = splitWhitespaceRuns(header);
        final i = f.indexOf('of');
        if (i >= 0 && i + 1 < f.length) pageSize = double.tryParse(f[i + 1]) ?? 0;
        break;
      }
    }
    final freePages = (pages['Pages free'] ?? 0) + (pages['Pages speculative'] ?? 0);
    final cachedPages = math.max(
      0.0,
      (pages['File-backed pages'] ?? 0) - (pages['Pages speculative'] ?? 0),
    );
    final kbPerPage = pageSize / 1024;
    return (
      total: total,
      free: freePages * kbPerPage,
      cached: cachedPages * kbPerPage,
      swapTotal: swapTotal,
      swapFree: swapFree,
    );
  }

  static Map<String, (int, int)> parseDarwinNetstat(String raw) {
    final result = <String, (int, int)>{};
    for (final line in raw.split('\n')) {
      final f = splitWhitespaceRuns(line);
      if (f.length < 10 || !f[2].startsWith('<Link#')) continue;
      final rx = int.tryParse(f[f.length - 5]);
      final tx = int.tryParse(f[f.length - 2]);
      if (rx == null || tx == null) continue;
      var device = f[0];
      if (device.endsWith('*')) device = device.substring(0, device.length - 1);
      result[device] = (rx, tx);
    }
    return result;
  }
}
