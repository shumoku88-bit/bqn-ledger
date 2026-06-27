# BQN Conventions for AI

Status: AI作業効率化ガイド / living document
Date: 2026-06-22

この文書は、pit が BQN コードを触るときの事故とデバッグ往復を減らすための短い規約です。

目的は BQN の完全な入門ではなく、このリポジトリで実際に起きやすい失敗を先に避けることです。

## 1. 最重要ルール

- 変更は小さく、1目的だけにする。
- `data/journal.tsv` / `data/plan.tsv` / `data/budget_alloc.tsv` / `data/accounts.tsv` は勝手に変更しない。
- journal-like TSV を分割するときは、空列を落とさない。原則 `lib.SplitKeepEmpty` を使う。
- `BuildCube` の意味、Canonical Daily Cube の shape、Layer 契約をついでに変えない。
- pure BQN 関数を追加・変更したら、可能な限り `tests/test_*.bqn` を追加・更新する。
- レポート公開フィールドや main section を変えたら、対応する docs も更新する。

## 2. BQN の同質化に注意する

BQN はリスト要素の形がそろうと、自動的に配列へマージされることがある。

危険な例:

```bqn
values ⇐ ⟨"OK", "OK"⟩
```

同じ長さの文字列が並ぶと、期待した「文字列2個のリスト」ではなく、2D 的な文字配列として扱われる場合がある。
一方で長さが違うとネスト構造になり、fixture によって型・shape が揺れる。

安全寄りの書き方:

```bqn
values ⇐ ⟨<"OK", <"WARN"⟩
```

取り出し側では、必要に応じて Disclose する。

```bqn
status ⇐ > idx ⊑ values
```

方針:

- 文字列、行、record 的な値を「リストの要素」として保持したいときは `<` で包むことを検討する。
- fixture によって文字列長が変わる値は特に包む。
- 取り出し側の `>` は、どこで box を外すかを明示するために局所化する。

## 3. shape を先に疑う

BQN のエラーは抽象的になりやすい。原因探索では値そのものより先に shape / rank / empty を疑う。

確認したいこと:

- 空配列ではないか
- scalar と list を取り違えていないか
- boxed value をそのまま文字出力していないか
- 同質化で想定外の配列になっていないか
- 1行だけの fixture と複数行 fixture で shape が変わらないか

小さい再現を作れる場合は、先に BQN ワンライナーや小テストで確認する。

## 4. TSV 分割では空列を保持する

journal-like TSV の先頭5列は固定:

```text
date memo from to amount
```

memo が空でも列位置を保つ必要がある。

避けること:

- 単純な split で空列を落とす
- `date from to amount` のように memo 欠落行を別形式として扱う
- 6列目以降の `key=value` メタを先頭5列の意味に混ぜる

原則:

```text
journal-like TSV を読む処理では lib.SplitKeepEmpty
```

## 5. fail closed を優先する

不正入力や未対応状態では、きれいな間違いを出さない。

優先順位:

1. error
2. warning / skipped / unavailable
3. 明示された fallback
4. 黙って 0 や空表示にする、は最後の手段

特に注意する値:

- 0 に見えるが、実際はデータ不足で計算不能な値
- 未定義 account
- budget mapping 欠落
- stale plan
- future anchor 欠落

## 6. レポート変更時の docs 同期

`src/reports/report_engine.bqn` の公開フィールドを変えたら:

- `docs/REPORT_FIELD_MAP.md`

`src/reports/main.bqn` や section 構成を変えたら:

- `docs/MAIN_SECTIONS.md`
- 必要なら `docs/REPORT_CONTRACTS.md`

section status を増やす場合:

- `docs/REPORT_SECTION_STATUS_POLICY.md`
- machine export が関係するなら exporter docs / check も確認する。

## 7. デバッグ時の推奨手順

1. `rtk git diff` で自分の差分だけ見る。
2. 失敗している check / test を最小範囲で再実行する。
3. shape / box / empty-field のどれが原因か仮説を立てる。
4. 小さい BQN 式または `tests/test_*.bqn` で再現する。
5. 修正後に `rtk git diff` で docs とテストの同期漏れを見る。
6. 可能なら `./checks/check.sh` または該当 check を実行する。

長い出力になりそうなコマンドは `rtk` または `sqz` を前置する。

## 8. よくある安全な実装方針

- 既存関数を大きく書き換えるより、小さい helper を追加してテストする。
- fallback を増やす前に、unknown / missing / duplicate の扱いを決める。
- 実データではなく fixture で再現する。
- 新しいメタキーを増やす場合は、先に `config/meta_schema.tsv` と `docs/JOURNAL_META.md` を更新する。
- Canonical Daily Cube に新しい意味を押し込まず、必要なら別 projection / view を作る。

## 9. pit への短い注意文

```text
BQN変更では同質化・box・shape・空TSV列に注意してください。
journal-like TSV は SplitKeepEmpty を使ってください。
実データ data/*.tsv は変更しないでください。
公開フィールドや section を変えたら docs も同期してください。
```

## 10. BQN 構文ハマりポイント

このリポジトリで実際に発生した構文トラブルと回避策の一覧。

### 10.1 `? ;` の最終ブランチに `@ ;` が書けない

```bqn
# ❌ エラー: Double subjects (missing ‿?)
op ≡ "list" ? (fn ⊑ ⟨FnA, FnB⟩) @ ;

# ✅ 回避: ⍟ で書き換える
{FnA @}⍟(op ≡ "list") @
```

原因: BQN パーサが `@ ;` を「2つの主語が並んでいる」と解釈する。
`? cond { ... } @ ;` の形は避け、`⍟` による条件実行か `◶` による選択を優先する。

### 10.2 `? ;` はファイルトップレベルに書けない

```bqn
# ❌ エラー: Punctuation : ; ? outside block top level
(≠ args) < 2 ? { •Out "usage" } ;

# ✅ 回避: 関数で囲む
{𝕊: (≠ args) < 2 ? { •Out "usage" } ; @ } @
```

トップレベルの制御には `⍟` を使うか、全体を関数 `{𝕊: ...}` で包む。

### 10.3 `⊑` は両辺を先行評価する

```bqn
# ❌ 危険: has_args が偽でも (3 ⊑ args) が評価されて out-of-bounds
label_arg ← (3 < ≠ args) ⊑ ""‿(3 ⊑ args)

# ✅ 回避: ⍟ で遅延評価
label_arg ← ""
{𝕊: label_arg ↩ 3 ⊑ args}⍟(3 < ≠ args) @
```

`⟨a, b⟩` のリスト構築は a, b 両方を即時に評価する。
条件次第で片方だけ評価したい場合は `⍟` と `↩` を使う。

### 10.4 `↩` は即時関数の外側の変数を変更する

```bqn
DoPace ← {𝕊 label:
  e ← FindEnvelope label
  out ← ""
  {𝕊: out ↩ "result"}⍟(e ≢ @) @   # out は DoPace のローカル変数
  {𝕊: out ↩ "error"}⍟(e ≡ @) @
  •Out out
}
```

`{𝕊: ...}⍟(cond) @` の中で `↩` すると、その即時関数の**外側**（`DoPace` のスコープ）の変数を変更する。
外側の変数は `←` で事前に定義しておく必要がある。

### 10.5 ブロックには `𝕊` が必要

```bqn
# ❌ エラー: Role of the two sides in assignment must match
DoList ← {
  •Out "header"
}

# ✅ 修正
DoList ← {𝕊:
  •Out "header"
}
```

引数を取らないブロックでも `𝕊`（または `𝕊:`）は必須。

## 11. BQN エラー診断カタログ

エラーメッセージから原因を素早く特定するための逆引き。

| エラーメッセージ | 最も疑うべき原因 | 確認手順 |
|---|---|---|
| `𝕩 cannot be empty` | `⊑` の対象が空リスト。フィルタ `/` で全要素が除外された、または `⊐` でマッチなし。 | `≠` で長さを確認。空でない前提なら条件を見直す。 |
| `indexing out-of-bounds (𝕨≡N, N≡≠𝕩)` | `i ⊑ arr` で i ≧ ≠arr。引数の個数不足、または `args` のインデックスが過剰。 | `≠ args` を `•Out` して確認。`args` の長さチェックを `⍟` で行っているか。 |
| `Punctuation : ; ? outside block top level` | ファイルトップレベルに `? ;` が裸で書かれている。 | §10.2 参照。`{𝕊: ...}` で包むか `⍟` に置き換える。 |
| `Double subjects (missing ‿?)` | `? cond { ... } @ ;` の `@ ;` 部分。または `a b` のように値が2つ並んでいる。 | §10.1 参照。`? ;` のブランチ末尾の `@ ;` を避ける。 |
| `Role of the two sides in assignment must match` | ブロックに `𝕊` がない。`←` の左右の型不一致。 | §10.5 参照。ブロック定義に `𝕊` または `𝕊:` があるか。 |
| `Undefined identifiers` | 変数が現在のスコープで見えない。多くの場合 `? { ... } ; { ... }` のブロック境界。 | `? ;` のブロック内で外側の変数を使っていないか。使うなら `⍟` パターンに置き換える。 |
| `Unmatched bracket` | 括弧の数が合っていない。`()` `{}` `⟨⟩` の対応を確認。 | エラー行の前後を含めて括弧の開閉を数える。 |
| `•Import: No such file or directory` | Import パスが間違っている。作業ディレクトリが repo root でない。 | `•Import` の相対パスが正しいか。`cd` してから実行しているか。 |

### 診断フロー

エラーが出たら以下の順で確認する:

1. エラーメッセージをこのカタログと照合する
2. 該当行の前後3行を読む（BQN のエラー位置は正確）
3. 疑わしい変数の型・shape を `bqn-dump` で確認する
4. 小さい再現コードで `bqn-eval` を使って切り分ける
5. 修正後、該当 test を再実行する
