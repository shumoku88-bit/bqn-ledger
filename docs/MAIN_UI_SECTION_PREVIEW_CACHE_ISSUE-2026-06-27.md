# Restore fzf section preview using temporary section cache

Status: open issue / docs-only / no implementation yet
Date: 2026-06-27

## Goal

Restore the old selector experience where `tools/main-ui.sh` opens a section list and moving through items shows a preview.

The preview must be fast and must not call BQN on every cursor movement.

## Background

Recent work added:

- `tools/report --section <key>`
- direct `tools/main-ui.sh <section>` routing through `tools/report --section`

This made direct section display faster.

The remaining desired behavior is selector preview.

## Desired design

On `tools/main-ui.sh` selector startup:

1. Create a temporary cache directory.
2. Ask the report engine to generate section text files once.
3. Store files by stable section key, for example:
   - snapshot.txt
   - envelopes.txt
   - planned.txt
   - recent.txt
   - check.txt
   - debug.txt
   - all.txt
4. fzf preview should only `cat` the cached file for the selected key.
5. Do not parse human-facing report headers in shell.
6. Do not use awk boundaries for preview.
7. Delete the temporary cache when selector exits.

## Review notes / implementation priorities

Suggested order:

1. Keep `tools/check.sh` resolving repo root from the repo root, not the parent directory.
2. Make `--section envelopes` safe on envelope-less / no-budget-data fixtures (fail closed or render a visible unavailable message).
3. If a ToC/select path exists, keep branch selection lazy-safe (`◶`) so `q`/cancel paths do not eagerly execute the body. If this logic ever lives on the historical report side again, the note target is `src/reports/main_impl.bqn` / `src/reports/report_sections.bqn`.
4. Add a smoke check for envelope-less and empty fixtures for `--section envelopes`.

## Future command shape

Possible report command:

```sh
tools/report data --write-section-cache "$cache_dir" --no-color
```
