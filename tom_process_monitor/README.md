# Tom Process Monitor Library

Shared core library for the Tom Process Monitor system.

## Overview

This package contains the core logic for:

- Process definitions and registry management
- Remote API Server (`RemoteApiServer`)
- Aliveness Server (`AlivenessServer`)
- Client definitions for interacting with the monitor

## Usage

This library is primarily used by the `tom_process_monitor_tool` and `monitor_watcher` applications to provide the monitoring infrastructure.

### Remote API & CORS

The servers implemented in this package (`RemoteApiServer` and `AlivenessServer`) are configured to support CORS (Cross-Origin Resource Sharing) for all origins (`*`). This allows web-based dashboards and tools running in browsers to interact directly with the local monitoring infrastructure.

| Server | Default port (watcher) | `Access-Control-Allow-Methods` |
| ------ | ---------------------- | ------------------------------ |
| `RemoteApiServer` | 19881 (19882) | `GET, POST, DELETE, OPTIONS` |
| `AlivenessServer` | 19883 (19884) | `GET, POST, OPTIONS` |

Both send `Access-Control-Allow-Origin: *` and `Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token`, and
answer an `OPTIONS` preflight request with `200 OK`.
