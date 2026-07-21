# Journal split-purchase transaction characterization — test-only plan

Status: completed
Owner: journal source migration
Canonical: no; canonical routing remains `TODO.md`
Exit: focused characterization implementation, review, completion record, and explicit return to no selected finite Journal slice
Date: 2026-07-22

## Purpose

現在のTSV記録面では、生活上は一つの買い物であっても、分類ごとに複数の物理行として記帳される。
今回のスライスでは、Journal transaction blockを使って、以下の要素を同時に保持できることを、public synthetic evidenceだけでcharacterizeする。

- 一つの店での一回の支払い
- 複数の費用科目への内訳
- 一つの支払元
- transaction-localな均衡
- posting順序
- 一つの出来事としてのidentity

目的はproduction Journal導入ではない。
目的は、mokoの日常的な要求である、
「一回の買い物を一つの取引として残しながら、タバコ、コーヒー、通常の食費、ストック食費、日用品などへ分けて記帳する」
という入力構造が、既存のtest-only Journal read pathで意味を保つか確認することである。

## Finite question

> Can public synthetic Journal purchase transactions preserve one real-world purchase event containing multiple expense-category postings and one payment posting through Stage 1, the read-only source carrier, Stage 2A, and numeric account reduction, while retaining posting order, transaction-local balance, and exact category totals, using tax-inclusive amounts and remaining disconnected from production routing?

### 日本語での補足
単一の買い物の支払いを複数の費用科目に内訳（スプリット）して記帳する際、既存のBQNパーサー（Stage 1）及びPosting IRアダプター（Stage 2A）、そしてread-only carrierを通じて、以下の点が一貫して保持・計算されるか：
- 記帳された順序（posting order）
- トランザクション内での貸借均衡（transaction-local balance）
- 正確な科目ごとの集計（exact category totals）
- 税込金額による一貫した扱い
- productionへの影響を持たず、テスト環境のみでの分離

## Selected public synthetic evidence

次の3つのトランザクションを選定する。Journal source内では、commodityとすべてのaccountを明示的に宣言し、すべてのaccountをsynthetic `resolved.accounts`にも存在させ、registry mismatchを発生させない。

ordinary actual purchaseのcharacterizationとして、明示的な`event-id`を必須にしない。既存Stage 1のphysical fallback identityを利用し、3つのtransactionが別々の`source_event_id`として保持されることを確認する。

### Transaction A: Convenience-store split purchase

```journal
2026-08-05 * Convenience store
    expenses:tobacco     600 JPY
    expenses:coffee      150 JPY
    assets:cash         -750 JPY
```

Required meaning:
* 一つの買い物
* 3 postings
* タバコと缶コーヒーを別科目で保持
* 支払元は現金
* transaction delta sumは0

### Transaction B: Supermarket food split

```journal
2026-08-06 * Supermarket food split
    expenses:food:daily    1400 JPY
    expenses:food:stock     900 JPY
    assets:bank           -2300 JPY
```

Required meaning:
* 一つのスーパー購入
* 3 postings
* 通常の食費とストック食費を区別
* 支払元は銀行口座
* transaction delta sumは0

### Transaction C: Supermarket mixed purchase

```journal
2026-08-07 * Supermarket mixed purchase
    expenses:food:daily    1400 JPY
    expenses:food:stock     900 JPY
    expenses:household      500 JPY
    assets:bank           -2800 JPY
```

Required meaning:
* 一つのスーパー購入
* 4 postings
* 通常食費、ストック食費、日用品を区別
* 支払元は銀行口座
* transaction delta sumは0

## Tax boundary

今回の全posting amountは、レシートに記載された税込金額として扱う。
- `expenses:tax` postingは作らない
- 8％と10％を別postingにしない
- 税抜価格を逆算しない
- 商品単位の税額配賦を行わない
- 税率別metadataを追加しない
- レシート合計と支払postingはそのまま一致させる
- category postingは税込category subtotalとする

税情報を保存する必要が後から確認された場合は、別の有限スライスでmetadataまたはreceipt evidenceとして検討する。
今回の税境界は、税を無視したという意味ではなく、税込支出へ内包したという意味である。

## Required characterization assertions

将来のfocused implementation testでは、最低限次を証明する契約にする。

### Stage 1
- `state = "ok"`
- diagnosticsは空
- transaction countは3
- posting countsは`3, 3, 4`
- transaction descriptionとposting orderを保持
- 各transactionのposting delta sumは0
- 3 transactionの`source_event_id`は互いに異なる
- explicit `event-id`なしでも各transaction blockが一つのeventとして保持される

### Read-only carrier and Stage 2A
- carrier resultは`state = "ok"`
- Stage 2A diagnosticsは空
- total Posting IR row countは10
- transaction orderを保持
- 各transaction内のposting orderを保持
- すべてのsuccessful Posting IR rowは既存の16-field shapeを維持
- `source_file`の既存境界を変更しない
- production loaderを使用しない

### Expected aggregate account deltas
各勘定科目の最終的な集計結果が以下のようになること：

```text
expenses:tobacco/JPY      600
expenses:coffee/JPY       150
expenses:food:daily/JPY  2800
expenses:food:stock/JPY  1800
expenses:household/JPY    500
assets:cash/JPY          -750
assets:bank/JPY         -5100
```

- 全account delta合計: `0`
- actual expense total: `5850`
- 支払元accountの合計: `-5850`

category totalsは、Transaction IRの説明文や店名から推論せず、Posting IRのresolved account coordinatesから計算する。

## Expected implementation scope

将来の実装候補を、次の最小範囲として記載する。

```text
fixtures/journal-split-purchase-characterization/profile.journal
fixtures/journal-split-purchase-characterization/accounts.tsv
tests/test_journal_split_purchase_transaction_characterization.bqn
```

既存のcarrier、Stage 1、Stage 2A、Cubeが契約を満たす場合、source codeは変更しない。
focused testは原則として次を再利用する：
- `journal_profile_stage1.Parse`
- `journal_read_only_source_carrier.Build`
- `journal_posting_ir_stage2a.Build`の既存経路
- 必要に応じて既存のCube materializationまたはlocal semantic-coordinate reduction

新しいproduction helperやsplit-purchase専用runtime moduleを追加しない。

## Success criteria

- 一つのtransaction blockが一つの生活上の購入eventとして保持される
- 一つのtransactionに3または4 postingsを保持できる
- 複数費用科目を別々のresolved account coordinatesとして保持できる
- 一つの支払postingが内訳合計と一致する
- 各transactionが個別に均衡する
- 3 transaction全体のaccount totalsが手計算と一致する
- 税込額のままカテゴリ分類できる
- production Journal routingは変更されない
- source truthはTSVのまま
- private dataを使用しない

## Non-goals

次を明確に除外する。
- production Journal loaderまたはrouting
- production editorまたはwriter
- 対話入力UI
- レシートOCR
- 商品明細の自動分類
- 店名からの科目推論
- tax posting
- 8％・10％税率の配賦
- 税抜価格の再構成
- tax metadata
- automatic account creation
- aliasesまたはfuzzy matching
- inventory accounting
- `assets:food-stock`への資産計上
- stock消費時の振替
- quantityまたはunit-price記録
- TSV-to-Journal conversion
- shadow read
- private-data comparison
- source-of-truth cutover
- `source_row` migration
- broader parserまたはregistry validation
- report formatter変更
- 次のJournal stageの自動選定

## Validation gate for the future implementation

```bash
bqn tests/test_journal_split_purchase_transaction_characterization.bqn
bqn tests/test_journal_native_three_posting_semantic_parity.bqn
bqn tests/test_journal_read_only_source_carrier.bqn
bqn tests/test_journal_resolved_account_registry_mismatch_rejection.bqn

bash checks/check-docs-lifecycle.sh
bash checks/check-absolute-links.sh
bash checks/check-repo-index.sh
git diff --check
bash tools/check.sh
```

## Completion routing

focused implementationとchecksが完了した場合:
- planを次へ移動する：
  `docs/archive/completed-plans/JOURNAL_SPLIT_PURCHASE_TRANSACTION_CHARACTERIZATION_PLAN-2026-07-22.md`
- exact fixture values、row counts、transaction identities、account totals、validation evidenceを記録する
- `TODO.md`、`NEXT_SESSION.md`、`docs/README.md`を更新する
- routingを`no finite slice selected`へ戻す
- production routing、writer、tax work、conversion、shadow read、cutoverを自動選定しない

## Completion Record (2026-07-22)

- **Status**: completed
- **Exact Fixture Paths**:
  - `fixtures/journal-split-purchase-characterization/profile.journal`
  - `fixtures/journal-split-purchase-characterization/accounts.tsv`
- **Exact Transactions**:
  - Transaction 1: 2026-08-05 * Convenience store (posting count: 3)
    - `expenses:tobacco` 600 JPY
    - `expenses:coffee` 150 JPY
    - `assets:cash` -750 JPY
  - Transaction 2: 2026-08-06 * Supermarket food split (posting count: 3)
    - `expenses:food:daily` 1400 JPY
    - `expenses:food:stock` 900 JPY
    - `assets:bank` -2300 JPY
  - Transaction 3: 2026-08-07 * Supermarket mixed purchase (posting count: 4)
    - `expenses:food:daily` 1400 JPY
    - `expenses:food:stock` 900 JPY
    - `expenses:household` 500 JPY
    - `assets:bank` -2800 JPY
- **Counts**:
  - Total Transaction IR count = 3
  - Total Posting IR row count = 10 (posting counts: `⟨3, 3, 4⟩`)
- **Identity Kind**: `physical_fallback`
- **3 Distinct Source Event Identities**: Confirmed that `source_event_id` is non-empty for all three transactions and they are mutually distinct by asserting that the event ID strings do not match each other.
- **Carrier Source Identity**: `"supplied-synthetic-split.journal"`. The carrier result retains this source identity, while the individual `posting_rows` keep their original `source_file` as `"profile.journal"`.
- **Transaction-Local Balance Results**: Verified that the sum of `delta` values for the postings of each individual transaction is exactly 0.
- **Exact Account Totals**:
  - `expenses:tobacco/JPY`: 600
  - `expenses:coffee/JPY`: 150
  - `expenses:food:daily/JPY`: 2800
  - `expenses:food:stock/JPY`: 1800
  - `expenses:household/JPY`: 500
  - `assets:cash/JPY`: -750
  - `assets:bank/JPY`: -5100
- **Category Metrics**:
  - Actual expense total: 5850
  - Payment account total: -5850
  - All-account delta sum: 0
- **Tax-Inclusive Boundary**: All amount values are treated as tax-inclusive category subtotals. No `expenses:tax` postings, 8%/10% tax rate splits, net price reconstruction, or tax metadata were introduced.
- **Numeric Reduction or Cube Boundary**: Materialized the 10 rows using `cube.Materialize` and verified that the actual account totals vector, valid count (10), skipped count (0), actual expense total (5850), and zero layer totals vector match expectations.
- **Focused Test Results**:
  - `tests/test_journal_split_purchase_transaction_characterization.bqn`: OK
- **Related Test Results**:
  - `tests/test_journal_native_three_posting_semantic_parity.bqn`: OK
  - `tests/test_journal_read_only_source_carrier.bqn`: OK
  - `tests/test_journal_resolved_account_registry_mismatch_rejection.bqn`: OK
- **Full check results**: Passed `tools/check.sh` and related checks.
- **Production Guard Rails**:
  - Production routing, writer, conversion, shadow read, and cutover have not been modified.
  - Source code (`src_next/**`) has not been modified.
  - Private data was not used or modified.
  - No next Journal slice was automatically selected.
