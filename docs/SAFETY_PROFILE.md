# Safety Profile

最終更新日: 2026-06-27
ステータス: **設計方針メモ / 未実装の検査項目を含む**

## 概要

この文書は、F-35 / JSF Air Vehicle C++ Coding Standards のような安全クリティカル系の考え方を、この家計簿レポートエンジン向けに翻訳したものです。

ここで目指すのは、航空機規格そのものへの準拠ではありません。
このリポジトリに必要なのは、個人用家計簿としての小さな安全規格です。

合言葉:

```text
変な入力で、きれいな間違いを出さない。
```

## 目的

- 正データ TSV を勝手に壊さない。
- 同じ入力からは同じレポートを出す。
- 入力不正や仕様外の状態を黙って補正しない。
- レポートが信用できない場合は、成功したふりをしない。
- BQN core / BQN editor / UI 補助 / AI 作業の責務境界を保つ。
- BQN editor や shell UI がなくても、source TSV、config TSV、BQN core だけで canonical report / export を生成できる経路を保つ。

## 対象範囲

この Safety Profile は、次の範囲に適用します。

| 範囲 | 扱い |
|---|---|
| `data/*.tsv` | 正データ。AIとレポートエンジンは原則直接変更しない。 |
| BQN report engine | 読み取り、検査、派生ビュー、レポート生成を担当する。 |
| BQN editor | 明示操作に基づく安全な TSV 追記・将来の編集経路を担当する。 |
| shell / gum / fzf | 表示、選択、検索、入力補助に徹する。 |
| docs / fixtures / tests | 契約と回帰確認を固定する。 |

## 基本原則

### 1. Source TSV is source of truth

`journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, `config.tsv` は、正データまたは設定データです。

BQN レポートエンジンはこれらを読んで派生値を作るだけで、正データを直接変更しません。
変更が必要な場合は、人間の確認、または専用 editor の明示操作を通します。

### 2. Fail closed, not pretty wrong

不正な入力を読んだときに、それっぽいレポートを出してはいけません。

例:

- 日付形式が壊れている。
- 金額が整数円ではない。
- `accounts.tsv` に存在しない account が使われている。
- 必須列が列ずれしている。
- `cycle.tsv` の区間が重複または逆転している。
- Cube の Layer 契約に反する projection がある。

この場合は、明示的な error / warning / skipped を出します。
黙って `misc` 扱い、今日扱い、ゼロ扱いなどにしません。

### 3. No implicit recovery

補正が必要な場合は、補正规則をコードの気分に埋め込まず、契約として文書化します。

許される補正:

- 文書化された default。
- fixture で固定された fallback。
- warning と一緒に出る互換処理。

避ける補正:

- 未知 account を自動で作る。
- 日付欠損を実行日に置き換える。
- 欠損 budget group を勝手に daily にする。
- plan / actual / budget の Layer を曖昧に混ぜる。

### 4. Deterministic report

同じ TSV と同じ引数からは、同じレポートを出します。

特に `as_of` は、実行中に各モジュールが勝手に `Today` を読むのではなく、入口で決めて渡します。
現在時刻が必要な export は、`system_now` / `generated_at` / `data_cutoff` などの意味を先に決めてから導入します。

### 5. Bounded computation

終わるか分からない探索や、資源上限が読みづらい処理を避けます。

BQN core では、なるべく有限の配列に投影してから処理します。

```text
Event IR -> Projection IR -> Day × Account × Layer -> report / export
```

再帰的に探し回るより、軸と shape を先に決めて、mask / group / fold / scan で扱います。

### 6. Boundary-preserving design

責務境界を崩さないことを、安全性の一部として扱います。

- BQN は正本数値エンジン。
- BQN editor は安全な書き込み経路。
- UI は入力補助と表示。
- AI は原則として実データ TSV を直接編集しない。
- 相談用の意味づけや助言は、canonical output に混ぜない。
- Canonical report / export は、source TSV (`data/*.tsv`)、config TSV (`data/config.tsv`, `config/system_defaults.tsv`, `config/default_config.tsv`, `config/meta_schema.tsv`) と BQN core だけで生成できる状態を維持する。
- BQN editor / shell UI / gum / fzf / helper scripts / helper-generated cache は外装であり、正本レポート計算の必須依存にしない。

## レポート状態

将来、section ごとに次の状態を持たせることを検討します。

| 状態 | 意味 |
|---|---|
| `OK` | 契約通りに計算できた。 |
| `WARN` | 互換処理または注意点があるが、出力は可能。 |
| `ERROR` | 契約違反があり、この section は信用できない。 |
| `SKIPPED` | 前提不足により意図的に出力しない。 |
| `UNAVAILABLE` | 履歴不足など、正常だが値を定義できない。 |

## Invariant 候補

### Source invariant

- `data/*.tsv` の先頭5列を壊さない。
- 空列を保持する必要がある読み込みでは `SplitKeepEmpty` を使う。
- 未定義 account を許さない。
- 金額は整数円。
- 実データ TSV は AI が明示指示なしに編集しない。

### Cube invariant

- Canonical Daily Cube の shape は `Day × Account × Layer` に固定する。
- 店舗、memo、カテゴリ、任意タグを Cube 軸に増やさない。
- `actual` は `journal.tsv` 由来。
- `plan` は `plan.tsv` 由来。
- `budget` は `budget_alloc.tsv` と journal 支出由来。
- `forecast` は予約 Layer として扱い、未実装時は安全にゼロまたは unavailable とする。
- `budget:*` account の Actual layer はゼロである。

### Time invariant

- `as_of` は入口で確定する。
- `system_today` より未来の journal 行は lint / strict check で止める。
- cycle は半開区間として扱い、重複・逆転を許さない。
- `as_of` より後の予定や実績を各 section がどう扱うかは、section 契約で明示する。

### Report execution invariant

- source TSV (`data/*.tsv`)、config TSV (`data/config.tsv`, `config/system_defaults.tsv`, `config/default_config.tsv`, `config/meta_schema.tsv`) と `src_next/**/*.bqn` で canonical report / export を生成できる。
- BQN editor, shell UI, gum/fzf, cache/helper-generated files を canonical report calculation の必須依存にしない。
- shell script で BQN-only 経路をテストすることは許容する。ただし守る対象は、レポート計算そのものが BQN と source/config TSV だけで完結すること。

### Editor invariant

- 書き込みは preview / confirm / backup / stale check / post-check lint を通す。
- 削除や大きな修正は、人間が TSV を直接確認して行う。
- multi-file transaction, 既存行編集, cycle/config/accounts 書き換えは、failure-injection と idempotency の検討前に広げない。

## 実装への落とし込み

まずは次の順で進めます。

1. 既存 check / lint / fixture がどの invariant を守っているか棚卸しする。
2. 不足している invariant を `docs/REPORT_CONTRACTS.md`, `docs/CANONICAL_DAILY_CUBE.md`, `docs/TIME_AS_AXIS.md` へ接続する。
3. `ERROR / WARN / SKIPPED / UNAVAILABLE` の出力方針を section 単位で設計する。
4. 失敗 fixture を追加し、きれいな間違いが出ないことを確認する。
5. BQN editor の書き込み範囲を広げる前に、idempotency / recurrence / recovery 契約を決める。

## 非目標

- 航空機規格そのものの完全再現はしない。
- 生活相談AIの助言を canonical output に混ぜない。
- 便利さのために正データの読みやすさを捨てない。
- 設定駆動化の名目で Canonical Daily Cube の shape や Layer 契約を利用者設定にしない。

## 関連文書

- `AGENTS.md`
- `TODO.md`
- `docs/QUALITY_BAR.md`
- `docs/SAFETY_PROFILE_INVARIANT_MAP.md`
- `docs/CANONICAL_DAILY_CUBE.md`
- `docs/TIME_AS_AXIS.md`
- `docs/REPORT_CONTRACTS.md`
- `docs/GO_EDITOR_USAGE.md`
- `docs/archive/active-plans/GO_EDITOR_NEXT_PLAN.md`
- `docs/archive/completed-plans/SAFE_WORKFLOW_REDESIGN.md`
