/// The `process_monitor` executable: the ProcessMonitor CLI
/// (`lib/src/cli_runner.dart`). Compiled into the binaries layer by buildkit
/// (`buildkit.yaml` `compiler:`); the macOS installer
/// (`tool/setup_autostart_macos.sh`) copies it from there as
/// `Tom Process Monitor`. Run with `--instance=watcher`, the same binary is
/// the MonitorWatcher.
library;

import 'dart:io';

import 'package:tom_process_monitor_tool/tom_process_monitor_tool.dart';

Future<void> main(List<String> args) async {
  exitCode = await ProcessMonitorCommand().run(args);
}
