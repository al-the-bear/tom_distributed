import 'package:test/test.dart';
import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:tom_process_monitor_tool/tom_process_monitor_tool.dart';
import 'package:tom_process_monitor_tool/src/version.versioner.dart';

/// process_monitor / monitor_watcher on tom_build_base's ToolRunner.
///
/// Test IDs: PMT-CLI-1..6.
void main() {
  Map<String, dynamic> options(List<String> args) =>
      CliArgParser(toolDefinition: processMonitorTool).parse(args).extraOptions;

  test('PMT-CLI-1: the installer\'s LaunchAgent arguments '
      '(--foreground --directory <dir>)', () {
    final o = options(['--foreground', '--directory', '/Users/x/pm']);
    expect(o['foreground'], isTrue);
    expect(o['directory'], '/Users/x/pm');
    expect(o['instance'], isNull);
  });

  test('PMT-CLI-2: a monitor\'s partner start (--foreground --instance '
      'watcher --directory <dir>) and the = forms', () {
    final partner = options([
      '--foreground',
      '--instance',
      'watcher',
      '--directory',
      '/d',
    ]);
    expect(
      (partner['foreground'], partner['instance'], partner['directory']),
      (true, 'watcher', '/d'),
    );
    final eq = options(['--instance=watcher', '--directory=/e', '-f']);
    expect(
      (eq['instance'], eq['directory'], eq['foreground']),
      ('watcher', '/e', true),
    );
    expect(options(['-d', '/f'])['directory'], '/f');
    for (final flag in ['stop', 'status', 'restart']) {
      expect(options(['--$flag'])[flag], isTrue);
    }
  });

  test('PMT-CLI-3: the background start re-launches with the options only '
      '(a compiled binary) or after the script (the Dart VM)', () {
    expect(
      detachedStartArguments(
        script: '/bin/process_monitor',
        instanceId: 'default',
        directory: '/d',
      ),
      ['--foreground', '--instance=default', '--directory=/d'],
    );
    expect(
      detachedStartArguments(
        script: '/x/bin/process_monitor.dart',
        instanceId: 'w',
      ),
      ['/x/bin/process_monitor.dart', '--foreground', '--instance=w'],
    );
  });

  test('PMT-CLI-4: --version prints the versioner\'s version', () async {
    final out = StringBuffer();
    final code = await runMonitorTool(
      processMonitorTool,
      MonitorExecutor(
        label: 'ProcessMonitor',
        defaultInstance: 'default',
        remotePort: 1,
      ),
      ['--version'],
      output: out,
    );
    expect(code, 0);
    expect(
      out.toString().split('\n').first,
      'process_monitor ${ProcessMonitorToolVersionInfo.versionLong}',
    );
  });

  test(
    'PMT-CLI-5: --help names the options, not the hidden --instance',
    () async {
      final out = StringBuffer();
      final code = await runMonitorTool(
        monitorWatcherTool,
        MonitorExecutor(
          label: 'MonitorWatcher',
          defaultInstance: 'watcher',
          remotePort: 1,
        ),
        ['--help'],
        output: out,
      );
      expect(code, 0);
      final text = out.toString();
      for (final name in [
        '--directory',
        '--foreground',
        '--stop',
        '--status',
        '--restart',
      ]) {
        expect(text, contains(name));
      }
      expect(text, isNot(contains('--instance')));
    },
  );

  // The client retries with backoff before it gives up (as before the move
  // to ToolRunner), which takes longer than the default 30 s.
  test(
    'PMT-CLI-6: --status against no running instance exits 1',
    timeout: const Timeout(Duration(minutes: 3)),
    () async {
      final code = await runMonitorTool(
        processMonitorTool,
        // Port 1: nothing listens there, so the status call fails.
        MonitorExecutor(
          label: 'ProcessMonitor',
          defaultInstance: 'default',
          remotePort: 1,
        ),
        ['--status'],
        output: StringBuffer(),
      );
      expect(code, 1);
    },
  );
}
