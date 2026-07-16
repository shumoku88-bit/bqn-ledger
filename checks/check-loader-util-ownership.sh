#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

# util is a pure helper owner. File/process I/O must not creep back in.
if grep -Eq '•SH|•FChars|•file\.|•Out|•Exit|LoadChars|LoadLines' src_next/util.bqn; then
  grep -En '•SH|•FChars|•file\.|•Out|•Exit|LoadChars|LoadLines' src_next/util.bqn >&2 || true
  fail "src_next/util.bqn must remain free of file, shell, and process I/O"
fi

# loader preserves the established public API through one pure split owner.
grep -Fq 'util ← •Import "util.bqn"' src_next/loader.bqn \
  || fail "loader.bqn must import util.bqn"
grep -Fq 'Split ← util.Split' src_next/loader.bqn \
  || fail "loader.bqn must delegate Split to util"
grep -Fq 'SplitKeepEmpty ← util.SplitKeepEmpty' src_next/loader.bqn \
  || fail "loader.bqn must delegate SplitKeepEmpty to util"

# Config keeps policy/selection ownership but reads bytes through loader.
grep -Fq 'loader ← •Import "loader.bqn"' src_next/config.bqn \
  || fail "config.bqn must import loader.bqn"
if grep -Fq 'lib.LoadLines' src_next/config.bqn; then
  fail "config.bqn must not use legacy util.LoadLines"
fi
[ "$(grep -Fc 'loader.ReadLines' src_next/config.bqn)" -eq 3 ] \
  || fail "config.bqn must route its three required reads through loader.ReadLines"

echo "check-loader-util-ownership: OK" >&2
