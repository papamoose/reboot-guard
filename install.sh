#!/usr/bin/env bash
#
# install.sh — install or uninstall the reboot-mollyguard wrapper.
#
# Usage:
#   sudo ./install.sh              install the wrapper
#   sudo ./install.sh --uninstall  remove the wrapper

set -eu

DEST=/usr/local/sbin/reboot
SRC_DIR=$(cd "$(dirname "$0")" && pwd)
SRC="$SRC_DIR/reboot"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo $0" >&2
    exit 1
fi

case "${1:-}" in
    --uninstall)
        if [ -e "$DEST" ] && [ "$(readlink -f "$DEST")" = "$(readlink -f "$SRC")" ]; then
            rm -f "$DEST"
            echo "Removed $DEST."
        else
            echo "$DEST is not the mollyguard wrapper; leaving it in place." >&2
            exit 1
        fi
        exit 0
        ;;
    "")
        ;;
    *)
        echo "Usage: sudo $0 [--uninstall]" >&2
        exit 2
        ;;
esac

if [ -e "$DEST" ] && [ "$(readlink -f "$DEST")" != "$(readlink -f "$SRC")" ]; then
    echo "$DEST already exists and is not this script. Aborting." >&2
    echo "Back it up and re-run if you are sure." >&2
    exit 1
fi

install -m 0755 "$SRC" "$DEST"
echo "Installed $DEST."

resolved=$(command -v reboot 2>/dev/null || true)
if [ -z "$resolved" ]; then
    echo "NOTE: 'reboot' is not in your PATH. Make sure /usr/local/sbin is in PATH." >&2
elif [ "$resolved" = "$DEST" ]; then
    echo "PATH check: 'reboot' resolves to the wrapper."
else
    echo "WARNING: 'reboot' resolves to $resolved, not the wrapper." >&2
    echo "Fix the PATH order: /usr/local/sbin must come before /usr/sbin and /sbin." >&2
fi
