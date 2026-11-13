# Deployment Guide

## macOS Deployment

### Binary Location

`process_monitor` (which is also the watcher, with `--instance=watcher`) and
`ledger_server` are built into the binaries layer, `$TOM_BINARY_PATH/<platform>/`,
by buildkit; the installer of `tom_process_monitor_tool` copies them into
`~/Library/Application Support/Tom/bin/` as "Tom Process Monitor" and
"Tom Ledger Server".

### Autostart
Use the provided script in `tom_process_monitor_tool` to setup LaunchAgents. The main `process_monitor` is registered as a LaunchAgent and will automatically start the partner watcher instance.
