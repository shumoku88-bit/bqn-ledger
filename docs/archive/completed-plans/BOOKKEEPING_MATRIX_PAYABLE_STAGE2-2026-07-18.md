# Bookkeeping Matrix Study: Payable Recognition and Payment Stage 2

```text
Status: completed research fixture
Owner: other
Canonical: no; current routing remains TODO.md and NEXT_SESSION.md
Exit: completed; future accounting topics require separately selected slices
Date: 2026-07-18
```

## 1. 目的

本研究は、`shumoku88-bit/bqn-ledger` の簿記行列研究の第2題として、サービス費用の発生と買掛金の計上、およびその後の銀行支払いをBQN行列および累積残高（running balances）として検証することを目的としています。
特に、**費用を認識する時点と現金を支払う時点が別の会計イベントであること**を確認し、現在の符号規約における負債の増減方向が正確に評価・計算できることを実証します。

## 2. 二件の取引と手計算仕訳

本研究で用いるテスト用取引は以下の2件です。

### 取引1: サービス費用の発生と買掛金計上 (2026-09-15)
代金は後日支払う契約で、2,400円の保守サービスを受けた。
* **借方 (Dr.)**: 保守費用 (expenses:maintenance) 2,400円
* **貸方 (Cr.)**: 買掛金 (liabilities:accounts-payable) 2,400円

### 取引2: 買掛金の支払い (2026-09-25)
買掛金2,400円を銀行口座から支払った。
* **借方 (Dr.)**: 買掛金 (liabilities:accounts-payable) 2,400円
* **貸方 (Cr.)**: 銀行預金 (assets:bank) 2,400円

## 3. 符号規約と負債の増減

リポジトリで採用されている Posting IR 符号規約は以下の通りです。
* **借方方向 (Dr.)**: 正 (`+`)
* **貸方方向 (Cr.)**: 負 (`-`)

これに従い、各取引の発生時・消滅時の符号は以下のように振る舞います。
* **費用の増加 (借方)**: 正 (`+2400`)
* **負債の増加 (貸方)**: 負 (`-2400`) — 買掛金の計上
* **負債の減少 (借方)**: 正 (`+2400`) — 買掛金の支払い
* **銀行資産の減少 (貸方)**: 負 (`-2400`) — 現金支払い

## 4. event × account 行列

`expected-event-account-matrix.tsv` に定義された期待行列：

```text
event_key	layer	assets:bank	liabilities:accounts-payable	expenses:maintenance	row_total
expense-on-account	actual	0	-2400	2400	0
payable-payment	actual	-2400	2400	0	0
```

### 行ゼロ不変条件 (Double-Entry Balance Invariant)
各取引（行）の全勘定科目デルタの合計値（`row_total`）は常に `0` となり、複式簿記の基本である貸借一致不変条件が維持されます。

## 5. 累積残高 (Running Balances)

`expected-running-balances.tsv` に定義された期待累積残高：

```text
event_key	assets:bank	liabilities:accounts-payable	expenses:maintenance
expense-on-account	0	-2400	2400
payable-payment	-2400	0	2400
```

* **費用発生後**: 銀行預金は0円、買掛金（負債）が-2,400円（負の残高＝未払額がある状態）、費用が2,400円。
* **支払い後**: 買掛金は0円（負債消滅）、銀行預金が-2,400円、費用は2,400円のまま維持。

## 6. 会計上の核心：費用認識と支払いの分離

* **発生主義の徹底**: 費用はサービス（便益）の提供を受けた時点で認識されます。買掛条件によって現金支払いを後日に延期する場合でも、費用認識そのものは支払日まで延期されません。
* **支払いイベントの本質**: 支払時には新たな費用は認識されず、すでに計上された負債（買掛金）の消滅と銀行預金の減少（資産減少）が記録されます。
* **鏡関係**: 先に実施された売掛金研究（収益認識と回収の分離）に対し、本研究は費用認識と支払いの分離という鏡関係を構成しています。

## 7. 実装および検証結果

* **テスト用フィクスチャ追加**:
  - `fixtures/bookkeeping-matrix-payable/profile.journal`
  - `fixtures/bookkeeping-matrix-payable/expected-event-account-matrix.tsv`
  - `fixtures/bookkeeping-matrix-payable/expected-running-balances.tsv`
  - `fixtures/bookkeeping-matrix-payable/README.md`
* **テストスクリプト追加**:
  - `tests/test_bookkeeping_matrix_payable.bqn`
  - BQN `+`` スキャンを用いた累積残高計算と、期待される会計不変条件（費用発生後・支払い後）の厳密なアサーション検証を追加し、動作を確認しました。
* **テスト実行結果**:
  `test_bookkeeping_matrix_payable.bqn: OK` の出力を確認。既存の receivable テストや `check.sh` に含まれる全テストも Green です。

## 8. 設計上の制約と方針

* **parser 変更なし**: 既存の `src_next/journal_profile_stage1.bqn` の構文解析サブセット内に完全に収まるように journal フィクスチャを記述しました。
* **production 非接続**: 本研究はテストコードとフィクスチャのみに閉じられており、production loader、実際の `journal.tsv`、 Cube 等の稼働システムへは一切接続していません。
* **後続タスクの自動選定排除**: 本研究の完了後、次の簿記研究題材（accruals 等）や、Journal Posting IR adapter parity Stage 2 などの後続開発テーマを自動選定・実装開始しません。後続は、個別に finite candidate として選定・承認されてから着手するものとします。
