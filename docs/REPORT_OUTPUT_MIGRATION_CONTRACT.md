# Report output migration contract

Status: Phase 0C approved destination contract
Owner: ledger-facts report migration
Current implementation: `tools/report` → `src_next/report.bqn`
Compact implementation: `tools/report-next-summary` → `src_next/summary.bqn`
Section inventory: `docs/REPORT_CONSTRUCTION_INVENTORY.md`

## Purpose

Moko approved this output-surface contract after review. Preserve every useful observable report capability while allowing implementation-generation names, compatibility-only behavior, and old entrypoints to disappear at cutover. This document decides where parity means identical bytes, identical schema, or identical accounting meaning.

Strict-source rejection differences approved in `docs/RUNTIME_COMPATIBILITY_INVENTORY.md` are intentional contract changes, not parity failures.

## Parity vocabulary

| level | requirement |
|---|---|
| **Byte** | stdout/file bytes match for the same destination request; line order, separators, and final newlines matter |
| **Schema** | keys, field types, ordering rules, status vocabulary, and omission rules match; presentation whitespace may differ |
| **Semantic** | selected facts, accounting values, provenance, state distinctions, and time/currency meaning match |
| **Intentional break** | old name/route is removed and all repository consumers move in the same cutover; no alias is retained |

Semantic parity always distinguishes zero, unavailable, rejected/error, and not-applicable. A matching total is insufficient when row membership, domain, status, or contributors differ.

## Surface decisions

| surface | current owner/consumer | destination parity | decision |
|---|---|---|---|
| direct human section | `tools/report --section KEY` | Semantic; Byte within destination routes | preserve all 15 keys and section meanings; direct section builds only its required result |
| full human report | `tools/report` | Semantic; canonical order; Byte within destination/cache | preserve the 15-section order; do not build a giant all-section semantic record |
| selected balances | `--section balances [--currency CODE]` | Semantic and domain-exact | one admitted currency only; approved strict default replaces implicit-JPY body |
| compact summary | `tools/report-next-summary`, `tools/query`, checks | Schema+Semantic for values; Intentional break for generation names | replace `src_next_` keys/headings atomically with stable `ledger_` names; emit no dual keys |
| section JSON | planned, balances, snapshot, envelopes | Schema+Semantic | preserve JSON field names/types/arrays/status behavior; strict invalid input may newly reject |
| section metadata TSV/JSON | `tools/report-section-metadata`, UI | Schema and canonical order | preserve six fields and 15 keys; `owner` path changes to the real destination owner and is not byte parity |
| section cache | `--write-section-cache DIR`, command hub | Byte within destination | `KEY.txt` equals direct destination body; `all.txt` equals destination full report; manifest order remains canonical plus `all` |
| cache publication | `tools/command-hub-cache-refresh` | Semantic+atomicity | stage, validate, atomically rename, remove stale no-longer-declared section files |
| query CLI | `tools/query` | Semantic; Intentional break for key prefix/summary command | migrate to canonical summary and `ledger_` keys in the same slice; no old-key fallback |
| report CLI errors | wrapper and BQN dispatcher | exit/stream class and Semantic message | preserve success 0 and usage/runtime failure class; messages may name strict evidence and new canonical paths |
| color | `--no-color`, `--color=never`, `--color=always`, `NO_COLOR`, TTY | Semantic | ANSI is presentation only; no-color is the parity/golden comparison mode |
| explicit observation | Outlook override and captured report clock | Semantic | capture CLI clock once; pass explicit observation to time-sensitive builds; no hidden section clock |
| developer diagnostics | `tools/report-next`, debug and probes | capability only; Intentional break for entrypoint/name | diagnostics remain available where useful but are not production report schema; old `report-next` name is deleted |

## Canonical section contract

The section keys and order remain:

```text
snapshot
issues
ytd
balances
cycle
trial-balance
envelopes
planned
recent
check
outlook
daily-trend
daily-flow
actual-comparison
debug
```

| key | semantic result | required output |
|---|---|---|
| `snapshot` | current account/household snapshot | human, compact, JSON |
| `issues` | ordered issue list and empty state | human |
| `ytd` | year-to-date account/category summaries | human, compact |
| `balances` | selected-domain account balances and totals | human, compact, JSON |
| `cycle` | cycle boundaries, progress, expense/capacity summary | human, compact |
| `trial-balance` | opening/movement/closing by account and selected layer/domain | human, compact |
| `envelopes` | policy-heavy envelope state, unassigned/backing diagnostics | human, compact, JSON |
| `planned` | open/completed Plan items and totals | human, compact, JSON |
| `recent` | ordered recent transaction list | human, compact |
| `check` | readiness/status diagnostics | human, compact |
| `outlook` | explicit-observation liquidity outlook | human, compact |
| `daily-trend` | row-local daily trend under documented time policy | human, compact |
| `daily-flow` | date × dynamic-category flow matrix | human |
| `actual-comparison` | explicit-observation current/baseline comparison | human, compact |
| `debug` | non-authoritative numeric/provenance diagnostics | human diagnostic |

Compact output is ordered as Snapshot, Cycle Info, minimal Cube summary, TBDS, Trial Balance, Cycle Summary, YTD, Expense Breakdown, Recent, Planned, Balances, Readiness, Plan/Journal Overlap, Envelopes, optional Household Metadata, Household Policy, Outlook, Daily Trend, and Actual Comparison. `issues` and `daily-flow` currently have no compact block. Shared Cube/TBDS/overlap/metadata/policy diagnostics migrate as narrow diagnostic capabilities, not as hidden report sections.

## List and first-line marker contract

`tools/report --list-sections` emits one line per canonical section in canonical order:

```text
KEY<TAB>FIRST_LINE_OF_HUMAN_BODY
```

The key and TSV shape are schema-stable. The marker must equal the actual destination body's first line, so generation-name cleanup or configured label changes may intentionally change marker text. UI consumers select by key and must not hard-code marker strings.

## Human output rules

1. Preserve row membership, sort order, totals, labels, status, and empty/error distinctions.
2. Preserve the plain-table convention where a result is tabular; do not force custom semantic results into Matrix formatting.
3. Remove `SrcNext`, `src_next`, `partial/src_next`, and old module paths from destination headings or status text.
4. Use current report labels unless a generation-name cleanup requires an intentional text update.
5. Render negative human numbers with ASCII `-`; machine/debug high-minus remains acceptable only where explicitly tested.
6. Compare old/new human output with color disabled and an explicit observation date.
7. Within the destination engine, direct section, full report section body, and cached section body must not have separate renderers.

Old/new whole-file byte parity is not required because strict admission and generation-name cleanup intentionally change some fixtures and headings. Unexplained differences remain failures.

## Compact key migration

Current compact keys use `src_next_`, an implementation-generation prefix. Keeping that prefix would preserve stale architecture in a public machine contract. At the section cutover that owns a key group:

```text
src_next_<suffix>  ->  ledger_<suffix>
```

Rules:

- preserve suffix meaning, value type, repeatability, ordering, status vocabulary, and omission behavior unless the section contract explicitly changes;
- update `tools/query`, checks, fixtures, and documented examples in the same commit;
- never emit old and new keys together;
- never make `tools/query` silently translate old keys;
- delete `tools/report-next-summary`; the canonical replacement is `tools/report-summary` at composition cutover;
- headings become implementation-neutral; consumers parse keys, not headings.

This is a controlled breaking rename, not a compatibility period.

## JSON contracts

JSON remains supported only for:

```text
snapshot
balances
envelopes
planned
```

For admitted equivalent evidence, preserve current object keys, arrays, scalar types, and status/empty behavior. JSON continues to be generated from the same presentation-neutral section result as human/compact output. It must not build an alternate context or parse human text.

Unsupported section JSON remains a nonzero CLI error. `--currency` remains valid only for human selected balances unless a future explicit schema adds a Currency axis; migration does not silently widen JSON.

## Metadata contract

`tools/report-section-metadata` keeps:

```text
key, label, category, owner, human_output, structured_output
```

TSV remains the default; JSON remains an array of objects with those fields. Section key/order/category are schema contracts. Label text follows configured report labels. `owner` is provenance and must change from `src_next/...` to the actual destination path when ownership moves; old paths are not retained as aliases.

Metadata remains source-independent: listing it must not read household TSV or build report facts.

## Cache contract

For one destination evidence snapshot and observation:

- `KEY.txt` is byte-identical to direct human `--section KEY` body under the cache newline convention;
- `all.txt` is byte-identical to direct full-report stdout;
- `.section-keys` contains canonical section keys followed by UI-only `all`;
- cache refresh publishes atomically and never exposes mixed generations;
- a removed section key removes its stale cache file at the same publication boundary;
- shell owns safe publication, not accounting or section rendering.

## CLI and exit contract

Supported daily report inputs are:

| input | meaning / combination rule |
|---|---|
| optional first positional base | explicit report base; otherwise wrapper resolves `LEDGER_DATA_DIR`, then configured user default |
| `--no-color`, `--color=never`, `--color=always` | presentation only |
| `--list-sections` | section key and first-line marker TSV; not combined with `--section` |
| `--section KEY` | one human section |
| `--format json` | requires one of the four JSON sections |
| `--write-section-cache DIR` | exclusive major mode; writes section files, `all.txt`, and manifest |
| `--outlook-as-of YYYY-MM-DD` | explicit Outlook observation; invalid/missing date fails |
| `--currency CODE` | registry-supported code; human `balances` section only |

The destination parser rejects missing option values, unknown sections/formats, and unsupported combinations. It does not reinterpret them through a historical route.

| condition | status |
|---|---:|
| successful human/JSON/list/cache/metadata request | 0 |
| unknown section, unsupported format, invalid option combination, invalid strict source | nonzero |
| metadata CLI usage/unsupported format | 2 remains acceptable current usage class |
| user cancellation in interactive UI | 130 where already defined by the UI |

Required argument/combination checks remain fail-closed. Exact error wording is not byte-stable, but it must identify the option or rejected source coordinate and must not print valid-looking report numbers after failure.

The destination keeps `tools/report` as the daily production command. Historical generation names such as `tools/report-next`, `tools/report-next-summary`, and source-path detection are removed at composition cutover with all callers.

## Time and deterministic parity

A parity run supplies an explicit observation wherever the section meaning depends on today. The composition root captures the system date at most once per command and passes it explicitly. Outlook's current override behavior remains. Daily Trend and Actual Comparison receive the captured report date without reading the clock inside section code.

Tests compare identical source snapshot, observation, selected domain, and config. A run with different observations is not a parity comparison.

## Public synthetic evidence

Current public evidence is intentionally layered rather than one private golden:

- `checks/check-src-next-report.sh` — direct/full section routing and CLI behavior;
- `checks/check-src-next-compact-summary.sh` and section checks — compact keys/statuses;
- `checks/check-json-clock-independence.sh` plus snapshot/balances/envelope/planned section checks — JSON schema and clock independence;
- `checks/check-report-section-metadata.sh` — metadata TSV/JSON and source independence;
- `checks/check-src-next-report.sh` and `checks/check-command-hub-browse-cache.sh` — cache body/manifest/publication behavior;
- `checks/check-src-next-golden.sh` — stable public diagnostic/accounting subset;
- `tests/test_src_next_*.bqn` — section semantics, invalid evidence, time and currency policies.

Each migration slice adds old/new public synthetic comparison for its owned semantic result before deleting the old owner. Private household output is not committed as parity evidence.

## Per-slice deletion gate

A section or surface moves only when:

1. equivalent admitted public evidence produces the same semantic result;
2. human/compact/JSON/cache consumers for that owner move together;
3. strict-source differences are expected and have explicit rejection tests;
4. new compact names have replaced all repository callers without aliases;
5. direct and cached destination bytes agree;
6. old builder, formatter, export, tests, and docs for that owner are deleted;
7. repository search finds no old owner path or key except migration history scheduled for deletion.

Final cutover succeeds only when no runtime, wrapper, fallback, `ForTest`, `_for_test`, old compact key, or old entrypoint remains.
