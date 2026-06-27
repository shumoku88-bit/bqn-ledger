# fixtures/basic

`fixtures/basic` は、`bqn-ledger` の最小だが一通り揃った安定確認用fixtureです。

## 何を再現しているか

- opening balance から資産を作る。
- 銀行→現金の資金移動を含む。
- 固定費 (`expenses:rent`, `fixed=1`) と変動費 (`expenses:food`) を含む。
- `accounts.tsv` の `budget=...` メタから、支出が封筒消費へ導出される。
- 封筒は `daily` / `flex` / `reserve` を使う。
- 固定費 (`expenses:rent`) は封筒外に置く。
- `budget_alloc.tsv` で `budget:unassigned` から `budget:daily` / `budget:flex` / `budget:reserve` に配賦する。
- `cycle.tsv` は `fixed` で `2026-01-01` 〜 `<2026-02-01` を指定する。
- `plan.tsv` は意図的に日付順ではない。レポート側で未来予定が日付順に並ぶことを確認する。

## 使い方

```sh
bqn main.bqn fixtures/basic --as-of 2026-01-05
./tools/snapshot.sh
```

snapshot の期待出力:

```text
docs/snapshots/basic_main.txt
```

更新は、表示変更が意図的な場合だけ行う:

```sh
./tools/snapshot.sh --update
```

## 注意

- このfixtureはテスト用データで、実データではない。
- snapshot は outlook の today 依存を避けるため、`--as-of 2026-01-05` で固定している。
- TSV仕様や表示仕様を変えたら、`docs/REPORT_FIELD_MAP.md` / `docs/MAIN_SECTIONS.md` / snapshot も確認する。
