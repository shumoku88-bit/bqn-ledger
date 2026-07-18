# Bookkeeping Matrix Study: Prepaid Insurance Payment and One-Month Expense Recognition Stage 3

Status: completed research fixture
Owner: other
Canonical: no; current routing remains TODO.md and NEXT_SESSION.md
Exit: completed; future accounting topics require separately selected slices
Date: 2026-07-18

## 目的

簿記行列研究のStage 3として、1年分の保険料支払いと1か月分の費用認識を、journal取引ブロック、event × account行列、running balances、BQN assertionsと手計算説明の四つで一致させた。

本作業はpublic synthetic fixtureによるtest-only研究であり、production機能ではない。

## 二件の仕訳

### 1年分の保険料を前払い（2026-10-01）

```text
借方  assets:prepaid-insurance  12000
貸方  assets:bank               12000
```

符号付きposting:

```text
assets:prepaid-insurance   12000
assets:bank               -12000
```

この時点では保険サービスをまだ受けていないため、`expenses:insurance`を増加させない。

### 1か月分の保険費用を認識（2026-10-31）

```text
借方  expenses:insurance         1000
貸方  assets:prepaid-insurance   1000
```

符号付きposting:

```text
expenses:insurance          1000
assets:prepaid-insurance   -1000
```

この取引は前払資産から費用への振替であり、`assets:bank`を動かさない。

## 符号規約

Posting IRでは借方方向を正、貸方方向を負とする。

- 資産の増加: 正
- 資産の減少: 負
- 費用の増加: 正

## event × account行列

```text
event_key	layer	assets:bank	assets:prepaid-insurance	expenses:insurance	row_total
insurance-prepaid	actual	-12000	12000	0	0
insurance-month-recognized	actual	0	-1000	1000	0
```

各event行の合計は0であり、取引ごとの貸借一致を保持する。

## running balances

BQNのscan `` +` `` をevent × account行列へ適用して導出する。

```text
event_key	assets:bank	assets:prepaid-insurance	expenses:insurance
insurance-prepaid	-12000	12000	0
insurance-month-recognized	-12000	11000	1000
```

## 前払資産と費用認識の意味

現金を先に支払っても、将来受けるサービスに対応する未消費部分は直ちに費用にはならず、前払費用という資産になる。サービスを受けた期間に応じて、その資産を費用へ振り替える。

最終時点では前払保険料11,000 JPYと保険費用1,000 JPYが残り、次の保存関係が成立する。

```text
11000 + 1000 = 12000
```

これは当初支払額12,000 JPYが、未消費の前払資産と認識済み費用へ配分されたことを表す。

## 実装ファイル

- `fixtures/bookkeeping-matrix-prepaid-insurance/profile.journal`
- `fixtures/bookkeeping-matrix-prepaid-insurance/expected-event-account-matrix.tsv`
- `fixtures/bookkeeping-matrix-prepaid-insurance/expected-running-balances.tsv`
- `fixtures/bookkeeping-matrix-prepaid-insurance/README.md`
- `tests/test_bookkeeping_matrix_prepaid_insurance.bqn`
- `docs/archive/completed-plans/BOOKKEEPING_MATRIX_PREPAID_INSURANCE_STAGE3-2026-07-18.md`

## 検証コマンド

```text
bqn tests/test_bookkeeping_matrix_prepaid_insurance.bqn
bqn tests/test_bookkeeping_matrix_payable.bqn
bqn tests/test_bookkeeping_matrix_receivable.bqn
bqn tests/test_src_next_journal_profile_stage1.bqn
bash tools/check.sh
bash tools/coverage
git diff --check origin/main...HEAD
```

## production非接続境界

- `src_next/journal_profile_stage1.bqn`は変更しない
- production loader、editor、reports、Posting IR production adapter、Cube、TBDSへ接続しない
- source TSVやprivate dataを読み書きしない
- 自動償却、スケジュール、recurrence、月末締め、writer、source migrationを実装しない
- Journal Posting IR adapter parity Stage 2へ進まない

## 次題を自動選定しないこと

Stage 3完了後も、前受収益などの次の簿記研究題材、parser拡張、adapter parity、production routingを自動選定しない。次の有限sliceは別途明示的に選定する。
