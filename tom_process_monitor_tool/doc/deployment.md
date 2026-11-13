# Deployment Guide

## macOS Autostart Setup

The `setup_autostart_macos.sh` script automates the deployment process.

### Binaries

Two binaries are built into the binaries layer by buildkit
(`buildkit -p tom_process_monitor_tool -p tom_dist_ledger_tool :compiler`, also
part of every full build), in `$TOM_BINARY_PATH/<platform>/`:

- `process_monitor` (from `tom_process_monitor_tool/bin/process_monitor.dart`):
  the main process manager; run with `--instance=watcher` it is the watcher;
- `ledger_server` (from `tom_dist_ledger_tool/bin/ledger_server.dart`): the
  distributed ledger server.

The script copies them from `$TOM_BINARY_PATH/darwin-<arch>/` into
`~/Library/Application Support/Tom/bin/` as "Tom Process Monitor" and
"Tom Ledger Server": a running service needs a copy that does not change under
it, the monitor finds the ledger server beside itself, and macOS lists the
services by these names. Copies an earlier version of the script compiled into
`~/.tom/bin/darwin_<arch>/` are removed.

### LaunchAgent
A single LaunchAgent (`~/Library/LaunchAgents/Tom Process Monitor.plist`, label `Tom Process Monitor`) is registered to start "Tom Process Monitor" on login. The main process will then spawn the watcher instance automatically using its internal configuration.
