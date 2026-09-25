#!/usr/bin/env bash
#
# run.sh — dry-run tests for the reboot wrapper.
#
# The tests never reboot the machine. The wrapper runs against a
# fake reboot binary that only prints a message and exits 0.
#
# Usage: bash tests/run.sh

set -u

REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
WRAP_SRC="$REPO_DIR/reboot"
if [ ! -f "$WRAP_SRC" ]; then
    echo "wrapper not found: $WRAP_SRC" >&2
    exit 1
fi

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

# Fake reboot binary: prints its arguments and exits 0.
cat > "$T/fakereboot" <<'EOF'
#!/bin/bash
echo "REAL REBOOT INVOKED, args: [$*]"
EOF
chmod +x "$T/fakereboot"

# Test copy: point at the fake binary, disable the TTY check so we
# can pipe answers in.
sed -e "s|/usr/sbin/reboot /sbin/reboot /bin/reboot|$T/fakereboot|" \
    -e 's|\[ ! -t 0 \]|[ 1 -eq 0 ]|' "$WRAP_SRC" > "$T/wrap"
chmod +x "$T/wrap"

# Test copy with the TTY check left in place (for the non-TTY test).
sed -e "s|/usr/sbin/reboot /sbin/reboot /bin/reboot|$T/fakereboot|" \
    "$WRAP_SRC" > "$T/wrap-tty"
chmod +x "$T/wrap-tty"

HOST_SHORT=$(hostname -s)
HOST_FULL=$(hostname)
HOST_FULL_UPPER=$(hostname | tr 'a-z' 'A-Z')

PASS=0
FAIL=0

# test_case <name> <input> <expected-exit> <expected-output-substring> <cmd...>
test_case() {
    local name=$1 input=$2 want_rc=$3 want_msg=$4
    shift 4
    local out rc
    out=$(printf '%s\n' "$input" | "$@" 2>&1)
    rc=$?
    if [ "$rc" -eq "$want_rc" ] && printf '%s' "$out" | grep -qF "$want_msg"; then
        echo "PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $name (rc=$rc, expected $want_rc)"
        echo "--- output ---"
        echo "$out"
        echo "--------------"
        FAIL=$((FAIL + 1))
    fi
}

test_case "wrong name cancels" \
    "definitely-not-this-box" 1 "Reboot cancelled." "$T/wrap"

test_case "correct short hostname reboots" \
    "$HOST_SHORT" 0 "REAL REBOOT INVOKED, args: []" "$T/wrap"

test_case "arguments are forwarded" \
    "$HOST_SHORT" 0 "REAL REBOOT INVOKED, args: [-f]" "$T/wrap" -f

test_case "full hostname, case-insensitive, reboots" \
    "$HOST_FULL_UPPER" 0 "REAL REBOOT INVOKED" "$T/wrap"

test_case "empty input cancels" \
    "" 1 "Reboot cancelled." "$T/wrap"

test_case "non-interactive use is refused" \
    "$HOST_SHORT" 1 "not a terminal" "$T/wrap-tty"

echo "----------------------------------------"
echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
