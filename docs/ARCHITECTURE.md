# アーキテクチャ (bqn-ledger)

Status: current architecture
Owner: architecture
Canonical: yes
Exit: revise when source or accounting boundaries change
Updated: 2026-07-26

## この文書の位置づけ

関連する文書:

- 長期ロードマップ: `docs/ENGINEERING_ROADMAP.md`
- 時間モデル: `docs/TIME_AS_AXIS.md`
- 記法・運用規約: `docs/CONVENTIONS.md`
- 保守手順: `docs/MAINTENANCE.md`
- purpose-specific projection方向: `docs/archive/active-plans/PURPOSE_SPECIFIC_PROJECTION_COMPOSITION_DIRECTION-2026-07-25.md`
- report context重複の現行観察: `docs/REPORT_CONTEXT_DUPLICATION_CHARACTERIZATION-2026-07-27.md`
- ledger factsを中心に全reportを移行し旧互換runtimeを削除するactive roadmap: `docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`
- 完了したreport prepared-boundary移行と削減記録: `docs/REPORT_CODE_REDUCTION_PLAN.md`
- `src_next` module topology: `docs/archive/audits/SRC_NEXT_MODULE_TOPOLOGY_AUDIT-2026-07-26.md`

この文書は、**データがシステム内をどう流れるか**、各モジュールが何を担当するかを説明します。

## 目的 / やらないこと

### 目的

- **正データは人間可読source** に置く。Actualは明示設定されたnative Journalだけ、plan/budget/accountsはTSVとする。
- **読み込み時に厳しく検査** する。typo や壊れた行は早めに失敗させる。
- **会計計算は配列中心** にする。BQN の強みであるベクトル・行列演算を使う。
- 日常操作の入口は **`tools/bl`（Command Hub）** とし、非対話のレポート入口は **`tools/report`** として保つ。
- 記録 → 検査 → 集計 → 表示の流れを毎日使えるようにする。
- checked posting factsから、Cube、TBDS、または具体的な問いに対応するpurpose-specific sparse resultを構成できるようにする。

### やらないこと

- core の中に「本格的な会計ソフト」や税制度判断を実装しない。
- Native Journal transactionをTSVの一対一行へ再flattenしない。
- 一つの巨大なuniversal Cubeや、証拠なしのgeneric query DSLを先に作らない。

## モノリス化の防止（旧 bqn-kakeibo の教訓）

旧エンジンにおいて、`BuildAt` が 100 フィールドを超える巨大な Record を構築し、各表示セクションがそれに深く依存した結果、変更困難なモノリス状態となりました。この再発を防ぐため、以下の設計原則を維持します。

1. **グローバルRecordへの安易なフィールド追加の禁止**
   - `BuildContext -> ViewModel -> Format` の流れを徹底し、各セクション内で独立した `ViewModel` を作る。
2. **「出力結果の同一性」のために内部構造を汚さない**
   - その場しのぎのパッチではなく、疎結合を最優先に設計する。
3. **言語境界の厳守**
   - BQN editor / Bash / UI 側に会計・生活ロジックを実装しない。旧 Go editor 関連コード・文書は historical として扱う。
4. **purpose-specific viewの独立性**
   - Cube、TBDS、direct sparse consumerを一つの万能resultへ潰さない。
   - 共有するのは、意味を失わないchecked facts、明示partition、exact groupingなど、複数の実consumerが証明した小さな材料に限る。
5. **flat stage flowとfirst-failure ownership**
   - 長いcompositionは、意味のあるstage名で一方向に読める形を優先する。
   - ただし一般的なpipeline frameworkへ先走らず、各stageのfailure code、diagnostics、no-partial-result契約を保つ。
6. **module directoryはownership evidenceから育てる**
   - `src_next`を一度に分類し直さず、direct-import graphとcaller evidenceから見えるcoherent neighborhoodを一群ずつ移す。
   - high fan-in hubやentrypointを最初の実験に使わず、移動ごとにimport target、focused test、full CI、current docsを同期する。
   - folder数ではなく、一覧から意味の区域が読めることを目的にする。

## 二大目的

### A. 生活を守る

- 次の収入日まで使い切らない（cycle）
- 封筒の残りを見る（budget/envelopes）
- 予定支出を見る（plan）
- 日々の安心を出す（毎日見られるサマリ）

### B. 確定申告の材料を残す

- 事業用/私用を分ける（`tax=business|private|mixed`）
- 必要経費候補を後で拾える粒度で残す
- 証憑と対応できる（`receipt=...`, `party=...`, `txn_id=...`）
- 年間集計を出せる

BQNは記録の背骨、専門ツールは申告の手先。背骨がまっすぐなら、手先はあとから選べます。

## システム共通の既定値

ファイルパスやデフォルトのベースディレクトリ名は `config/system_defaults.tsv` を正本として一元管理します。実運用データを公開 repo から外出しする場合は、`LEDGER_DATA_DIR` が `DEFAULT_BASE_DIR` より優先されます。

- BQN側: 呼び出し元 wrapper が base directory を渡す
- Bash側: `tools/lib/system-defaults.sh` 経由でロードし、`LEDGER_DATA_DIR` で上書き
- BQN editor側: wrapper (`tools/edit` / `tools/edit-bqn`) が解決した base directory を `src_edit/` に渡す
- Go側: historical code 用。現行 daily path の必須依存ではない

## 正データファイル

各ツールは base directory 配下のnative Journalとsource TSVを正データとして読む。公開 repo の `data/` は匿名 sandbox、実運用データは `LEDGER_DATA_DIR`（例: `/path/to/ledger-data/data`）で外出しする。実データの場所は移動可能であり、運用時は `tools/doctor` と `docs/DATA_DIR_SETUP.md` を入口に確認する。

- `<base>/accounts.tsv` — 勘定科目マスタ。1列目が科目名、2列目以降は `key=value` メタ。
- `<base>/<ACTUAL_JOURNAL_FILE>` — Actual layerの唯一の正本。native multi-postingを保持する。
- `<base>/plan.tsv` — 将来予定。Plan layer の正本。
- `<base>/budget_alloc.tsv` — 封筒予算配賦。Budget allocation の正本。
- `<base>/cycle.tsv` — サイクル期間設定。

### journal-like TSV の共通形式

先頭5列: `date memo from to amount`。6列目以降は `key=value` メタ。

## 中核概念

### 時間は軸である

```text
時間はラベルではなく、座標軸である。
```

- **座標時間**: Event を配置する時間座標（`date`）
- **観察時点**: レポートをどの時点から見るか（`as_of`）
- **外部時計**: OS から取得（`dt.Today`）。既定 `as_of` の供給元
- **期間ビュー**: cycle、月、週など、時間座標上の区間 view

`cycle` は Cube の基本軸ではなく、`[start, end_exclusive)` の区間 view。

### 動的勘定科目空間

勘定科目数は `accounts.tsv` から動的に決定される。`src_next/account_key.bqn` の `Resolve` が `count ← ≠accounts` を返し、cube や TBDS はこの値を使って配列を確保する。

旧エンジン時代の 256 スロット固定設計から移行済み。コード内にハードコードされた勘定科目上限は存在しない。

### Canonical Daily Cube

**`Day × Account × Layer`**

- `0: actual` — configで明示選択された単一Actual sourceから（Journal/TSVのmerge・fallbackなし）
- `1: plan` — `<base>/plan.tsv` から
- `2: budget` — `<base>/budget_alloc.tsv` と封筒消費から
- `3: forecast` — 予約レイヤ（現在ゼロ）

Cube は密な日付軸を使い、Ordinal 番号で $O(1)$ 参照可能。

### TBDS (Trial Balance Data Set)

`period × account × layer × opening/movement/closing`

Accounting-grade の試算表データセット。opening は期間開始前残高、movement は期間内変動、closing は opening + movement。

### Purpose-specific sparse projection

CubeやTBDSを経由せず、checked posting factsから具体的な問いへ直接作るviewも許されます。最初の実consumerは `src_next/queries/actual_expense_ranking.bqn` です。

```text
checked selected-domain posting facts
  + selected period
  + explicit expense AccountKey partition
  + Actual / debit admission
  -> exact sparse grouping
  -> amount-descending expense ranking
  -> contributor posting IDs
```

`src_next/queries/exact_sparse_grouping.bqn` は、明示されたkeysとalready-admitted exact valuesだけをgroupする小さなI/O-free kernelです。arithmetic domain、account role、期間、side、layerなどの意味はconsumer側が先に決めます。

`actual_expense_ranking.bqn`では、transaction-level `kind="expense"` を各postingのexpense分類として使いません。multi-posting expense transactionには `assets:prepaid` のような非expense debit coordinateも含み得るため、resolved account metadataから作ったexpense AccountKey partitionへのmembershipで選択します。

このconsumerは現在、public report sectionやproduction Cube/TBDS accumulationを置き換えていません。public synthetic fixtureとfocused testにより、selected-domain producer integration、TBDS expense relation parity、JPY/ILS scale、domain/scale fail-closed、deterministic ranking、contributor lookupをcharacterizeしています。

### Module topology

`src_next`は現在75個のBQN moduleを持ち、そのうち71個がroot直下、4個が`src_next/calc/`または`src_next/queries/`にあります。source-levelのdirect `•Import` graphには293 edgeがあり、欠損targetとimport cycleはありません。最初の低blast-radius migrationによりpurpose-specific query pairだけがnestedになり、production hubとentrypointはrootに残っています。

`tools/src-next-import-graph`がdirect import edge、module degree、cycle、欠損targetを機械的に観察します。詳細なpoint-in-time evidenceとmigration順序は`docs/archive/audits/SRC_NEXT_MODULE_TOPOLOGY_AUDIT-2026-07-26.md`にあります。

最初のdirectory migrationとして、production hubから切り離されたpurpose-specific query pairを移動しました。

```text
src_next/queries/
  actual_expense_ranking.bqn
  exact_sparse_grouping.bqn
```

この移動は二つを同時に実施し、root wrapperを残していません。focused tests、current contracts、import graph、full CIを新pathへ同期しました。完全なdirectory skeletonを先に作らず、各neighborhoodの意味が証拠で確かめられた時点で育てる方針は維持します。

## Dataflow

```text
<base>/accounts.tsv / selected actual source / <base>/plan.tsv / <base>/budget_alloc.tsv / <base>/cycle.tsv
   │
   └─ src_next/loader.bqn / actual_source.bqn (明示source読み込み)
        │
        ├─ src_next/context.bqn (full report / non-selected compatibility context)
        └─ src_next/selected_domain_context.bqn (JPY/ILS/USD共通の明示1通貨Actual + plan + budget)
             │
             ├─ checked selected-domain posting facts + resolved AccountKey metadata
             │    ├─ src_next/cube.bqn ──── Canonical Daily Cube (Day × Account × Layer)
             │    ├─ src_next/tbds.bqn ──── Trial Balance Data Set (opening/movement/closing)
             │    └─ expense AccountKey partition
             │         └─ src_next/queries/exact_sparse_grouping.bqn
             │              └─ src_next/queries/actual_expense_ranking.bqn (direct sparse consumer)
             │
             ├─ 各セクション Build(ctx) → ViewModel → Format / FormatHuman
             │
             └─ src_next/report.bqn ────── 人間向けレポート入口
                  src_next/summary.bqn ──── 機械向けコンパクト出力
```

現行productionと切り離したpure canonical proofが存在する。

```text
already-read Account + raw Actual -> snapshot.bqn -> Actual Facts
already-read Plan/Budget TSV + admitted Account
  -> companion_snapshot.bqn
  -> strict Plan Facts + Budget Facts
```

両rootは共通の`facts.bqn`からaligned Transaction/Posting FactsとSource/Domain/Account/Layer tablesを得る。Plan/Budgetはexplicit currency、Account currency一致、exact scaleを要求し、Planはdurable `plan_id`なしではadmitしない。どちらか一方のcompanion sourceがinvalidなら両方のfactsを空にする。空のoptional companion sourceは正常で、架空Domainを作らない。Source table/indexは最初のActual+Plan consumerであるincomeAnchor resolutionで導入し、source-qualified durable contributorを保持するが、巨大なmerged snapshotやcross-domain arithmeticは作らない。

新ledger ownerはsource path、I/O、clock、旧context、Cube/TBDS、report fieldを受け取らない。`config_admission.bqn`はledger source座標とreport policyを分離し、`cycle_admission.bqn`はfacts/as-ofを参照しないunresolved cycle definitionだけをadmitする。fixed/calendarMonth/incomeAnchorは必要 evidenceが異なるため3つのnarrow resolverに分け、共通`cycle_result.bqn` shapeへ返す。period resolutionをsource parserやuniversal cycle contextへ戻さない。Plan completionは`plan_completion_join.bqn`がexplicitに選択されたPlan/Actual Transaction indexをdurable `plan_id`だけでJoinする。各sourceのcurrency、exact coefficient/scale、Account direction、source-qualified Posting contributorを別々に保持し、複数Actualを加算しない。同一signatureの複数completionは`duplicate`、競合signatureは`ambiguous`であり、どちらも`completed`へ潰さない。period selection、temporal label、formatは後続use-case/section責務である。現行runtime/editor callerもcanonical Actual admission pathを直接importし、旧module pathはwrapperなしで削除済みである。schemaとinvariantは`docs/LEDGER_FACT_SCHEMA.md`、config/cycle境界は`docs/CONFIG_CYCLE_ADMISSION.md`を正とする。

`src/accounting/account_period.bqn`はexplicit Facts/domain/layer/start/end ordinalsからAccount別opening/movement/closingとcontributor Posting indicesを構築する。`date_category_flow.bqn`は同じFactsからstrict date × Account-metadata-derived categoryのsparse expense groupsとincome/netを構築し、`month_category_flow.bqn`はそのevidenceをmonth × categoryへrollupする。date/month両方で同一になったexplicit row-axis × bounded columnのexact groupingだけを`sparse_group.bqn`へ抽出し、`sparse_pivot.bqn`が同じsparse schemaをdense values/contributorsへmaterializeしてcanonical `matrix_result.bqn` constructorへ渡す。category classification、date/month axis、income/net、opening policy、label/sign/formatは統合していない。全capabilityはsection名を知らず、Cube/TBDSをimportしない。

最初の`src/sections/trial_balance.bqn` proofはdense Account-period stateをsparse化せず、section-localなopening/debit/credit/closing arraysからcanonical MatrixResultへcomposeし、同一resultをhuman/compactへrenderする。第二の`daily_flow.bqn` proofはgenuine sparse date/category expense Pivotへincome/netを加え、explicit latest-or-period-start observationとempty zero rowをsection-localに保つ。`planned_payments.bqn`はMatrixでないList resultのproofで、resolved cycle、explicit observation、Plan/Actual Factsからselection→completion Join→temporal state/exact totalをcomposeし、同一resultをhuman/compact/JSONへrenderする。複数rendererで一致したvisual width/paddingだけを`src/report/text.bqn`へ抽出し、accounting formulaを複製しない。

2026-07-28の`REPORT_PORTFOLIO_DECISION.md`により、destinationは旧15 section parityを要求しない。`REPORT_PORTFOLIO_CONTRACT.md`は`envelopes / balances / recent / planned / cycle-accounts / cycle-comparison / monthly-accounts / daily-target / issues`の静的catalog、axes/measures/time/currency/provenance、supported surfacesを選択する。`REPORT_SURFACE_RETIREMENT_MAP.md`は旧route/key/cache/metadata/query/checkを移行またはatomic削除へ割り当てる。

最初のretained P2実装は`account_balance.bqn`がActual Facts/domain/explicit observationからzeroを含む全Account closingとsource-qualified contributorsを導出し、`sections/account_balances.bqn`が一列MatrixResultをhuman/compact/JSONへ描画する。二つ目のdestination JSON consumer成立時にexplicit JSON text constructorsだけを`report/json_text.bqn`へ抽出した。P3 `recent_transactions.bqn`はActual末尾N Transactionをnewest-firstに選び、multi-posting lane arraysとexact total/provenanceを保持する。`sections/recent_journal.bqn`はarraysをrender時だけcomma joinし、human/tab-delimited compactへ描画する。二つのList rendererが一致した時点でplain table renderingを`report/text.bqn`へ追加した。

P4 `cycle_account_period.bqn`はalready-resolved cycleとexplicit observationからinclusive observationのend-exclusive ordinalを確定し、既存`account_period`をcomposeする。raw Posting indicesはこの境界でsource-qualified referenceへ変換される。`sections/cycle_accounts.bqn`はopening/debit/signed credit/movement/closingの五列Matrixをhuman-onlyで所有する。P5 `month_account_movement.bqn`はstrict month rangeを先にdense axis化し、empty month/zero Accountを含むsigned movementと両axis totalsを構築する。`sections/monthly_accounts.bqn`はmovementだけをhuman Matrixへ描画し、closing/YTDを混在させない。P6 `cycle_comparison.bqn`は2つのaccounted windowだけをexplicit policyで比較し、current/baseline coefficientとprovenanceをdifferenceから失わせない。Trial BalanceとDaily Flowは有用なcapability/proofとして残るが、旧routeを自動的に維持する根拠にはならない。production routingと旧surface削除はretained report proofsとsupported-source readiness後のatomic cutoverまで行わない。

### Selected-domain composition stages

`selected_domain_context.BuildFromPrepared`は、次の順序を持つflatなcompositionです。

```text
selected-currency policy
  -> complete Actual admission
  -> Actual currency-proof carriage
  -> selected non-Actual evidence/projection preparation
  -> combined context-scale selection
  -> exact Actual/non-Actual normalization
  -> Cube/TBDS period views
```

各stageは前段が成功した場合だけ実行されます。policy failureの後にsourceを検査したり、Actual admission failureの後にplan/budgetを処理したりしません。失敗時はそのstageのcodeとdiagnosticsを保持し、`posting_rows`と`actual_transactions`を空にして部分contextを返しません。

`PrepareNonActualRows`はplan/budgetのsource-evidence validation、selected-domain arithmetic proof、checked Posting IR projectionを所有します。`NormalizeSelectedRows`はActualとnon-Actualの二つのadmitted row集合を一つのcontext-local exact scaleへそろえることだけを所有します。これらはmodule内部のsemantic stageであり、generic pipeline frameworkや新しいpublic APIではありません。

`selected_domain_context.bqn` は complete-source admission と Stage 2A `currency_proof_rows` を再利用し、呼び出し側が明示したregistry-supportedな1通貨だけをcontext-local exact scaleへ射影する。JPY・ILS・USDはすべてこの同じ境界を通り、通貨literalによるcontext分岐は持たない。plan / budgetも同じ通貨をsource metadataとaccount currencyで証明し、証明失敗時は部分contextを返さない。declaration-only Journalや選択通貨Actualが0件のときも、validな選択plan / budgetからcontextを構成し、全source layerが空なら正常なempty contextを返す。これはCurrency axisや一般的な多通貨Cubeではなく、各呼び出しで1通貨だけを既存 `Day × Account × Layer` viewまたは同domainのpurpose-specific consumerへ渡す境界である。

default currency付きfull/cache reportは現在、通常section用の`context.BuildContext`に加えてbalances用selected-domain contextも構築する移行状態にある。両routeを巨大contextへ統合しない。両方のActual admissionはcanonical complete transactionsを使い、production cycle/contextにhistorical parser fallbackはない。ordinary contextだけが既存Cube/TBDS向け`delta` rowへ一時変換し、selected routeはexact currency-proof rowsを保持する。Journal list/reverseとbase-oriented completionはcanonical Facts由来のtyped transaction rowsを使う。focused legacy characterization contextのcompletion interpretationとoffline cleanup parserは明示的に隔離され、Phase 3/7で削除する。consumer固有のno-data、observation、cycle policyは引き続き各ownerに置く。

## Presentation boundary

BQN は terminal styling を出力しない。BQN の責務は、source TSV の検査、意味解釈、計算、plain text report、machine-readable export、semantic status word までである。

Report sectionの内部境界は一括framework化せず、適用可能なmoduleから`context/source adapter → I/O-free semantic VM → renderer`へ寄せる。`planned_payments.bqn`が最初の明示例で、compact pathはcycle/completionだけのprepared VM、human/JSON pathはtemporal attachment済みprepared VMを使う。`cycle_summary.bqn`もcontext adapterでdates/completionを準備し、I/O-free coreがTBDS interpretationとremaining-plan joinを行う。既存public entrypointはadapter wrapperとして維持し、rendererはcontextやbaseを読まない。

ただし境界分離そのものを完成条件にしない。新しいprepared seamにはcaller移行と削除候補を対応させ、移行後は不要なsource-loading wrapper、compatibility API、重複assembly、source-shape checkを縮小する。rendererを持たないconsumer helperへ形式的な三層構造を強制せず、短さのためにdiagnosticsや可読性を弱めない。`actual_snapshot.bqn`はrendererなしの例で、checked posting rows、既存Cube view、resolved metadata、明示as_ofだけを受けるI/O-free coreを持ち、Outlook移行後はbroad `BuildAt`とsource-loading latest-date APIを削除した。`daily_flow.bqn`もActual date取得をcontext adapterへ止め、prepared coreはCube/resolved/cycle/date evidenceだけを受ける一方、section固有の明示as_of row anchorは保持する。`daily_trend.bqn`ではActual coordinatesとchecked plan reserve resultをadapterで準備し、numeric coreはrow-local future-income replayとreserve計算結果を組み立てる。`BuildAt`の明示値は計算観察点ではなくhuman header coordinateという既存契約を変えない。`outlook.bqn`はconfig、next-obligation lines、Envelope、Actual Snapshot、remaining-planをadapterで準備し、section-specific prepared inputからarithmeticとVMを組み立てる。open-ended frontierとdefault/explicit absence policyは統合しない。Envelopeは一括分割せず、既にI/O-freeなbalance/unassigned/backing責務を維持し、dead source-loading APIとcallerのないexportから先に削る。execution planned coverageもlazy source/value adapterとprepared readonly comparisonを分け、disabled/missing-envelope時のsource非取得を保つ。Envelope固有のsource-order observationとinvalid-date挙動は他sectionのpolicyへ統合しない。このprepared-boundary削減trackは完了済み。次期ledger-facts engineへの移行順序、巨大all-report recordの再発防止、旧互換runtimeの最終削除条件は`docs/LEDGER_REPORT_ENGINE_MIGRATION_ROADMAP.md`を参照する。現行production behaviorはcutoverまで本書の記述を維持する。

BQN が出してよいもの:

- plain text report
- section key
- machine-readable summary
- `ok`, `warn`, `due`, `overdue`, `future`, `completed` などの意味語

BQN が出してはいけないもの:

- ANSI escape sequence
- terminal color code
- cursor control
- TTY 依存の表示制御
- fzf / gum など特定 UI ツール向けの装飾 markup

色、太字、枠、カード、preview、対話的な見せ方は presentation layer の責務である。現在の置き場は `tools/bl`、`tools/lib/color-filter`、`tools/main-ui.sh`、`tools/add-ui.sh` の表示補助とする。将来 viewer を追加する場合も、この境界を越えない。

TTYのsection selectorは、cacheがcoldまたはstaleでもreport計算を待たずに開く。生成中は古い金額を黙って表示せず明示的な更新中statusだけを表示する。`tools/command-hub-cache-refresh`はBQNが一度に生成したcanonical section cacheと`.section-keys` manifestをstagingし、manifest由来の各preview fileをatomic renameした後、最後にtimestampをpublishする。section identity/orderの正本は`src_next/report_sections.bqn`であり、UIとrefreshはsection名の配列を重複保持しない。default currencyを宣言したledgerでは、human `balances`のdirect / full / cacheが同じselected-domain section bodyを使い、shellによる差し替えは行わない。highlight時の`tools/command-hub-preview`はmanifest/file/statusだけを読み、report engineを起動しない。非対話呼び出しはdeterministicな同期refreshを維持する。

この境界の詳細は `docs/archive/active-plans/DECISION_TERMINAL_COLOR_CONFIG.md` に置く。

Shell は UI・選択・wrapper・safe-write orchestration だけを担当する。actual Journal / `accounts.tsv` / `plan.tsv` / `budget_alloc.tsv` の会計意味や生活ルールは shell に持たせず、source route・候補・検査結果は BQN export / BQN editor protocol / config 由来のものを使う。

```text
BQN: meaning, calculation, plain output
UI: color, layout, interaction
```

### Layer model

```text
Source evidence
  → checked posting facts
  ├─ Canonical Daily Cube
  ├─ TBDS(period, as_of)
  └─ purpose-specific sparse projections
       → consumer-specific validation / report / export

Accounting reports
  → household policy layer
  → household views
```

Accounting core は生活ルールを知らない。年金・月給・封筒派などの生活スタイルは policy layer で扱う。
