# Budget envelope redesign plan

Status: implemented on 2026-06-07.

## 目的

細かいカテゴリ別封筒をやめ、毎サイクルの配賦作業を軽くする。

従来の `食費` / `嗜好品` / `日用品` / `学習` のような細かい封筒は、管理できる範囲が広い一方で、日常運用では配賦判断が面倒になりやすい。

今後は「何に使ったか」ではなく、「お金の役割」で封筒を分ける。

## 新しい封筒

- `budget:daily`
  - 毎日の消費。
  - 食費、タバコ、缶コーヒーなど、日割りで見たい支出。

- `budget:flex`
  - 通常の裁量枠。
  - 日用品、学習、交通など、daily ほど毎日ではないが、固定費でもない支出。

- `budget:reserve`
  - 安全弁・予備。
  - 予定外支出や判断保留のための取り置き。

## expense -> budget 対応案

### daily

```tsv
expenses:食費	budget=daily	spend_class=variable
expenses:食費:ストック	budget=daily	spend_class=variable
expenses:タバコ	budget=daily	spend_class=variable
expenses:缶コーヒー	budget=daily	spend_class=variable
```

### flex

```tsv
expenses:日用品	budget=flex	spend_class=variable
expenses:学習	budget=flex	spend_class=variable
expenses:交通	budget=flex	spend_class=variable
```

### reserve

```tsv
expenses:予備	budget=reserve	spend_class=variable
```

## 封筒にしないもの

### 固定費

固定費は封筒化しない。

既存の以下で扱う。

- `fixed=1`
- `spend_class=fixed`
- `plan.tsv`
- `daily-trend` の fixed reserve（未払い固定費の予約控除。封筒 `budget:reserve` とは別物）

対象例:

- `expenses:家賃`
- `expenses:通信`
- `expenses:光熱費`
- `expenses:保険料`
- `expenses:借金返済`
- `expenses:AIサブスク`
- `expenses:サブスク`

### 貯金・投資

貯金・投資は封筒化しない。

理由:

- 使ってよい予算として目立たせたくない。
- `assets:ゆうちょ` / `assets:オルカン積立` という資産として管理すれば十分。
- 必要なら `plan.tsv` の資産移動予定で扱う。

## 移行対象

### accounts.tsv

予算口座を旧粒度から新粒度へ変更する。

旧候補:

- `budget:食費`
- `budget:嗜好品`
- `budget:日用品`
- `budget:バッファ`
- `budget:学習`
- `budget:貯金`
- `budget:投信`

新候補:

- `budget:daily`
- `budget:flex`
- `budget:reserve`

`budget:opening` / `budget:unassigned` / `budget:spent` は維持する。

### budget_alloc.tsv

現在の配賦:

```tsv
2026-05-30	seed	budget:opening	budget:unassigned	9779
2026-05-30	alloc	budget:unassigned	budget:嗜好品	3642
2026-05-30	alloc	budget:unassigned	budget:食費	5907
2026-06-03	realloc-food-to-study	budget:食費	budget:学習	2310
```

最終的な移行は、旧配賦の帳尻合わせではなく、2026-06-07 から新封筒をリセット開始する方式にした。

```tsv
2026-06-07	seed-reset	budget:opening	budget:unassigned	8170
2026-06-07	alloc-reset-daily	budget:unassigned	budget:daily	8170
```

意味:

- 旧 `食費` / `嗜好品` / `学習` などの細かい封筒履歴は引き継がない。
- 2026-06-07 時点で、残りの封筒対象額を `daily` にまとめる。
- `budget_alloc.tsv` の開始日が 2026-06-07 になるため、それ以前の支出は予算消費に含めない。
- 同日 2026-06-07 の記帳済み daily 支出は日付粒度の都合で予算消費に含まれるため、seed-reset は現在流動資産 6339 に同日 daily 支出 1831 を足した 8170 としている。

## 注意点

`accounts.tsv` の `budget=...` は、過去の `journal.tsv` 支出にも再計算として効く。

そのため、`accounts.tsv` だけを先に変更すると、旧 `budget_alloc.tsv` との対応が崩れ、封筒残高が大きくずれる可能性がある。

実施時は次を同じ変更セットで行う。

1. `accounts.tsv` の budget accounts / `budget=...` を変更
2. `budget_alloc.tsv` の旧封筒配賦を新封筒へ移行
3. docs の例を更新
4. `rtk ./tools/check.sh` を実行

## 実施しないこと

この移行では、以下は行わない。

- `journal.tsv` の書き換え
- 貯金・投資の封筒化
- 固定費の封筒化
- `plan.tsv` の書き換え

## 実施後に確認すること

- `bqn main.bqn --section envelopes`
  - 活動/残高がある新封筒（例: `budget:daily`）が表示されること
  - `budget:flex` / `budget:reserve` は定義済みでも、配賦や消費がなければ表示されないことがある
  - 旧 `食費` / `嗜好品` / `学習` が不要に残らないこと

- `bqn main.bqn --section daily-trend`
  - fixed reserve の見え方が変わらないこと

- `bqn main.bqn --section cycle-consult`
  - 固定費・予定の相談表示が壊れないこと

- `rtk ./tools/check.sh`
  - 全体チェックが通ること
