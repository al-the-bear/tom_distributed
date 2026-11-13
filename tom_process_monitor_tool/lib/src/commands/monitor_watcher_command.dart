import 'dart:async';

import '../cli_runner.dart';

/// Command handler for the monitor_watcher CLI (on tom_build_base's
/// ToolRunner, [monitorWatcherTool]).
class MonitorWatcherCommand {
  /// Runs the monitor_watcher command with the given arguments; answers the
  /// exit code.
  Future<int> run(List<String> args) => runMonitorTool(
    monitorWatcherTool,
    MonitorExecutor(
      label: 'MonitorWatcher',
      defaultInstance: 'watcher',
      remotePort: 19882,
    ),
    args,
  );
}
