# BQN primitive usage inventory

Status: mechanically generated observation

Repository baseline: `221c4234af615cbf31bb9e22a7600efed58b088c`
Official primitive source: `mlochbaum/BQN@1d43de0a8d66010c55f26fafb967c648d2fefade`
Tracked BQN source files: 192

Executable tokens are separated from comments and text literals using BQN token precedence.
Documentation and archive code do not make a primitive present in the current runtime.

## Corpus

| Corpus | Files |
|---|---:|
| production | 82 |
| editor | 41 |
| tools | 1 |
| tests | 68 |
| support | 0 |
| documentation | 0 |
| archive | 0 |

## Primitive summary

| Glyph | Role | Official name | Prod | Editor | Tools | Tests | Support | Docs | Archive | Non-code | Runtime |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `+` | function | Conjugate / Add | 284 | 220 | 0 | 85 | 0 | 0 | 0 | 16 | **used** |
| `-` | function | Negate / Subtract | 61 | 30 | 0 | 10 | 0 | 0 | 0 | 2502 | **used** |
| `×` | function | Sign / Multiply | 20 | 12 | 0 | 3 | 0 | 0 | 0 | 4 | **used** |
| `÷` | function | Reciprocal / Divide | 10 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **used** |
| `⋆` | function | Exponential / Power | 5 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | **used** |
| `√` | function | Square Root / Root | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `⌊` | function | Floor / Minimum | 21 | 3 | 0 | 0 | 0 | 0 | 0 | 0 | **used** |
| `⌈` | function | Ceiling / Maximum | 25 | 6 | 0 | 0 | 0 | 0 | 0 | 0 | **used** |
| `∧` | function | Sort Up / And | 305 | 247 | 3 | 15 | 0 | 0 | 0 | 0 | **used** |
| `∨` | function | Sort Down / Or | 149 | 121 | 2 | 52 | 0 | 0 | 0 | 0 | **used** |
| `¬` | function | Not / Span | 200 | 179 | 0 | 31 | 0 | 0 | 0 | 0 | **used** |
| `|` | function | Absolute Value / Modulus | 10 | 2 | 0 | 0 | 0 | 0 | 0 | 54 | **used** |
| `≤` | function | Less Than or Equal To | 26 | 22 | 0 | 2 | 0 | 0 | 0 | 0 | **used** |
| `<` | function | Enclose / Less Than | 182 | 210 | 1 | 105 | 0 | 0 | 0 | 138 | **used** |
| `>` | function | Merge / Greater Than | 24 | 59 | 0 | 6 | 0 | 0 | 0 | 148 | **used** |
| `≥` | function | Greater Than or Equal To | 22 | 6 | 0 | 2 | 0 | 0 | 0 | 0 | **used** |
| `=` | function | Rank / Equals | 366 | 226 | 13 | 11 | 0 | 0 | 0 | 423 | **used** |
| `≠` | function | Length / Not Equals | 655 | 533 | 3 | 121 | 0 | 0 | 0 | 0 | **used** |
| `≡` | function | Depth / Match | 355 | 300 | 0 | 82 | 0 | 0 | 0 | 0 | **used** |
| `≢` | function | Shape / Not Match | 101 | 69 | 1 | 4 | 0 | 0 | 0 | 0 | **used** |
| `⊣` | function | Identity / Left | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `⊢` | function | Identity / Right | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `⥊` | function | Deshape / Reshape | 20 | 3 | 0 | 5 | 0 | 0 | 0 | 0 | **used** |
| `∾` | function | Join / Join To | 1233 | 986 | 4 | 592 | 0 | 0 | 0 | 0 | **used** |
| `≍` | function | Solo / Couple | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `⋈` | function | Enlist / Pair | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `↑` | function | Prefixes / Take | 39 | 38 | 0 | 5 | 0 | 0 | 0 | 0 | **used** |
| `↓` | function | Suffixes / Drop | 42 | 88 | 0 | 40 | 0 | 0 | 0 | 0 | **used** |
| `↕` | function | Range / Windows | 86 | 59 | 0 | 12 | 0 | 0 | 0 | 0 | **used** |
| `»` | function | Nudge / Shift Before | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `«` | function | Nudge Back / Shift After | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `⌽` | function | Reverse / Rotate | 11 | 7 | 0 | 7 | 0 | 0 | 0 | 0 | **used** |
| `⍉` | function | Transpose / Reorder Axes | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `/` | function | Indices / Replicate | 234 | 111 | 0 | 23 | 0 | 0 | 0 | 1952 | **used** |
| `⍋` | function | Grade Up / Bins Up | 4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **used** |
| `⍒` | function | Grade Down / Bins Down | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `⊏` | function | First Cell / Select | 33 | 0 | 0 | 2 | 0 | 0 | 0 | 0 | **used** |
| `⊑` | function | First / Pick | 631 | 572 | 3 | 412 | 0 | 0 | 0 | 0 | **used** |
| `⊐` | function | Classify / Index Of | 16 | 6 | 0 | 15 | 0 | 0 | 0 | 0 | **used** |
| `⊒` | function | Occurrence Count / Progressive Index Of | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `∊` | function | Mark Firsts / Member Of | 18 | 21 | 0 | 1 | 0 | 0 | 0 | 0 | **used** |
| `⍷` | function | Deduplicate / Find | 4 | 13 | 0 | 25 | 0 | 0 | 0 | 0 | **used** |
| `⊔` | function | Group Indices / Group | 12 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **used** |
| `!` | function | Assert / Assert with Message | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 80 | **unused** |
| `˙` | 1-modifier | Constant | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `˜` | 1-modifier | Self / Swap | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | **used** |
| `˘` | 1-modifier | Cells | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `¨` | 1-modifier | Each | 661 | 324 | 0 | 181 | 0 | 0 | 0 | 0 | **used** |
| `⌜` | 1-modifier | Table | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `⁼` | 1-modifier | Undo | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `´` | 1-modifier | Fold | 160 | 168 | 0 | 79 | 0 | 0 | 0 | 0 | **used** |
| `˝` | 1-modifier | Insert | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| ``` | 1-modifier | Scan | 21 | 10 | 0 | 4 | 0 | 0 | 0 | 20 | **used** |
| `∘` | 2-modifier | Atop | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `○` | 2-modifier | Over | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `⊸` | 2-modifier | Before / Bind | 94 | 54 | 0 | 15 | 0 | 0 | 0 | 0 | **used** |
| `⟜` | 2-modifier | After / Bind | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `⌾` | 2-modifier | Under | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `⊘` | 2-modifier | Valences | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `◶` | 2-modifier | Choose | 7 | 152 | 0 | 6 | 0 | 0 | 0 | 0 | **used** |
| `⎉` | 2-modifier | Rank | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `⚇` | 2-modifier | Depth | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **unused** |
| `⍟` | 2-modifier | Repeat | 522 | 338 | 0 | 36 | 0 | 0 | 0 | 0 | **used** |
| `⎊` | 2-modifier | Catch | 1 | 1 | 0 | 2 | 0 | 0 | 0 | 0 | **used** |

Runtime-unused total: **23 of 64**.

Runtime-unused glyphs: `√` `⊣` `⊢` `≍` `⋈` `»` `«` `⍉` `⍒` `⊒` `!` `˙` `˘` `⌜` `⁼` `˝` `∘` `○` `⟜` `⌾` `⊘` `⎉` `⚇`

## Representative executable locations

- `+` Conjugate / Add: `src/accounting/cycle_account_period.bqn:52`, `src/accounting/cycle_calendar_month_resolution.bqn:6`, `src/accounting/cycle_calendar_month_resolution.bqn:17`, `src/accounting/cycle_calendar_month_resolution.bqn:20`, `src/accounting/envelope_backing.bqn:91`
- `-` Negate / Subtract: `src/accounting/account_period.bqn:107`, `src/accounting/cycle_calendar_month_resolution.bqn:17`, `src/accounting/cycle_calendar_month_resolution.bqn:18`, `src/accounting/cycle_comparison.bqn:47`, `src/accounting/cycle_comparison.bqn:48`
- `×` Sign / Multiply: `src/accounting/cycle_calendar_month_resolution.bqn:17`, `src/accounting/matrix_result.bqn:46`, `src/accounting/month_account_movement.bqn:16`, `src/accounting/plan_temporal_status.bqn:17`, `src/application/report_destination_cli.bqn:21`
- `÷` Reciprocal / Divide: `src/accounting/cycle_calendar_month_resolution.bqn:6`, `src/accounting/daily_target.bqn:154`, `src/accounting/daily_target.bqn:155`, `src/accounting/month_account_movement.bqn:18`, `src/application/editor_actual.bqn:30`
- `⋆` Exponential / Power: `src/application/editor_actual.bqn:30`, `src/application/report_destination_cli.bqn:21`, `src/ledger/date_ordinal.bqn:6`, `src/ledger/journal_transaction_structure.bqn:38`, `src/text/parse.bqn:24`
- `⌊` Floor / Minimum: `src/accounting/account_balance.bqn:21`, `src/accounting/cycle_account_period.bqn:52`, `src/accounting/cycle_calendar_month_resolution.bqn:6`, `src/accounting/cycle_income_anchor_resolution.bqn:82`, `src/accounting/daily_target.bqn:54`
- `⌈` Ceiling / Maximum: `src/accounting/account_balance.bqn:36`, `src/accounting/account_period.bqn:47`, `src/accounting/cycle_comparison.bqn:58`, `src/accounting/cycle_income_anchor_resolution.bqn:61`, `src/accounting/cycle_income_anchor_resolution.bqn:70`
- `∧` Sort Up / And: `src/accounting/account_balance.bqn:33`, `src/accounting/account_balance.bqn:40`, `src/accounting/account_period.bqn:40`, `src/accounting/account_period.bqn:49`, `src/accounting/account_period.bqn:58`
- `∨` Sort Down / Or: `src/accounting/account_balance.bqn:7`, `src/accounting/account_balance.bqn:21`, `src/accounting/account_period.bqn:7`, `src/accounting/cycle_account_period.bqn:49`, `src/accounting/cycle_comparison.bqn:8`
- `¬` Not / Span: `src/accounting/account_balance.bqn:19`, `src/accounting/account_balance.bqn:20`, `src/accounting/account_balance.bqn:30`, `src/accounting/account_balance.bqn:41`, `src/accounting/account_period.bqn:29`
- `|` Absolute Value / Modulus: `src/accounting/cycle_calendar_month_resolution.bqn:6`, `src/accounting/month_account_movement.bqn:18`, `src/ledger/amount_text.bqn:6`, `src/ledger/date_ordinal.bqn:7`, `src/ledger/exact_scale.bqn:14`
- `≤` Less Than or Equal To: `src/accounting/account_balance.bqn:33`, `src/accounting/cycle_account_period.bqn:47`, `src/accounting/cycle_income_anchor_resolution.bqn:57`, `src/accounting/cycle_income_anchor_resolution.bqn:66`, `src/accounting/daily_target.bqn:184`
- `<` Enclose / Less Than: `src/accounting/account_balance.bqn:21`, `src/accounting/account_balance.bqn:36`, `src/accounting/account_balance.bqn:78`, `src/accounting/account_period.bqn:47`, `src/accounting/account_period.bqn:58`
- `>` Merge / Greater Than: `src/accounting/cycle_income_anchor_resolution.bqn:78`, `src/accounting/daily_target.bqn:93`, `src/accounting/plan_temporal_status.bqn:17`, `src/application/daily_scope_adapter.bqn:74`, `src/application/report_destination_cli.bqn:43`
- `≥` Greater Than or Equal To: `src/accounting/account_period.bqn:31`, `src/accounting/account_period.bqn:59`, `src/accounting/daily_target.bqn:35`, `src/accounting/daily_target.bqn:86`, `src/accounting/daily_target.bqn:154`
- `=` Rank / Equals: `src/accounting/account_balance.bqn:33`, `src/accounting/account_balance.bqn:48`, `src/accounting/account_balance.bqn:65`, `src/accounting/account_balance.bqn:73`, `src/accounting/account_balance.bqn:76`
- `≠` Length / Not Equals: `src/accounting/account_balance.bqn:21`, `src/accounting/account_balance.bqn:36`, `src/accounting/account_balance.bqn:67`, `src/accounting/account_balance.bqn:73`, `src/accounting/account_balance.bqn:76`
- `≡` Depth / Match: `src/accounting/account_balance.bqn:7`, `src/accounting/account_balance.bqn:8`, `src/accounting/account_balance.bqn:40`, `src/accounting/account_balance.bqn:45`, `src/accounting/account_balance.bqn:59`
- `≢` Shape / Not Match: `src/accounting/account_balance.bqn:50`, `src/accounting/account_balance.bqn:63`, `src/accounting/account_period.bqn:28`, `src/accounting/cycle_comparison.bqn:42`, `src/accounting/daily_target.bqn:50`
- `⥊` Deshape / Reshape: `src/ledger/amount_text.bqn:8`, `src/ledger/date_ordinal.bqn:14`, `src/ledger/date_ordinal.bqn:29`, `src/ledger/exact_scale.bqn:14`, `src/ledger/facts.bqn:99`
- `∾` Join / Join To: `src/accounting/account_balance.bqn:7`, `src/accounting/account_balance.bqn:19`, `src/accounting/account_balance.bqn:20`, `src/accounting/account_balance.bqn:22`, `src/accounting/account_balance.bqn:30`
- `↑` Prefixes / Take: `src/accounting/month_account_movement.bqn:52`, `src/accounting/month_category_flow.bqn:27`, `src/application/actual_journal_admission.bqn:10`, `src/application/editor_actual.bqn:9`, `src/application/editor_config_path.bqn:8`
- `↓` Suffixes / Drop: `src/accounting/recent_transactions.bqn:36`, `src/application/daily_scope_admission.bqn:75`, `src/application/date_today.bqn:3`, `src/application/ledger_inspect_cli.bqn:22`, `src/application/report_destination_cli.bqn:44`
- `↕` Range / Windows: `src/accounting/account_balance.bqn:67`, `src/accounting/account_period.bqn:48`, `src/accounting/account_period.bqn:89`, `src/accounting/daily_target.bqn:123`, `src/accounting/daily_target.bqn:134`
- `⌽` Reverse / Rotate: `src/accounting/recent_transactions.bqn:36`, `src/application/report_destination_cli.bqn:21`, `src/editor/journal_profile.bqn:41`, `src/ledger/date_ordinal.bqn:6`, `src/ledger/exact_decimal.bqn:27`
- `/` Indices / Replicate: `src/accounting/account_balance.bqn:12`, `src/accounting/account_balance.bqn:34`, `src/accounting/account_balance.bqn:35`, `src/accounting/account_balance.bqn:44`, `src/accounting/account_balance.bqn:45`
- `⍋` Grade Up / Bins Up: `src/accounting/date_category_flow.bqn:79`, `src/ledger/currency_registry.bqn:44`, `src/sections/daily_flow.bqn:18`, `src/sections/planned_payments.bqn:71`
- `⊏` First Cell / Select: `src/accounting/date_category_flow.bqn:80`, `src/accounting/date_category_flow.bqn:81`, `src/accounting/envelope_backing.bqn:135`, `src/accounting/envelope_backing.bqn:136`, `src/accounting/envelope_backing.bqn:137`
- `⊑` First / Pick: `src/accounting/account_balance.bqn:8`, `src/accounting/account_balance.bqn:38`, `src/accounting/account_balance.bqn:54`, `src/accounting/account_balance.bqn:55`, `src/accounting/account_balance.bqn:79`
- `⊐` Classify / Index Of: `src/accounting/account_balance.bqn:8`, `src/accounting/account_period.bqn:8`, `src/accounting/cycle_income_anchor_resolution.bqn:15`, `src/accounting/date_category_flow.bqn:14`, `src/accounting/date_category_flow.bqn:82`
- `∊` Mark Firsts / Member Of: `src/application/actual_journal_admission.bqn:9`, `src/application/config_rows.bqn:6`, `src/application/report_destination_cli.bqn:18`, `src/application/report_manifest_admission.bqn:14`, `src/editor/friend_travel_source_event.bqn:17`
- `⍷` Deduplicate / Find: `src/editor/friend_travel_source_event.bqn:68`, `src/editor/journal_profile.bqn:210`, `src/editor/journal_profile.bqn:233`, `src/editor/journal_profile.bqn:234`, `src/editor/journal_profile.bqn:346`
- `⊔` Group Indices / Group: `src/application/daily_scope_admission.bqn:7`, `src/ledger/account_admission.bqn:12`, `src/ledger/companion_admission.bqn:11`, `src/ledger/config_admission.bqn:16`, `src/ledger/currency_registry.bqn:7`
- `˜` Self / Swap: `src_edit/plan_budget_sync_cmd.bqn:66`
- `¨` Each: `src/accounting/account_balance.bqn:7`, `src/accounting/account_balance.bqn:8`, `src/accounting/account_balance.bqn:39`, `src/accounting/account_balance.bqn:40`, `src/accounting/account_balance.bqn:43`
- `´` Fold: `src/accounting/account_balance.bqn:7`, `src/accounting/account_balance.bqn:36`, `src/accounting/account_balance.bqn:40`, `src/accounting/account_period.bqn:7`, `src/accounting/account_period.bqn:47`
- ``` Scan: `src/application/daily_scope_admission.bqn:7`, `src/editor/journal_profile.bqn:36`, `src/editor/journal_profile.bqn:41`, `src/ledger/account_admission.bqn:12`, `src/ledger/companion_admission.bqn:11`
- `⊸` Before / Bind: `src/accounting/account_balance.bqn:7`, `src/accounting/account_balance.bqn:8`, `src/accounting/account_balance.bqn:45`, `src/accounting/account_period.bqn:7`, `src/accounting/account_period.bqn:8`
- `◶` Choose: `src/application/config_rows.bqn:6`, `src/application/config_rows.bqn:9`, `src/application/editor_actual.bqn:31`, `src/application/editor_actual.bqn:32`, `src/editor/friend_travel_source_event.bqn:21`
- `⍟` Repeat: `src/accounting/account_balance.bqn:36`, `src/accounting/account_balance.bqn:59`, `src/accounting/account_balance.bqn:72`, `src/accounting/account_balance.bqn:73`, `src/accounting/account_balance.bqn:74`
- `⎊` Catch: `src/editor/travel_exchange_event.bqn:96`, `src/ledger/exact_decimal.bqn:43`, `tests/test_editor_travel_exchange_event.bqn:89`, `tests/test_editor_travel_exchange_event.bqn:90`

## Modifier special names

| Name | Executable count | Corpora |
|---|---:|---|
| `𝕨` | 31 | editor:24, production:2, tests:5 |
| `𝕩` | 1044 | editor:414, production:448, tests:160, tools:22 |
| `𝕗` | 0 |  |
| `𝕘` | 0 |  |
| `𝕤` | 0 |  |
| `𝕣` | 0 |  |
| `𝕎` | 0 |  |
| `𝕏` | 0 |  |
| `𝔽` | 0 |  |
| `𝔾` | 0 |  |
| `𝕊` | 2092 | editor:794, production:1153, tests:145 |

## System values

| Name | Executable count | Corpora |
|---|---:|---|
| `•BQN` | 6 | editor:1, production:5 |
| `•Exit` | 76 | editor:43, production:30, tests:3 |
| `•FChars` | 56 | editor:3, production:1, tests:52 |
| `•Fmt` | 179 | editor:128, production:34, tests:15, tools:2 |
| `•Import` | 664 | editor:154, production:190, tests:320 |
| `•Out` | 257 | editor:108, production:51, tests:94, tools:4 |
| `•SH` | 11 | editor:9, production:1, tests:1 |
| `•Type` | 3 | tools:3 |
| `•UnixTime` | 2 | editor:2 |
| `•args` | 37 | editor:29, production:7, tests:1 |
| `•file` | 12 | editor:9, production:3 |
| `•wdpath` | 2 | editor:1, production:1 |

## Reproduction

```sh
python3 tools/bqn-primitive-inventory --ref 221c4234af615cbf31bb9e22a7600efed58b088c --format markdown
python3 tools/bqn-primitive-inventory --ref 221c4234af615cbf31bb9e22a7600efed58b088c --format json
```
