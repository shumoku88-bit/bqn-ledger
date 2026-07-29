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

echo 'check-source-io-ownership: OK'
