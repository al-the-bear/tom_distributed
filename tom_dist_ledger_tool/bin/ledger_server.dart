/// The `ledger_server` executable: the Distributed Ledger HTTP server
/// (`lib/src/ledger_server_main.dart`). Compiled into the binaries layer by
/// buildkit (`buildkit.yaml` `compiler:`); the ProcessMonitor installer copies
/// it from there as `Tom Ledger Server`, beside `Tom Process Monitor`, where
/// the monitor finds it.
library;

import 'package:tom_dist_ledger_tool/tom_dist_ledger_tool.dart';

Future<void> main(List<String> args) => ledgerServerMain(args);
