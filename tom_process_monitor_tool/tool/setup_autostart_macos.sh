#!/bin/bash
set -e

# setup_autostart_macos.sh
# Sets up ProcessMonitor as a macOS LaunchAgent.
# The main ProcessMonitor will automatically spawn the MonitorWatcher.
#
# The binaries come from the binaries layer, $TOM_BINARY_PATH/darwin-<arch>/
# (`process_monitor`, `ledger_server`, built by buildkit's `:compiler`). They
# are copied - the layer is a git checkout that changes under a running
# service - into ~/Library/Application Support/Tom/bin as "Tom Process
# Monitor" and "Tom Ledger Server" (the monitor finds the ledger server beside
# itself, and macOS lists the services by these names).
#
# Usage:
#   cd tom_ai/distributed/tom_process_monitor_tool
#   ./tool/setup_autostart_macos.sh [--clean]
#
# Options:
#   --clean    Delete existing configuration before installation.

echo "Setting up Tom Process Monitor autostart..."

# Parse arguments
CLEAN=false
for arg in "$@"; do
    case $arg in
        --clean)
            CLEAN=true
            shift
            ;;
    esac
done

if [ -z "${TOM_BINARY_PATH:-}" ]; then
    echo "Error: TOM_BINARY_PATH is not set (it names the binaries layer, tom_binaries/tom)."
    exit 1
fi

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    PLATFORM="darwin-x64"
elif [ "$ARCH" == "arm64" ]; then
    PLATFORM="darwin-arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi
LAYER_BIN="$TOM_BINARY_PATH/$PLATFORM"
for b in process_monitor ledger_server; do
    if [ ! -x "$LAYER_BIN/$b" ]; then
        echo "Error: $LAYER_BIN/$b is missing. Pull the binaries layer (tom_pull_binaries) or build it:"
        echo "  buildkit -p tom_process_monitor_tool -p tom_dist_ledger_tool :compiler"
        exit 1
    fi
done

INSTALL_BIN="$HOME/Library/Application Support/Tom/bin"
mkdir -p "$INSTALL_BIN"

# "Tom Process Monitor": the name macOS shows in its background items list.
BINARY_NAME="Tom Process Monitor"
BINARY_PATH="$INSTALL_BIN/$BINARY_NAME"

echo "Installing $BINARY_NAME and Tom Ledger Server from $LAYER_BIN..."

if [ "$CLEAN" = true ]; then
    echo "Cleaning old configuration..."
    rm -f "$HOME/.tom/process_monitor/processes_default.json"
    rm -rf "$HOME/.tom/process_monitor/logs"
    echo "Old configuration removed."

    echo "Creating initial configuration with standaloneMode=false..."
    mkdir -p "$HOME/.tom/process_monitor"
    cat > "$HOME/.tom/process_monitor/processes_default.json" <<EOF
{
  "version": 1,
  "instanceId": "default",
  "monitorIntervalMs": 5000,
  "standaloneMode": false,
  "alivenessServer": {
    "enabled": true,
    "port": 19883
  },
  "processes": {}
}
EOF
fi

# We don't need a separate monitor_watcher binary because process_monitor
# can act as a watcher when passed --instance=watcher, which is what the
# internal spawning logic does.

LAUNCH_AGENTS="$HOME/Library/LaunchAgents"
mkdir -p "$LAUNCH_AGENTS"

# 1. Tom Process Monitor.plist
PM_PLIST="$LAUNCH_AGENTS/Tom Process Monitor.plist"
echo "Creating $PM_PLIST..."
cat > "$PM_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>Tom Process Monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BINARY_PATH</string>
        <string>--foreground</string>
        <string>--directory</string>
        <string>$HOME/.tom/process_monitor</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/tom_process_monitor.out</string>
    <key>StandardErrorPath</key>
    <string>/tmp/tom_process_monitor.err</string>
</dict>
</plist>
EOF

# Unload old agents if they exist
echo "Unloading old agents..."
launchctl unload "$LAUNCH_AGENTS/com.tom.monitor_watcher.plist" 2>/dev/null || true
launchctl unload "$LAUNCH_AGENTS/com.tom.process_monitor.plist" 2>/dev/null || true
launchctl unload "$PM_PLIST" 2>/dev/null || true

# Kill existing processes
echo "Stopping existing processes..."
pkill -f "process_monitor" || true
pkill -f "Tom Process Monitor" || true

# Copy the binaries now that the old ones no longer run.
install -m 0755 "$LAYER_BIN/process_monitor" "$BINARY_PATH"
install -m 0755 "$LAYER_BIN/ledger_server" "$INSTALL_BIN/Tom Ledger Server"

# Remove deprecated watcher plist if it exists
rm -f "$LAUNCH_AGENTS/com.tom.monitor_watcher.plist"
rm -f "$LAUNCH_AGENTS/com.tom.process_monitor.plist"

# Remove the copies earlier versions of this script compiled into ~/.tom/bin.
for old in "$HOME/.tom/bin/darwin_arm64" "$HOME/.tom/bin/darwin_x64"; do
    rm -f "$old/Tom Process Monitor" "$old/Tom Ledger Server" "$old/process_monitor" "$old/monitor_watcher"
done

echo "Loading ProcessMonitor Agent (Label: Tom Process Monitor)..."
launchctl load "$PM_PLIST"

echo "Done! Executable installed to $BINARY_PATH"
echo "ProcessMonitor started via LaunchAgent."
echo "The OS sees the binary name '$BINARY_NAME', so it should appear correctly in settings."
echo "Check status with: tail -f /tmp/tom_process_monitor.out"
