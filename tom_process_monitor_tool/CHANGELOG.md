## 1.1.0

- `process_monitor` / `monitor_watcher` run on tom_build_base's ToolRunner
  (2.30.0): the shared `--help`, and `--version` from the versioner
  (`version.versioner.dart`) with the binary's origin, in place of the
  hard-coded `process_monitor version 1.0.0`. Every flag stays: `--directory`
  / `-d`, `--foreground` / `-f`, `--stop`, `--status`, `--restart`, the hidden
  `--instance`; exit codes 0 / 1 as before. `CliRunner` and the `args`
  dependency are gone (`ProcessMonitorCommand` / `MonitorWatcherCommand` keep
  their `run(args)`).
- The background start no longer passes a compiled binary its own path as an
  argument (`detachedStartArguments`).
- `--foreground` exits after Ctrl+C / SIGTERM: the signal subscriptions are
  cancelled once the monitor has stopped (before, the process stayed alive
  with the monitor stopped).

## 1.0.0

- Initial version.
