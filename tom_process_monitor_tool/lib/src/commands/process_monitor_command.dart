import 'dart:async';

import '../cli_runner.dart';

/// Command handler for the process_monitor CLI (on tom_build_base's
/// ToolRunner, [processMonitorTool]).
class ProcessMonitorCommand {
  /// Runs the process_monitor command with the given arguments; answers the
  /// exit code.
  Future<int> run(List<String> args) => runMonitorTool(
    processMonitorTool,
    MonitorExecutor(
      label: 'ProcessMonitor',
      defaultInstance: 'default',
      remotePort: 19881,
    ),
    args,
  );
}
