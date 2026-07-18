# BOOKKEEPING_MATRIX_RECEIVABLE_STAGE1-2026-07-18

Status: completed research fixture
Owner: other
Canonical: no; current routing remains TODO.md and NEXT_SESSION.md
Exit: completed; future accounting topics require separately selected slices
Date: 2026-07-18

---

## 目的
`shumoku88-bit/bqn-ledger` の簿記行列研究の第1題として、掛け売上による売掛金の発生からその現金回収までのプロセスを対象とした synthetic な BQN 行列検証用 fixture およびテストを追加する。本研究は journal parser の機能拡張ではなく、売上の認識と現金回収が別々の会計イベントであることを、仕訳・行列・累積残高（running balance）・手計算説明の四つで一致させることを目的とする。

## 二件の取引
本検証では、以下の単純化された二件の取引を対象とする。

1. **掛け売上 (2026-09-01)**:
   顧客へ3,000円のサービス/商品を掛けで販売。
   - 借方: assets:accounts-receivable (売掛金)  3,000 円
   - 貸方: income:sales (売上)  3,000 円
2. **売掛金の回収 (2026-09-10)**:
   売掛金3,000円が銀行口座へ入金。
   - 借方: assets:bank (銀行)  3,000 円
   - 貸方: assets:accounts-receivable (売掛金)  3,000 円

## 追加ファイル
本作業により以下のファイルを新規に追加した。
- `fixtures/bookkeeping-matrix-receivable/README.md` (手計算説明、符号規約、非対象範囲の整理)
- `fixtures/bookkeeping-matrix-receivable/profile.journal` (簿記行列研究用 JPY journal fixture)
- `fixtures/bookkeeping-matrix-receivable/expected-event-account-matrix.tsv` (期待される event × account 行列データ)
- `fixtures/bookkeeping-matrix-receivable/expected-running-balances.tsv` (期待される累積残高データ)
- `tests/test_bookkeeping_matrix_receivable.bqn` (BQN ユニットテストコード)
- 本完了記録ファイル

## event × account 行列
`expected-event-account-matrix.tsv` に定義された期待される仕訳行列は以下の通りである。
- 行方向は各取引（イベント）に対応。
- 列方向は勘定科目に対応。

| event_key | layer | assets:bank | assets:accounts-receivable | income:sales | row_total |
| :--- | :--- | :--- | :--- | :--- | :--- |
| credit-sale | actual | 0 | 3000 | -3000 | 0 |
| receivable-collection | actual | 3000 | -3000 | 0 | 0 |

## running balances
`expected-running-balances.tsv` に定義された、取引ごとの累積残高（Running Balances）は以下の通りである。
- 各行の累積和により、取引後の勘定残高の推移を表す。

| event_key | assets:bank | assets:accounts-receivable | income:sales |
| :--- | :--- | :--- | :--- |
| credit-sale | 0 | 3000 | -3000 |
| receivable-collection | 3000 | 0 | -3000 |

## 行ゼロ不変条件
各取引行の合計（`row_total`）は `0` になる。これは複式簿記における貸借平均の原理（ゼロ和）を体現し、不変条件としてテスト内で明示的にアサートされている。

## 売上認識と回収の分離
本研究で明示される会計上の核心は、**売上は掛け売上の時点で認識され、売掛金回収の時点では新たな売上は認識されない**という点である。
回収イベントによって、資産の形態が売掛金から銀行預金へと置き換わるのみであり、累積売上高は一貫して `¯3000 JPY` (貸方方向3000円) で不変であることを検証している。

## テスト結果
`tests/test_bookkeeping_matrix_receivable.bqn` を実行し、以下の項目が検証をパスすることを確認した。
- parser の解析結果（state ＝ "ok", diagnostics ＝ 0, 各件数）
- layer および event_id、durable identity 属性
- `BuildMatrix` による event × account 行列の完全一致
- BQN の累積和（`+\`）による running balances 導出と TSV 定義値の完全一致
- 最終残高の会計的整合性

## production 非接続
本研究は test-only な fixture および検証コードの追加にとどまり、以下の production 関連機能には一切接続・影響していない。
- production loader
- editor (日常の write path)
- main report path
- Posting IR production adapter
- Cube, TBDS
- 実際の source TSV や private data

## 次題を自動選定しないこと
本 Stage 1 研究の完了に伴い、次の簿記研究題材は未選定のまま保留とする。同様に、Journal Posting IR adapter parity Stage 2 やその他の未選定候補についても、自動的に次の作業対象として選定しない。
