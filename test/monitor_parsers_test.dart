// Ported from ProcParsersTests.swift and DarwinParsersTests.swift.

import 'package:catussh/monitor/server_status.dart';
import 'package:flutter_test/flutter_test.dart';

const meminfoFixture = '''
MemTotal:       16384000 kB
MemFree:         1024000 kB
MemAvailable:    8192000 kB
Buffers:          512000 kB
Cached:          4096000 kB
SwapCached:            0 kB
SwapTotal:       2097152 kB
SwapFree:        1048576 kB
HugePages_Total:       0
Hugepagesize:       2048 kB''';

const procStatFixture = '''
cpu  100 0 200 1600 50 0 10 0 0 0
cpu0 50 0 100 800 25 0 5 0 0 0
cpu1 50 0 100 800 25 0 5 0 0 0
intr 123456''';

const mergedOutputFixture = '''
<<<CATUSSH-SECTION:cpu-a>>>
cpu  100 0 200 1600 50 0 10 0 0 0
cpu0 50 0 100 800 25 0 5 0 0 0
<<<CATUSSH-SECTION:net-a>>>
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo: 1000      10    0    0    0     0          0         0     1000      10    0    0    0     0       0          0
  eth0: 5000      50    0    0    0     0          0         0     2000      20    0    0    0     0       0          0
<<<CATUSSH-SECTION:wait>>>
<<<CATUSSH-SECTION:cpu-b>>>
cpu  200 0 300 3200 100 0 20 0 0 0
cpu0 100 0 150 1600 50 0 10 0 0 0
<<<CATUSSH-SECTION:uptime>>>
773229.50 1531748.20
<<<CATUSSH-SECTION:hostname>>>
web-01''';

const dfPkFixture = '''
Filesystem                        1024-blocks     Used Available Capacity Mounted on
udev                                 8192000        0   8192000       0% /dev
tmpfs                                1638400   124928   1513472       8% /run
/dev/mapper/ubuntu--vg-ubuntu--lv   51281224 15994688  32923552      33% /
tmpfs                                8192000        0   8192000       0% /dev/shm
tmpfs                                   5120        0      5120       0% /run/lock
none                                       0        0         0       0% /sys/fs/cgroup
/dev/sda2                            1959920   251792   1606088      14% /boot
/dev/sdb1                          976762532 6185396 920562116       1% /media/My Passport''';

const topFixture = '''
Processes: 700 total, 10 running, 690 sleeping, 3000 threads
Load Avg: 1.11, 2.22, 3.33
CPU usage: 10.0% user, 20.0% sys, 70.0% idle
PhysMem: 10G used, 6G unused.
Processes: 743 total, 14 running, 729 sleeping, 3558 threads
Load Avg: 98.70, 115.18, 55.43
CPU usage: 50.31% user, 32.91% sys, 16.77% idle
PhysMem: 15G used, 90M unused.''';

int occurrences(String haystack, String needle) => needle.allMatches(haystack).length;

void main() {
  group('/proc/meminfo', () {
    test('parses keyed values', () {
      final info = ProcParsers.parseMeminfo(meminfoFixture);
      expect(info['MEMTOTAL'], 16384000);
      expect(info['MEMFREE'], 1024000);
      expect(info['BUFFERS'], 512000);
      expect(info['CACHED'], 4096000);
      expect(info['SWAPTOTAL'], 2097152);
      expect(info['SWAPFREE'], 1048576);
      expect(info['HUGEPAGESIZE'], 2048);
      expect(info['HUGEPAGES_TOTAL'], isNull);
    });

    test('swap usage is relative to swap total', () {
      final info = MemoryInfo(
        total: 16384000, free: 1024000, buffers: 512000, cached: 4096000,
        swapTotal: 2097152, swapFree: 1048576,
      );
      expect(info.swapUsed, closeTo(0.5, 0.001));
      expect(info.phyUsed, closeTo((16384000 - 1024000 - 4096000 - 512000) / 16384000, 0.001));
    });

    test('zero swap does not divide by zero', () {
      final info = MemoryInfo(total: 16384000, free: 1024000, buffers: 0, cached: 0, swapTotal: 0, swapFree: 0);
      expect(info.swapUsed, 0);
      expect(info.swapUsed.isNaN, isFalse);
    });
  });

  group('/proc/stat', () {
    test('parses summary and cores', () {
      final r = ProcParsers.parseProcStat(procStatFixture);
      expect(r.summary!.user, 100);
      expect(r.summary!.idle, 1600);
      expect(r.cores['cpu0']!.system, 100);
      expect(r.cores['cpu1']!.iowait, 25);
      expect(r.cores.length, 2);
    });

    test('percentage between samples', () {
      final priv = ProcParsers.parseProcStat(procStatFixture).summary!;
      final curr = ProcParsers.parseProcStat(procStatFixture.replaceFirst('cpu  100', 'cpu  200')).summary!;
      final percent = ProcParsers.calculatePercent(priv, curr);
      expect(percent.sumUser, closeTo(100, 0.01));
      expect(percent.sumUsed, closeTo(100, 0.01));
    });

    test('identical samples yield zero, not NaN', () {
      final sum = ProcParsers.parseProcStat(procStatFixture).summary!;
      final percent = ProcParsers.calculatePercent(sum, sum);
      expect(percent.sumUsed, 0);
      expect(percent.sumUsed.isNaN, isFalse);
      expect(percent.sumSystem.isInfinite, isFalse);
    });

    test('cores are ordered numerically', () {
      final info = ProcessorInfo.withCores(const ProcessPercentInfo(), {
        for (final i in [10, 2, 1, 0]) 'cpu$i': const ProcessPercentInfo(),
      });
      expect(info.cores.map((c) => c.name), ['cpu0', 'cpu1', 'cpu2', 'cpu10']);
    });
  });

  group('/etc/os-release', () {
    test('prefers PRETTY_NAME and strips double quotes', () {
      expect(
        ProcParsers.parseOsReleaseName('NAME="Ubuntu"\nVERSION_ID="22.04"\nPRETTY_NAME="Ubuntu 22.04.1 LTS"'),
        'Ubuntu 22.04.1 LTS',
      );
    });
    test('falls back to NAME', () {
      expect(ProcParsers.parseOsReleaseName('NAME="Debian GNU/Linux"'), 'Debian GNU/Linux');
    });
    test('strips single quotes', () {
      expect(ProcParsers.parseOsReleaseName("NAME='Fedora Linux'"), 'Fedora Linux');
    });
    test('unquoted and missing', () {
      expect(ProcParsers.parseOsReleaseName('NAME=Alpine Linux'), 'Alpine Linux');
      expect(ProcParsers.parseOsReleaseName(''), 'Generic Linux');
    });
  });

  group('/proc/loadavg', () {
    test('parses', () {
      final load = ProcParsers.parseLoadavg('0.27 0.34 0.39 2/916 23817');
      expect(load.load1avg, closeTo(0.27, 0.001));
      expect(load.load5avg, closeTo(0.34, 0.001));
      expect(load.load15avg, closeTo(0.39, 0.001));
      expect(load.runningProcess, 2);
      expect(load.totalProcess, 916);
    });
    test('malformed returns zero', () {
      final load = ProcParsers.parseLoadavg('garbage');
      expect(load.load1avg, 0);
      expect(load.totalProcess, 0);
    });
  });

  group('merged monitor script', () {
    test('assigns payloads to sections', () {
      final s = ProcParsers.splitMonitorSections(mergedOutputFixture);
      expect(s['cpu-a']!.contains('cpu0 50'), isTrue);
      expect(s['net-a']!.contains('eth0:'), isTrue);
      expect(s['uptime']!.trim(), '773229.50 1531748.20');
      expect(s['hostname']!.trim(), 'web-01');
      expect(s['wait']!.trim(), '');
      expect(s['cpu-b']!.contains('cpu0 50'), isFalse);
    });

    test('ignores inline marker lookalikes', () {
      final s = ProcParsers.splitMonitorSections(
        '<<<CATUSSH-SECTION:df>>>\n/dev/sda1 100 50 50 50% /mnt/<<<CATUSSH-SECTION:mem>>>-disk',
      );
      expect(s['mem'], isNull);
      expect(s['df']!.contains('/mnt/<<<CATUSSH-SECTION:mem>>>-disk'), isTrue);
    });

    test('tolerates carriage returns', () {
      final s = ProcParsers.splitMonitorSections(
        '<<<CATUSSH-SECTION:hostname>>>\r\nweb-01\r\n<<<CATUSSH-SECTION:uptime>>>\r\n42 84\r\n',
      );
      expect(s['hostname']!.trim(), 'web-01');
      expect(ProcParsers.parseUptime(s['uptime']!), 42);
    });

    test('samples counters twice around one sleep', () {
      final script = ServerStatus.monitorScript(includeStatic: true);
      expect(occurrences(script, '/bin/cat /proc/stat'), 2);
      expect(occurrences(script, '/bin/cat /proc/net/dev'), 2);
      expect(occurrences(script, '/bin/sleep 1'), 1);
      for (final section in ['cpu-a', 'net-a', 'cpu-b', 'net-b', 'mem', 'df', 'uptime', 'loadavg', 'hostname', 'os-release']) {
        expect(
          script.contains("echo '${ServerStatus.sectionMarkerPrefix}$section${ServerStatus.sectionMarkerSuffix}'"),
          isTrue,
          reason: 'missing marker for $section',
        );
      }
    });

    test('omits statics unless asked', () {
      final script = ServerStatus.monitorScript(includeStatic: false);
      expect(script.contains('os-release'), isFalse);
      expect(script.contains('hostname'), isFalse);
      expect(occurrences(script, '/bin/sleep 1'), 1);
    });

    test('a whole reading parses', () {
      final parsed = ServerStatus.parse(merged: mergedOutputFixture, graphics: 'no nvidia gpu available');
      final status = parsed.status;
      expect(status.system.hostname, 'web-01');
      expect(parsed.hostname, 'web-01');
      // The fixture has no second network sample, so no rates.
      expect(status.network.elements, isEmpty);
      final withSecond = ServerStatus.parse(
        merged: mergedOutputFixture.replaceFirst(
          '<<<CATUSSH-SECTION:uptime>>>',
          '<<<CATUSSH-SECTION:net-b>>>\n  eth0: 6000 0 0 0 0 0 0 0 2500 0 0 0 0 0 0 0\n    lo: 1000 0 0 0 0 0 0 0 1000 0 0 0 0 0 0 0\n<<<CATUSSH-SECTION:uptime>>>',
        ),
        graphics: '',
      ).status;
      expect(withSecond.network.elements.map((e) => e.device), ['eth0', 'lo']);
      expect(withSecond.totalReceivePerSecond, 1000);
      expect(withSecond.totalTransmitPerSecond, 500);
      expect(status.processor.cores.length, 1);
      expect(status.graphics, isNull);
    });
  });

  group('/proc/uptime', () {
    test('reads first field', () {
      expect(ProcParsers.parseUptime('773229.50 1531748.20\n'), closeTo(773229.5, 0.001));
      expect(ProcParsers.parseUptime('42'), 42);
      expect(ProcParsers.parseUptime('garbage'), 0);
      expect(ProcParsers.parseUptime(''), 0);
    });
  });

  group('df -Pk', () {
    test('parses numeric columns', () {
      final root = ProcParsers.parseDfPk(dfPkFixture).firstWhere((e) => e.mountPoint == '/');
      expect(root.size, '49G');
      expect(root.used, '15G');
      expect(root.free, '31G');
      expect(root.percent, 33);
    });
    test('keeps long device names', () {
      final elements = ProcParsers.parseDfPk(dfPkFixture);
      expect(elements.any((e) => e.mountPoint == '/'), isTrue);
      expect(elements.length, 7);
    });
    test('keeps spaces in mount point and skips empty filesystems', () {
      final elements = ProcParsers.parseDfPk(dfPkFixture);
      final mounted = elements.firstWhere((e) => e.mountPoint == '/media/My Passport');
      expect(mounted.size, '932G');
      expect(mounted.used, '5.9G');
      expect(elements.any((e) => e.mountPoint == '/sys/fs/cgroup'), isFalse);
    });
    test('formats kilobytes like df -h', () {
      expect(ProcParsers.formatKilobytes(957440), '935M');
      expect(ProcParsers.formatKilobytes(512), '512K');
      expect(ProcParsers.formatKilobytes(1945600), '1.9G');
    });
  });

  group('Darwin', () {
    test('top uses last sample for CPU and load', () {
      final processor = ProcessorInfo.fromDarwinTop(topFixture)!;
      expect(processor.summary.sumUser, closeTo(50.31, 0.001));
      expect(processor.summary.sumSystem, closeTo(32.91, 0.001));
      expect(processor.summary.sumUsed, closeTo(83.23, 0.001));
      expect(processor.cores.length, 0);
      final load = ProcParsers.parseDarwinTopLoad(topFixture);
      expect(load.load1avg, closeTo(98.70, 0.001));
      expect(load.load5avg, closeTo(115.18, 0.001));
      expect(load.load15avg, closeTo(55.43, 0.001));
      expect(load.runningProcess, 14);
      expect(load.totalProcess, 743);
    });

    test('malformed top returns no reading', () {
      expect(ProcessorInfo.fromDarwinTop('not top output'), isNull);
      expect(ProcParsers.parseDarwinTopLoad('not top output'), const SystemLoad());
    });

    test('memory uses page size and swap units', () {
      const fixture = '''
hw.memsize: 17179869184
hw.pagesize: 16384
vm.swapusage: total = 2048.00M  used = 512.00M  free = 1536.00M  (encrypted)
Mach Virtual Memory Statistics: (page size of 16384 bytes)
Pages free:                                     4497.
Pages speculative:                              1547.
Pages occupied by compressor:                  21904.
File-backed pages:                            407513.
Anonymous pages:                              486560.''';
      final memory = MemoryInfo.fromDarwin(fixture);
      expect(memory.memTotal, 16777216);
      expect(memory.memFree, 96704);
      expect(memory.memCached, 6495456);
      expect(memory.memBuffers, 0);
      expect(memory.swapTotal, 2097152);
      expect(memory.swapFree, 1572864);
      expect(memory.swapUsed, closeTo(0.25, 0.001));
      expect(memory.phyUsed, greaterThan(0));
      expect(memory.phyUsed, lessThan(1));
    });

    test('memory falls back to vm_stat page size', () {
      const fixture = '''
hw.memsize: 8589934592
Mach Virtual Memory Statistics: (page size of 4096 bytes)
Pages free: 1000.
Pages speculative: 500.
File-backed pages: 2000.''';
      final memory = MemoryInfo.fromDarwin(fixture);
      expect(memory.memFree, 6000);
      expect(memory.memCached, 6000);
    });

    test('netstat reads link rows and optional address column', () {
      const before = '''
Name       Mtu   Network       Address            Ipkts Ierrs     Ibytes    Opkts Oerrs     Obytes  Coll
lo0        16384 <Link#1>                          10     0       100       10     0       100     0
en0        1500  <Link#11>   be:c4:9b:88:a5:08    20     0      1000       30     0      2000     0
gif0*      1280  <Link#2>                             0     0         0        0     0         0     0
en0        1500  192.168.31    192.168.31.241      20     -      1000       30     -      2000     -''';
      const after = '''
lo0        16384 <Link#1>                          15     0       150       20     0       250     0
en0        1500  <Link#11>   be:c4:9b:88:a5:08    25     0      3000       40     0      6000     0
gif0       1280  <Link#2>                             1     0        64        2     0       128     0''';
      final network = NetworkInfo.fromNetstat(before, after)!;
      NetworkElement d(String n) => network.elements.firstWhere((e) => e.device == n);
      expect(network.elements.length, 3);
      expect(d('en0').rxBytesPerSec, 2000);
      expect(d('en0').txBytesPerSec, 4000);
      expect(d('lo0').rxBytesPerSec, 50);
      expect(d('gif0').txBytesPerSec, 128);
    });

    test('uptime and release name', () {
      expect(ProcParsers.parseDarwinUptime('1000\n{ sec = 750, usec = 912078 } Sat Oct 17 21:39:26 2026\n'), 250);
      expect(ProcParsers.parseDarwinUptime('garbage'), 0);
      expect(
        ProcParsers.parseDarwinReleaseName('ProductName:            macOS\nProductVersion:         27.2\nBuildVersion:           26B5112a'),
        'macOS 27.2',
      );
    });

    test('script contains Darwin probes and Linux fallbacks', () {
      final script = ServerStatus.monitorScript(includeStatic: true);
      for (final probe in [
        '/usr/bin/top -l 2 -n 0 -s 1',
        '/usr/sbin/netstat -ibn',
        '/usr/bin/vm_stat',
        'vm.swapusage',
        '/usr/bin/sw_vers',
        'kern.boottime',
        '/bin/cat /proc/meminfo',
      ]) {
        expect(script.contains(probe), isTrue, reason: probe);
      }
    });
  });

  group('nvidia-smi', () {
    test('parses GPUs from XML', () {
      const xml = '<?xml version="1.0" ?><nvidia_smi_log><driver_version>550.54</driver_version>'
          '<cuda_version>12.4</cuda_version><attached_gpus>1</attached_gpus>'
          '<gpu id="00000000:01:00.0"><product_name>NVIDIA GeForce RTX 4090</product_name>'
          '<uuid>GPU-1234</uuid><fan_speed>30 %</fan_speed>'
          '<fb_memory_usage><total>24564 MiB</total><reserved>300 MiB</reserved><used>1024 MiB</used><free>23240 MiB</free></fb_memory_usage>'
          '<utilization><gpu_util>17 %</gpu_util><memory_util>3 %</memory_util><encoder_util>0 %</encoder_util><decoder_util>0 %</decoder_util></utilization>'
          '</gpu></nvidia_smi_log>';
      final info = GraphicsInfo.fromNvidiaSmi(xml)!;
      expect(info.version, '12.4');
      expect(info.units.single.name, 'NVIDIA GeForce RTX 4090');
      expect(info.units.single.memoryTotal, 24564);
      expect(info.units.single.gpuUtil, 17);
    });

    test('no GPU reads as none', () {
      expect(GraphicsInfo.fromNvidiaSmi('no nvidia gpu available'), isNull);
      expect(GraphicsInfo.fromNvidiaSmi(''), isNull);
    });
  });
}
