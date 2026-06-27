# Maintenance guide (bqn-ledger)

位置づけ:
- 長期の方針: `docs/ROADMAP.md`
- 直近のタスク: `TODO.md`

## Quick commands

- Environment / data-dir doctor: `tools/doctor`
- Full check suite: `tools/check.sh`
- Daily report entry: `tools/main-ui.sh`
  - Full human report: `tools/report`
  - Section selector (fzf/gum): `tools/main-ui.sh select`
- Machine summary: `tools/report-next-summary`
- Add a transaction (Go editor):
  - `tools/edit journal add` — 実績取引の追記
  - `tools/edit budget add` — 予算配賦の追記
  - `tools/add-ui.sh` — fzf/gum 対話式入力UI

## Where to implement changes

### Add a new computed metric / report section

1) Implement computation in the appropriate `src_next/*.bqn` module
2) Follow `BuildContext → ViewModel → Format / FormatHuman` pattern
3) Wire into `src_next/report.bqn` and `src_next/summary.bqn`

### Add a new report view

- Keep `tools/report` as the primary entry.
- Section modules go in `src_next/`.
- Follow the existing pattern: `Build(ctx) → ViewModel`, `Format(ViewModel) → text`.

## Stability guidelines

- Keep TSV as the source of truth; avoid writing derived files.
- Treat this as a **daily-life tool**: record → validate → aggregate → display.
- Do **not** embed tax制度判断 in the core; record metadata and export instead.
- Document any new metadata key in `docs/JOURNAL_META.md` and `docs/CONVENTIONS.md`.
- Household policy / lifestyle rules belong in the policy layer, not in accounting core.

## Change checklist

When you change behavior:

- TSV schema / row rules changed → update `docs/ARCHITECTURE.md` + `docs/JOURNAL_META.md`
- New/renamed tool or command → update `docs/ARCHITECTURE.md` + `docs/AI_CODEMAP.md`
- Data directory resolution / `LEDGER_DATA_DIR` behavior changed → update `docs/DATA_DIR_SETUP.md` + `README.md`
- New meta key adopted → update `docs/JOURNAL_META.md`
- After changes, run: `tools/check.sh`
