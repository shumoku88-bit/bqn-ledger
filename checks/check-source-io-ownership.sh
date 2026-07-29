#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fail() { echo "FAIL: $1" >&2; exit 1; }

# Pure parsing and read-only application I/O remain separate bounded owners.
if grep -Eq '•SH|•FChars|•file\.|•Out|•Exit|LoadChars|LoadLines' src/text/parse.bqn; then
  fail 'src/text/parse.bqn gained file, shell, or process I/O'
fi
grep -Fq 'parse ← •Import "../text/parse.bqn"' src/application/source_io.bqn \
  || fail 'source_io must delegate splitting to src/text/parse.bqn'
if grep -Eq '•SH|•Out|•Exit|•GetTime|•Delay' src/application/source_io.bqn; then
  fail 'source_io gained shell, output, process, or clock behavior'
fi

# Removed owners must not survive as imports or forwarding modules.
[[ ! -e src_next/util.bqn && ! -e src_next/loader.bqn ]] \
  || fail 'removed src_next helper owner still exists'
if rg -n 'src_next/(util|loader)\.bqn|Import "(util|loader)\.bqn"' src src_edit src_next tests checks tools \
  --glob '*.bqn' --glob '*.sh' --glob '!check-source-io-ownership.sh' >/dev/null; then
  fail 'removed src_next helper owner is still imported'
fi

# Existing source readers now use the implementation-neutral application owner.
grep -Fq 'loader ← •Import "../src/application/source_io.bqn"' src_next/config.bqn \
  || fail 'config must import src/application/source_io.bqn'
[[ $(grep -Fc 'loader.ReadLines' src_next/config.bqn) -eq 5 ]] \
  || fail 'config must route its five required reads through source_io.ReadLines'

echo 'check-source-io-ownership: OK'
