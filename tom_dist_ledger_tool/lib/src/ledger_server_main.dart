/// Distributed Ledger Server CLI on tom_build_base's ToolRunner.
library;

import 'dart:async';
import 'dart:io';

import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:tom_dist_ledger/tom_dist_ledger.dart';

import 'version.versioner.dart';

/// The port the server listens on without `--port`.
const defaultLedgerPort = 19880;

/// `ledger_server`: the Distributed Ledger HTTP server. A ProcessMonitor
/// starts it as `ledger_server --path <dir>`.
final ledgerServerTool = ToolDefinition(
  name: 'ledger_server',
  description: 'Distributed Ledger HTTP server',
  version: DistLedgerToolVersionInfo.version,
  versionString: 'ledger_server ${DistLedgerToolVersionInfo.versionLong}',
  mode: ToolMode.singleCommand,
  features: NavigationFeatures.minimal,
  globalOptions: [
    OptionDefinition.option(
      name: 'port',
      abbr: 'p',
      description: 'Port to listen on (default $defaultLedgerPort)',
      valueName: 'port',
    ),
    OptionDefinition.option(
      name: 'path',
      abbr: 'd',
      description:
          'Base path of the ledger storage (default ~/.tom/distributed_ledger)',
      valueName: 'path',
    ),
  ],
);

/// The ledger server's settings from its options, or an error message.
({int port, String basePath})? ledgerServerSettings(
  CliArgs args, {
  void Function(String message)? onError,
}) {
  final rawPort = args.extraOptions['port'];
  final port = rawPort == null
      ? defaultLedgerPort
      : int.tryParse(rawPort.toString());
  if (port == null || port < 1 || port > 65535) {
    onError?.call('Error: --port must be a port number, not "$rawPort".');
    return null;
  }
  final basePath =
      (args.extraOptions['path'] as String?) ?? _defaultLedgerPath();
  return (port: port, basePath: basePath);
}

/// Starts the server and keeps it running until SIGINT.
class LedgerServerExecutor extends CommandExecutor {
  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async =>
      ItemResult.success(path: context.path, name: context.name);

  @override
  Future<ToolResult> executeWithoutTraversal(CliArgs args) async {
    final settings = ledgerServerSettings(args, onError: stderr.writeln);
    if (settings == null) return const ToolResult.failure('invalid --port');

    print('Starting Distributed Ledger Server...');
    print('  Port: ${settings.port}');
    print('  Base path: ${settings.basePath}');

    final server = await LedgerServer.start(
      basePath: settings.basePath,
      port: settings.port,
    );

    print('Server listening on http://localhost:${settings.port}');
    print('Press Ctrl+C to stop.');

    ProcessSignal.sigint.watch().listen((_) async {
      print('\nShutting down...');
      await server.stop();
      exit(0);
    });

    await Completer<void>().future;
    return const ToolResult.success();
  }
}

/// Main entry point of the ledger server CLI; sets the exit code.
Future<void> ledgerServerMain(List<String> arguments) async {
  final result = await ToolRunner(
    tool: ledgerServerTool,
    executors: {'default': LedgerServerExecutor()},
  ).run(arguments);
  if (!result.success) exitCode = result.exitCode;
}

/// The default ledger storage path: ~/.tom/distributed_ledger
String _defaultLedgerPath() {
  final home =
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      Directory.current.path;
  return '$home/.tom/distributed_ledger';
}
