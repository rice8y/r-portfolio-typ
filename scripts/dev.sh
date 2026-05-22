#!/usr/bin/env bash
set -euo pipefail

# `just` receives SIGINT if the terminal driver converts Ctrl+C to a signal for
# the whole foreground process group.  Use /dev/tty directly, because just can
# run recipes with stdin redirected; disabling ISIG on fd 0 is then a no-op.
TTY="/dev/tty"
if [ -r "$TTY" ] && [ -w "$TTY" ]; then
  OLD_STTY=$(stty -g < "$TTY" 2>/dev/null || true)
  restore_tty() {
    if [ -n "${OLD_STTY:-}" ]; then
      stty "$OLD_STTY" < "$TTY" 2>/dev/null || true
    fi
  }
  trap restore_tty EXIT
  trap 'restore_tty; exit 0' INT TERM

  # Disable terminal-generated signals. Ctrl+C is passed to Node as \x03, where
  # scripts/dev.mjs handles it and exits with status 0. Feed Node from /dev/tty
  # so keyboard stop works even when just does not expose a TTY on stdin.
  stty -echo -icanon -isig min 1 time 0 < "$TTY" 2>/dev/null || true
  node scripts/dev.mjs < "$TTY"
else
  trap 'exit 0' INT TERM
  node scripts/dev.mjs
fi
