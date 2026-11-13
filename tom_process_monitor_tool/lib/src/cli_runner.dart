import 'dart:async';
import 'dart:io';

import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:tom_process_monitor/tom_process_monitor.dart';

import 'version.versioner.dart';

/// The options of `process_monitor` and `monitor_watcher`. The installer's
/// LaunchAgent starts `--foreground --directory <dir>`; a ProcessMonitor
/// starts its partner with `--foreground --instance watcher --directory <dir>`.
const monitorOptions = [
  OptionDefinition.option(
    name: 'directory',
    abbr: 'd',
    description:
        'Base directory for the monitor\'s files '
        '(default ~/.tom/process_monitor/)',
    valueName: 'dir',
  ),
  OptionDefinition.flag(
    name: 'foreground',
    abbr: 'f',
    description: 'Run in the foreground (do not detach)',
  ),
  OptionDefinition.flag(name: 'stop', description: 'Stop the running instance'),
  OptionDefinition.flag(
    name: 'status',
    description: 'Show the status of the running instance',
  ),
  OptionDefinition.flag(
    name: 'restart',
    description: 'Restart the running instance',
  ),
  OptionDefinition.option(
    name: 'instance',
    description: 'Instance id (watcher: the MonitorWatcher)',
    hidden: true,
  ),
];

ToolDefinition _monitorTool(String name, String description) => ToolDefinition(
  name: name,
  description: description,
  version: ProcessMonitorToolVersionInfo.version,
  versionString: '$name ${ProcessMonitorToolVersionInfo.versionLong}',
  mode: ToolMode.singleCommand,
  features: NavigationFeatures.minimal,
  globalOptions: monitorOptions,
);

/// `process_monitor`: starts, stops and queries the ProcessMonitor.
final processMonitorTool = _monitorTool(
  'process_monitor',
  'Start, stop and query the Tom ProcessMonitor',
);

/// `monitor_watcher`: the same for the MonitorWatcher instance.
final monitorWatcherTool = _monitorTool(
  'monitor_watcher',
  'Start, stop and query the Tom MonitorWatcher',
);

/// Runs one monitor instance or talks to the running one, from the options
/// of [monitorOptions].
class MonitorExecutor extends CommandExecutor {
  /// Shown in messages: `ProcessMonitor` or `MonitorWatcher`.
  final String label;

  /// The instance id when `--instance` is not given.
  final String defaultInstance;

  /// The port of the running instance's remote API.
  final int remotePort;

  /// Creates the executor for one of the two tools.
  MonitorExecutor({
    required this.label,
    required this.defaultInstance,
    required this.remotePort,
  });

  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async =>
      ItemResult.success(path: context.path, name: context.name);

  @override
  Future<ToolResult> executeWithoutTraversal(CliArgs args) async {
    final o = args.extraOptions;
    final directory = o['directory'] as String?;
    final instanceId = (o['instance'] as String?) ?? defaultInstance;
    RemoteProcessMonitorClient client() =>
        RemoteProcessMonitorClient(baseUrl: 'http://localhost:$remotePort');

    final int code;
    if (o['stop'] == true) {
      code = await _stop(client());
    } else if (o['status'] == true) {
      code = await _status(client());
    } else if (o['restart'] == true) {
      code = await _restart(client());
    } else {
      code = await _start(
        instanceId: instanceId,
        directory: directory,
        foreground: o['foreground'] == true,
      );
    }
    return code == 0
        ? const ToolResult.success()
        : ToolResult.failure('$label: exit $code');
  }

  Future<int> _stop(RemoteProcessMonitorClient client) async {
    try {
      await client.restartMonitor();
      stdout.writeln('$label stop signal sent.');
      return 0;
    } catch (_) {
      stderr.writeln('$label is not running or unreachable.');
      return 1;
    } finally {
      client.dispose();
    }
  }

  Future<int> _status(RemoteProcessMonitorClient client) async {
    try {
      final status = await client.getMonitorStatus();
      stdout.writeln('$label Status:');
      stdout.writeln('  Instance: ${status.instanceId}');
      stdout.writeln('  State: ${status.state}');
      stdout.writeln('  PID: ${status.pid}');
      stdout.writeln('  Uptime: ${status.uptime}s');
      stdout.writeln('  Managed Processes: ${status.managedProcessCount}');
      stdout.writeln('  Running Processes: ${status.runningProcessCount}');
      stdout.writeln('  Standalone Mode: ${status.standaloneMode}');
      return 0;
    } catch (_) {
      stderr.writeln('$label is not running or unreachable.');
      return 1;
    } finally {
      client.dispose();
    }
  }

  Future<int> _restart(RemoteProcessMonitorClient client) async {
    try {
      await client.restartMonitor();
      stdout.writeln('$label restart initiated.');
      return 0;
    } catch (e) {
      stderr.writeln('Error restarting $label: $e');
      return 1;
    } finally {
      client.dispose();
    }
  }

  Future<int> _start({
    required String instanceId,
    String? directory,
    required bool foreground,
  }) async {
    final name = instanceId == 'watcher' ? 'Watcher' : 'ProcessMonitor';
    final monitor = ProcessMonitor(
      instanceId: instanceId,
      directory: directory,
    );

    if (foreground) {
      stdout.writeln('Starting $name in foreground...');
      stdout.writeln('Press Ctrl+C to stop.');

      final completer = Completer<void>();
      final signals = [
        ProcessSignal.sigint.watch().listen((_) async {
          stdout.writeln('\nShutting down $name...');
          await monitor.stop();
          if (!completer.isCompleted) completer.complete();
        }),
        ProcessSignal.sigterm.watch().listen((_) async {
          await monitor.stop();
          if (!completer.isCompleted) completer.complete();
        }),
      ];

      await monitor.start();
      await completer.future;
      // Why: an open signal subscription keeps the process alive, so after
      // the monitor stopped it would never exit (the LaunchAgent then sees a
      // hung process instead of an exit it can restart).
      for (final subscription in signals) {
        await subscription.cancel();
      }
      return 0;
    }

    stdout.writeln('Starting $name in background...');
    final process = await Process.start(
      Platform.resolvedExecutable,
      detachedStartArguments(
        script: Platform.script.toFilePath(),
        instanceId: instanceId,
        directory: directory,
      ),
      mode: ProcessStartMode.detached,
    );
    stdout.writeln('$name started with PID: ${process.pid}');
    return 0;
  }
}

/// The arguments the background start re-launches itself with. Under the Dart
/// VM ([script] a `.dart`, `.dill` or snapshot file) the script comes first;
/// a compiled binary is its own executable, so it gets the options only.
List<String> detachedStartArguments({
  required String script,
  required String instanceId,
  String? directory,
}) {
  final runsAsScript =
      script.endsWith('.dart') ||
      script.endsWith('.dill') ||
      script.endsWith('.snapshot');
  return [
    if (runsAsScript) script,
    '--foreground',
    '--instance=$instanceId',
    if (directory != null) '--directory=$directory',
  ];
}

/// Runs [tool] with [executor] on [args] and answers the exit code (0, or 1
/// when the command failed). Output is the tool's own; no run summary.
Future<int> runMonitorTool(
  ToolDefinition tool,
  MonitorExecutor executor,
  List<String> args, {
  StringSink? output,
}) async {
  final result = await ToolRunner(
    tool: tool,
    executors: {'default': executor},
    output: output,
  ).run(args);
  return result.exitCode;
}
