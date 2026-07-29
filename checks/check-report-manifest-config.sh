#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-report-manifest-config.XXXXXX")
trap 'rm -rf "$work"' EXIT

bqn tests/test_application_report_manifest_config.bqn >/dev/null
manifest_config="$fixture/report_manifests.destination.tsv"
[[ $(bqn src/application/report_manifest_config_cli.bqn "$manifest_config" human) == report_all_human.destination.tsv ]]
[[ $(bqn src/application/report_manifest_config_cli.bqn "$manifest_config" compact) == report_all_compact.destination.tsv ]]

mkdir "$work/missing" "$work/duplicate" "$work/same" "$work/no-config"
printf 'REPORT_HUMAN_MANIFEST=human.tsv\n' >"$work/missing/config.tsv"
if bqn src/application/report_manifest_config_cli.bqn "$work/missing/config.tsv" human >"$work/missing.out" 2>&1; then
  echo 'FAIL: missing compact manifest config succeeded' >&2; exit 1
fi
grep -F 'report_compact_manifest_missing_or_duplicate' "$work/missing.out" >/dev/null
printf '%s\n' \
  'REPORT_HUMAN_MANIFEST=one.tsv' 'REPORT_HUMAN_MANIFEST=two.tsv' \
  'REPORT_COMPACT_MANIFEST=compact.tsv' >"$work/duplicate/config.tsv"
if bqn src/application/report_manifest_config_cli.bqn "$work/duplicate/config.tsv" human >"$work/duplicate.out" 2>&1; then
  echo 'FAIL: duplicate human manifest config succeeded' >&2; exit 1
fi
grep -F 'report_human_manifest_missing_or_duplicate' "$work/duplicate.out" >/dev/null
printf '%s\n' 'REPORT_HUMAN_MANIFEST=all.tsv' 'REPORT_COMPACT_MANIFEST=all.tsv' >"$work/same/config.tsv"
if bqn src/application/report_manifest_config_cli.bqn "$work/same/config.tsv" human >"$work/same.out" 2>&1; then
  echo 'FAIL: one manifest basename for two surfaces succeeded' >&2; exit 1
fi
grep -F 'report_manifests_must_differ' "$work/same.out" >/dev/null
if bqn src/application/report_manifest_config_cli.bqn "$work/no-config/missing.tsv" human >"$work/no-config.out" 2>&1; then
  echo 'FAIL: missing explicit config fell back to repository config' >&2; exit 1
fi
grep -F 'report manifest config source is not readable' "$work/no-config.out" >/dev/null

if rg -n 'src_next|DEFAULT.*MANIFEST|repository' \
  src/application/report_manifest_admission.bqn src/application/report_manifest_config.bqn >/dev/null; then
  echo 'FAIL: report manifest config gained old runtime or fallback ownership' >&2; exit 1
fi

echo 'check-report-manifest-config: OK'
