# Public source readiness audit

Status: Phase 0C current evidence
Owner: ledger-facts report migration
Roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`
Compatibility decisions: `docs/RUNTIME_COMPATIBILITY_INVENTORY.md`
Scope: direct child directories under public `fixtures/` at `d7188bd`

## Purpose

Measure how much of the public fixture corpus currently depends on implicit currency, Plan identity, config, role, or source-layout behavior before strict source admission is introduced.

This audit does not inspect private household data. Run it on a private base only under explicit human direction, and do not publish private paths or output.

## Reproducible command

```bash
python3 tools/characterization/report_source_readiness_audit.py \
  fixtures --children --summary
```

Detailed TSV:

```bash
python3 tools/characterization/report_source_readiness_audit.py fixtures --children
```

The tool is readonly and requires an explicit path. It does not default to `data/`, `LEDGER_DATA_DIR`, or another household location.

## Results

| metric | value |
|---|---:|
| direct fixture directories | 99 |
| missing/non-explicit `DEFAULT_CURRENCY` | 96 |
| account rows | 625 |
| account rows missing explicit `currency=` | 574 |
| account rows missing explicit `role=` | 11 |
| Plan rows | 126 |
| Plan rows missing explicit `currency=` | 125 |
| Plan rows missing explicit `plan_id=` | 84 |
| Budget rows | 97 |
| Budget rows missing explicit `currency=` | 96 |
| Actual source found only through `base/data/` fallback | 0 |
| directories without a direct Actual source | 34 |

Only these three direct fixture directories currently declare `DEFAULT_CURRENCY` explicitly:

```text
fixtures/currency-usd-single
fixtures/demo
fixtures/editor-currency-m2
```

## Interpretation

### Strict currency is a corpus migration, not a small parser switch

Most public fixtures were created under implicit-JPY contracts:

- 574 of 625 account rows omit `currency=`;
- 125 of 126 Plan rows omit `currency=`;
- 96 of 97 Budget rows omit `currency=`;
- 96 of 99 fixture directories do not declare `DEFAULT_CURRENCY`.

Deleting C12/C13/C16 from the compatibility inventory therefore requires deliberate fixture migration and new negative tests. Turning on strict admission first would mostly measure fixture age, not destination correctness.

### Role readiness is much closer

Only 11 of 625 account rows omit `role=`. Explicit-role report semantics can become strict with a much smaller migration, while dedicated missing-role fixtures can remain rejection/diagnostic evidence.

### Plan identity needs semantic classification

Forty-two of 126 Plan rows have explicit `plan_id=`; 84 do not. Not every fixture row necessarily represents a completion-capable durable relationship. Phase 0C must classify Plan fixtures before bulk editing:

- completion/remaining/trend/overlap rows should receive explicit durable identity;
- rows whose purpose is malformed/missing identity should remain negative evidence;
- component fixtures not exercising identity should either be migrated consistently or narrowed to their actual test boundary.

The five-field fallback must not be retained merely to avoid fixture updates.

### The nested Actual path fallback has no public fixture dependency

No direct fixture directory requires `base/data/<journal>` fallback. C09 can likely be removed from the public path once private base layout is explicitly checked. The 34 missing-Actual directories include component fixtures that are not complete report bases; they are not evidence for retaining the path fallback.

## Fixture migration classes

Do not add metadata blindly to all 99 directories. Classify each fixture first:

1. **full report parity fixture** — migrate to complete strict source evidence;
2. **negative admission fixture** — preserve the intentional omission/error and update the expected strict diagnostic;
3. **component fixture** — audit only fields relevant to that component; do not require an unrelated full ledger;
4. **historical rehearsal fixture** — archive/delete when its old implementation disappears;
5. **editor fixture** — migrate with the corresponding final editor read/write contract.

## Required next decisions

Before Phase 2 source migration:

- approve required `DEFAULT_CURRENCY` for full report bases;
- approve explicit account currency for arithmetic accounts;
- approve explicit Plan/Budget row currency;
- define exactly which Plan rows require durable `plan_id=`;
- permit missing role only as unclassified diagnostic evidence, never semantic prefix inference;
- explicitly inspect private base layout/readiness under human direction;
- select the first small public fixture cohort rather than bulk-editing the corpus.

## Safety

The audit tool reports paths and aggregate counts. Public fixture output is safe to record. Private output may reveal directory names and source shape, so it remains local unless moko explicitly directs otherwise.
