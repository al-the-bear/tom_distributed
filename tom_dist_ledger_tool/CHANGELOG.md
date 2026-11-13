## 1.1.0

- `ledger_server` runs on tom_build_base's ToolRunner (2.30.0): the shared
  `--help`, `--version` from the versioner. `--port` / `-p` and `--path` /
  `-d` stay; a `--port` that is no port number is now an error (exit 1)
  instead of falling back to 19880. `printLedgerServerUsage` is gone (help
  comes from the tool definition).

## 1.0.0

- Initial version.
