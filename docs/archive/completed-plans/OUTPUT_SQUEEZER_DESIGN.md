# Output Squeezer Design

Status: **replaced by `tools/query` (2026-06-26)**
Date: 2026-06-22 (original) / updated 2026-06-26

旧 `tools/sqz-report` は old-engine exporter（`export-report-numbers.bqn`, `export-actual-comparison.bqn`）に依存しており削除済み。
現在は薄い wrapper `tools/query` が `src_next/summary.bqn` の machine-readable 出力に対して同様の機能を提供する。

## 現在のツール

```bash
tools/query <base> <key>          # 値だけ返す
tools/query <base> --list          # 全 key=value
tools/query <base> --keys          # 全 key 名のみ
tools/query <base> --grep <pat>    # key 名で grep
```

計算はしない。既存の `tools/report-next-summary` 出力のフィルタのみ。

## 旧設計（履歴）

以下は旧 `tools/sqz-report` の設計。削除済み。

## 目的

- 人間向け report text の大量出力を AI コンテキストへ流さない。
- BQN exporter の machine-readable output を、key query / grep / compact diff へ絞る。
- golden 差分や report 数値確認の往復を短くする。

## 境界

```text
BQN exporters = canonical numbers / machine-readable tables
tools/sqz-report = query, filter, compact diff
```

`sqz-report` は計算しません。

禁止:

- 残高、封筒、cycle、actual comparison の再計算
- source TSV の編集
- human report text の装飾解析を正本にすること

## 入力 source

現在使う exporter:

- `src/reports/exporters/export-report-numbers.bqn`
- `src/reports/exporters/export-actual-comparison.bqn`

今後 section status などを広げる場合も、まず BQN exporter を source にしてから wrapper 側で絞ります。

## CLI

```bash
tools/sqz-report <base> [--as-of YYYY-MM-DD] <key>
tools/sqz-report <base> [--as-of YYYY-MM-DD] <key> --with-meta
tools/sqz-report <base> [--as-of YYYY-MM-DD] --list
tools/sqz-report <base> [--as-of YYYY-MM-DD] --grep PATTERN
tools/sqz-report <fixture> [--as-of YYYY-MM-DD] --diff
```

### scalar key

`export-report-numbers.bqn` の `key` 列をそのまま使います。

```bash
tools/sqz-report data liquid_assets_today
tools/sqz-report fixtures/basic --as-of 2026-06-16 cycle_actual_expense
```

既定出力は値だけです。

```text
123456
```

### `--with-meta`

scalar key の full TSV row を返します。

```bash
tools/sqz-report data liquid_assets_today --with-meta
```

出力:

```text
key	value	source_layer	status	formula_id	note
liquid_assets_today	...	actual	canonical	F001	...
```

### table key

`actual_comparison` の表は次の key 形式で参照します。

```text
actual_comparison:<period_kind>:<lane>:<unit>:<field>
```

例:

```bash
tools/sqz-report data actual_comparison:cycle:variable:food:diff_amount
```

`--with-meta` は v1 では scalar key のみ対応です。

### `--list`

全 key を `key=value` で短く出します。

### `--grep`

key 名に対して awk regex で絞ります。

```bash
tools/sqz-report data --grep liquid
tools/sqz-report fixtures/basic --grep '^cycle_'
```

### `--diff`

fixture の expected と actual を比較し、巨大 diff ではなく compact mismatch だけを出します。

参照 expected:

- `<fixture>/expected/report_numbers.tsv`
- `<fixture>/expected/actual_comparison.tsv` があれば併せて比較

## エラー方針

- base 未指定、不明 option、option 引数欠落は exit 1。
- key が存在しない場合は exit 1。
- `--diff` で expected がない場合は exit 1。
- `--with-meta` を table key に使った場合は exit 1。

## 今後の候補

- `--section balances|cycle|envelopes|actual-comparison|section-status`
- `--format tsv|json`。ただし JSON は TUI/GUI/app shell の要求が具体化してから。
- section status exporter の query 対応。
- よく使う長い table key の alias。
