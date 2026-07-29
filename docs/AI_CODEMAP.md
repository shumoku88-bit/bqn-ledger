# AI_CODEMAP: pit向けコード地図

Status: current operational guide
Owner: docs
Canonical: yes
Exit: keep current while this remains the pit code/data-flow entry point
Updated: 2026-07-28

この文書は、pit（AI作業相棒）が `bqn-ledger` を触る前に読むための地図です。
人間が読む場合も、コードの入口・データフロー・どのファイルが正本かを短時間で確認するための索引として使えます。外部向けの最初の入口は `docs/README.md` と `CONTRIBUTING.md` です。

## まず読む順番

1. `docs/AI_CODEMAP.md`（このファイル）
2. `TODO.md`（現在進行中・次に着手する作業だけ）
3. `docs/QUALITY_BAR.md`（品質基準）
4. `docs/SRC_NEXT_CURRENT.md`（`src_next` が現在の普段使い report engine であること、旧 migration docs の扱い）
5. `docs/DEVELOPER_INSPECTION_ENTRYPOINT.md`（低層診断入口と `main.bqn` 互換wrapper）
6. `docs/ARCHITECTURE.md`（データフロー・モジュール責務）
7. `docs/CANONICAL_DAILY_CUBE.md`（固定するDaily Cube契約）
8. `docs/TIME_AS_AXIS.md`（時間座標・観察時点・区間view）
9. `src_next`のfile moveなら `docs/archive/audits/SRC_NEXT_MODULE_TOPOLOGY_AUDIT-2026-07-26.md` と `tools/src-next-import-graph`
10. projection変更なら `docs/archive/active-plans/PURPOSE_SPECIFIC_PROJECTION_COMPOSITION_DIRECTION-2026-07-25.md`、`docs/archive/audits/PROJECTION_BQN_OWNERSHIP_AUDIT-2026-07-26.md`、該当する `src_next/*` consumer
11. レポート変更なら`docs/REPORT_PORTFOLIO_DECISION.md`、`docs/REPORT_PORTFOLIO_CONTRACT.md`、`docs/REPORT_SURFACE_RETIREMENT_MAP.md`、active roadmap、`docs/LEDGER_FACT_SCHEMA.md`を先に読む。旧15 sectionはcurrent inventoryでありdestination requirementではない。現行production behaviorは `src_next/report.bqn` と current contractsで確認する
12. エディタ作業なら `docs/PRODUCTION_EDITOR_DIRECTION.md` / `docs/BQN_EDITOR_USAGE.md` / `src_edit/README.md`
13. 複数ポスティング導入検討なら `docs/archive/completed-plans/DECISION_MULTI_POSTING_INVESTIGATION.md`
14. 変更内容に応じて `docs/CONVENTIONS.md` / `docs/JOURNAL_META.md` / `docs/MAINTENANCE.md`
15. 履歴・背景（非アクティブな計画書、旧エンジン移行期資料、完了済みの計画書など）が必要な場合のみ `docs/archive/` を読む
16. AIによる家計相談計算の設計なら `docs/archive/active-plans/AI_BUDGET_CALCULATOR_DESIGN.md`

`docs/archive/completed-plans/REPORT_FIELD_MAP.md` と `docs/archive/completed-plans/MAIN_SECTIONS.md` は旧エンジンの historical / superseded docs です。現行レポート変更の正本導線としては読まず、旧 `main.bqn` / `report_engine.Build` の履歴確認が必要な場合だけ参照します。

`docs/archive/src-next-migration/` も移行期の履歴です。現在の入口は `docs/SRC_NEXT_CURRENT.md` と `tools/report` を正とし、archive 内の「production default is bqn main.bqn」「Stage 4b 未開始」などの記述を現行仕様として扱わないでください。

## 絶対に守ること

- Actual source は `<base>/config.tsv` の `ACTUAL_JOURNAL_FILE` で指定するnative Journalだけである。TSV actual route・fallback・dual writeはない。`plan.tsv` / `budget_alloc.tsv` / `accounts.tsv` は引き続き正データ。公開 repo の `data/` は匿名 sandbox、実運用は `LEDGER_DATA_DIR` で外出しする。
- pit は実データ TSV を勝手に書き換えない。必要ならユーザー確認を取る。
- journal-like TSV の先頭5列は固定: `date memo from to amount`。
- 6列目以降は `key=value` メタ。会計計算は原則として先頭5列だけを見る。
- 大改造しない。1段階・1目的・小さい差分で進める。
- TODOを進める際は、まず `TODO.md` と該当する active plan を参照する。
- 大きめの相談が来たら、通常TODO/active planを進める話か、BQN editor トラックか、先にmokoへ確認する。
- transaction-level `kind` とposting-level AccountKey partitionを混同しない。multi-posting transactionでは一つのtransaction kindの中に異なるaccount coordinateが共存する。
- flatなstage列へ整理するときも、first-failure ownership、diagnostic code、no-partial-resultを変えない。後段stageは前段成功時だけ実行する。
- `src_next/developer_inspection.bqn` が低層diagnostic implementationのownerである。`src_next/main.bqn`は一時的な互換wrapperに限定し、実装を戻さない。productionは `tools/report` → `src_next/report.bqn` の境界を保つ。
- `src_next`のdirectory移動は、`tools/src-next-import-graph --validate`とrepository-wide caller searchを先に行い、一つのcoherent neighborhoodだけを動かす。high fan-in hubやentrypointを最初の実験にせず、空のdirectory skeletonを先に作らない。

## 作業完了ゲート

実装や調査の作業は、codeだけがmergeされた時点では完了としない。関連する範囲について次を同じ作業単位で閉じる。

1. focused testと必要なintegration evidenceを追加する。
2. `tools/check.sh`、`tools/coverage`、差分検査、GitHub Actionsを成功させる。
3. `TODO.md`、`docs/ARCHITECTURE.md`、このcode mapを現在地へ同期する。
4. 関連するcurrent contract、active plan、README/docs indexへの影響を確認し、必要な文書を同期する。
5. 実施前の表現、旧module名、古い次工程、誤ったownership説明が残っていないかrepository検索する。
6. PR descriptionとfinal head SHAを同期する。
7. Ready化・merge後にmain SHAとmain上のファイルを確認する。

変更対象が大きくdocs-only follow-upへ分ける場合も、そのfollow-upのmergeまでを同じ作業単位として扱う。

## 全体像

```text
<base>/accounts.tsv / <base>/<ACTUAL_JOURNAL_FILE> / <base>/plan.tsv / <base>/budget_alloc.tsv / <base>/cycle.tsv / <base>/issues.tsv
   │
   ├─ src_next/loader.bqn / actual_source.bqn (明示source読み込み)
   │    │
   │    ├─ src_next/context.bqn / selected_domain_context.bqn
   │    │    │
   │    │    ├─ checked posting facts
   │    │    │    ├─ src_next/cube.bqn (Canonical Daily Cube: Day × Account × Layer)
   │    │    │    ├─ src_next/tbds.bqn (Trial Balance Data Set: opening/movement/closing)
   │    │    │    └─ explicit semantic partition + src_next/queries/exact_sparse_grouping.bqn
   │    │    │         └─ src_next/queries/actual_expense_ranking.bqn (first direct sparse consumer)
   │    │    │
   │    │    └─ src_next/report.bqn (人間向けproduction report)
   │    │         ├─ src_next/issues.bqn (Issues & Decisions 表示)
   │    │         └─ src_next/summary.bqn (機械向けコンパクト出力)
   │    │
   │    └─ src_next/developer_inspection.bqn (developer inspection implementation)
   │         └─ src_next/main.bqn (temporary compatibility wrapper)
```

`src_next/queries/actual_expense_ranking.bqn`は現時点でpublic report sectionへ配線されていない。checked selected-domain posting factsを使うpurpose-specific consumerとして、public synthetic fixtureとfocused testでcharacterizeされている。

現在の`src_next`は71 BQN module中67 moduleがroot直下、4 moduleがnestedで、direct importは277（internal 263）、欠損target 0、cycle 0です。exact decimal、currency registry、complete/single-domain Journal admissionは全callerと`src/ledger`へ移動し、旧path wrapperはありません。移動前のpoint-in-time evidenceは`docs/PHASE0_REPORT_ENGINE_CHARACTERIZATION.md`と`docs/archive/audits/SRC_NEXT_MODULE_TOPOLOGY_AUDIT-2026-07-26.md`に保持します。

## 正データファイル

各ツールは `LEDGER_DATA_DIR`、未設定なら `config/system_defaults.tsv` の `DEFAULT_BASE_DIR` を base directory として読む。公開 repo の `data/` は sandbox fixture として扱う。実データの場所を確認する入口は `docs/DATA_DIR_SETUP.md` と `tools/doctor`。

- `config/meta_schema.tsv` — メタデータキーの定義
- `config/report_labels.tsv` — src_next report の表示ラベル定義。
- `<base>/accounts.tsv` — 勘定科目マスタ
- `<base>/<ACTUAL_JOURNAL_FILE>` — 実績取引の唯一の正本。native transaction block / multi-posting
- `<base>/plan.tsv` — 未来予定
- `<base>/budget_alloc.tsv` — 封筒/予算の手動配賦
- `<base>/cycle.tsv` — サイクル期間設定
- `<base>/issues.tsv` — Issues & Decisions ログ

## コード地図

### `src/ledger/` (移行中のcanonical ledger facts)

- `facts.bqn` — successful canonical Actual/companion admissionとstrict aligned Account tableを受け、aligned Transaction/Posting factsとSource/Domain/Account/Layer tableへall-or-nothing projectionするread-only owner。全Factはexplicit source_indexを持ち、transactionがあればDomain必須だけをgenericに検査する。
- `date_ordinal.bqn` — fact date用のstrict ISO Gregorian validation/ordinalだけを持つpure coordinate owner。clockや表示を持たない。
- `exact_decimal.bqn` — source amount textのexact parse、canonical coefficient/scale、exact-range diagnosticsを所有するpure kernel。全runtime/editor/test callerを同時移動し、旧path wrapperはない。
- `currency_registry.bqn` — repository currency policy行をI/Oなしで検査し、Policy/IsSupportedCurrencyを返すpure owner。旧path wrapperはない。
- `account_admission.bqn` — accounts.tsv行とregistryだけを受け、explicit currency、unique key/metadata、known metadata、unclassified roleをall-or-nothingのaligned Account tableへadmitする。
- `journal_transaction_structure.bqn` — complete admissionがdomain-normalizeした1 transaction partitionのheader、metadata、declared account、posting side/zero-sum、identity、source lineをall-or-nothingでadmitするpure owner。旧`historical_external_plan` profileをimportしない。
- `journal_single_domain_admission.bqn` — 1 transaction domainのexact decimal、registry precision、Account currency、balance、normalized structureをadmitする。
- `journal_complete_admission.bqn` — declaration-onlyを含むraw Journal全体をdomain partitionし、各ordinary transactionをsingle-domain ownerへ渡してcomplete no-partial transaction evidenceを返す。
- `snapshot.bqn` — already-read account lines、raw Journal、registryをstrict Account→complete Journal→factsへcomposeするpure bounded root。
- `companion_admission.bqn` — already-read Plan/Budget TSVの固定5座標、closed metadata、strict date、positive exact amount、explicit currency、Account currency、durable Plan IDをsource policyごとにall-or-nothing admissionする。
- `companion_snapshot.bqn` — Plan/Budget両admissionをcommon factsへcomposeし、一方でもinvalidなら両source factsをpublishしないpure bounded root。
- `config_admission.bqn` — already-read config行をclosed/unique key、mandatory registry-supported `DEFAULT_CURRENCY`、typed source座標とreport policyへall-or-nothing admissionする。repository defaultやpath I/Oを持たない。
- `cycle_admission.bqn` — fixed/incomeAnchor/calendarMonthのalready-read定義をstrict date/range/day、explicit income Account roleへall-or-nothing admissionする。facts/as-of/clockからのperiod resolutionを持たない。
- `transaction_rows.bqn` — canonical factsからsource-order Transactionとordered Postingをtyped joinするJournal list/reverse/Recent向けnarrow capability。source loadやreport formattingを持たない。
- `issue_admission.bqn` — non-accounting `issues.tsv`のstrict eight-column admission。durable identity、status、optional date/amount+currency、source row/refをall-or-nothingで保持し、Transaction/Posting Factsへ混入させない。
- `amount_text.bqn` — exact coefficient/scaleをroundingなしでplain decimal textへ変換するpure capability。
- `exact_scale.bqn` — admitted signed coefficientをselected scaleへdecimal text経由でexact normalizationし、checked sumするpure arithmetic owner。
- 現行production routingはまだ`src_next`だが、runtime/editorのcomplete admission callerは`src/ledger`を直接importする。`src/ledger`から`src_next`をimportしてはならない。

### `src/accounting/` (canonical facts上のpure accounting capabilities)

- `account_balance.bqn` — Actual Facts/domain/explicit observationから全Account（zero含む）のexact closingとsource-qualified Posting contributorsを導出する retained Balances capability。mixed/unknown domainやoverflowはpartial tableを返さない。
- `account_period.bqn` — explicit Facts/domain/layer/start/endだけを受け、Account-orderのopening/debit/credit/movement/closing、exact totals、contributor Posting indicesを返す。Cube/TBDS、context、section、format、clockを持たない。
- `cycle_result.bqn` — fixed/calendarMonth/incomeAnchor resolverが共有するok/unavailable/error period shape。unavailable/errorはdate/ordinal/day_countを空にし、sentinelやzeroへ潰さない。
- `cycle_fixed_resolution.bqn` — admitted fixed definitionだけを解決し、不要なobservation/Factsを受けない。
- `cycle_calendar_month_resolution.bqn` — admitted start_dayとexplicit as-ofだけからmonth-safe half-open periodを解決する。
- `cycle_income_anchor_resolution.bqn` — explicit as-of、Actual Facts、Plan Facts、income Account evidenceからanchor periodとsource-qualified durable contributorsを解決する。I/O、clock、cross-source amount加算を持たない。
- `fact_reference.bqn` — 2つのcross-source consumerで一致したSource validationとdurable Transaction/Posting reference構築だけを共有する。
- `plan_completion_join.bqn` — explicitに選択済みのPlan/Actual Transaction Factsをdurable `plan_id`だけでJoinする。各sourceのexact amount、Account direction、Posting contributorを保持し、open/completed/duplicate/ambiguousを区別する。five-field fallbackやduplicate amount加算を持たない。
- `recent_transactions.bqn` — Actual Factsとpositive limitからphysical source末尾N件をnewest-firstに選び、multi-posting debit/credit arrays、exact debit total、Transaction/Posting provenanceを返す retained List capability。
- `cycle_account_period.bqn` — resolved cycle、explicit observation、Actual Factsを`account_period`へcomposeし、observed end-exclusiveを確定する。全cell contributorをsource-qualified Posting referenceへ変換し、cycle boundary evidenceを別保持する。
- `cycle_comparison.bqn` — 2つのexplicit accounted cycle windowsを`aligned_elapsed | complete_cycles`で比較し、current/baseline/differenceとwindow別・union provenanceを返す。similar period探索を持たない。
- `envelope_backing.bqn` — strict Budget/Actual/Plan、horizon/observation、explicit funding scopeからEnvelope termsと別証拠系のbacking/reconciliationを構築する。named stages、durable completion、exact fail-closed、source-qualified provenanceを所有する。
- `daily_target.bqn` — explicit observation/target、owner-resolved account-balance assets、open obligations、per-obligation reservationからexact capacity/target/shortfallを計算する。future incomeやaggregate reservation inferenceを入力に持たない。
- `month_account_movement.bqn` — strict `[first_month,last_month_exclusive)`とActual Factsからempty month/zero Accountを含むdense Month × Account signed movementを構築し、両axis totalsをexact reconciliationする。
- `date_category_flow.bqn` — strict date period内のexplicit income/expense Account postingsを、Account metadata由来dynamic envelope categoryと`other`へsparse groupingする。date income/net、exact scale、contributor Posting indicesを返し、prefix inferenceやDaily Flow section fieldを持たない。
- `month_category_flow.bqn` — presentation-neutral date/category evidenceをcalendar month × categoryへrollupし、exact scaleと元Posting contributorsを保持するextensibility proof。
- `sparse_group.bqn` — date/month両consumerで同一と証明されたexplicit row axis × bounded columnのdeterministic sparse Group。exact sum、zero-sum contributor保持、all-or-nothing diagnosticsだけを所有し、date/month/category policyを持たない。
- `matrix_result.bqn` — opaque row/column coordinates、exact scale、dense values/contributorsを検査して唯一のpresentation-neutral MatrixResult shapeを構築する。dense consumerは直接使う。
- `sparse_pivot.bqn` — shared sparse Groupをzero/contributor semantics付きdense arraysへmaterializeし、`matrix_result.bqn`へ委譲するpolicy-free Pivot。Matrix shapeを重複所有せず、label/sign/format/totalsを持たない。

### `src/sections/` (destination section-local result/render owners)

- `trial_balance.bqn` — successful Account-period resultのdense values/contributorsをcanonical MatrixResult constructorへ直接渡し、同じresultをhuman/compactへrenderする最初のvertical proof。不要なsparse往復、会計formula、source I/O、context、Cube/TBDS、JSONを持たず、production routingにはまだ未接続。
- `daily_flow.bqn` — date/category accounting evidenceのgenuine sparse expense Pivotとincome/netを一つのMatrixResultへcomposeする第二proof。explicit latest-or-period-start observation、empty zero row、derived net contributors、human-only contractを所有し、clock/compact/JSONを持たない。
- `planned_payments.bqn` — resolved cycleとexplicit observationからPlan/Actual selection、durable completion Join、temporal state、single-domain exact open totalをcomposeするdestination List section。同じresultからhuman/compact/JSONを描画し、duplicate/ambiguous completionを拒否する。
- `account_balances.bqn` — retained `balances` one-column Matrix/List result。explicit date/ordinal一致を検査し、全Accountをhuman/`ledger_balance` compact/JSONへ同一resultから描画する。
- `recent_journal.bqn` — retained `recent` List result。Account lane arraysをsemantic resultで維持し、human tableとtab-delimited `ledger_recent_journal` compactだけを描画する。
- `cycle_accounts.bqn` — retained `cycle-accounts` Account × opening/debit/signed credit/movement/closing Matrix。human-onlyで、compact/JSONや旧Trial Balance routeを所有しない。
- `cycle_comparison.bqn` — retained `cycle-comparison` Account × current/baseline/difference Matrix。human-onlyで、ratio/status laneを所有しない。
- `envelope_backing.bqn` — retained `envelopes` bounded Statement。同一resultからhuman、`ledger_envelope*` compact、exact-number JSONを描画し、Budget claimとfunding evidenceを別table/coordinateとして表示する。
- `daily_target.bqn` — retained `daily-target` evidence-bearing Card/Projection。asset/obligation/calculationをhuman表示し、`ledger_daily_target_*` compactを描画する。JSONはunsupported。
- `issues.bqn` — retained `issues` source-order open List。human-onlyで、sentinel date/zero amount、accounting obligation化、editor report-text parsingを持たない。
- `monthly_accounts.bqn` — retained `monthly-accounts` Month × Account movement Matrix。human-onlyで、month-end balance、YTD、role summaryを混在させない。

### `src/report/` (destination report-level presentation/composition primitives)

- `text.bqn` — 複数Matrix/List rendererで一致したvisual width、padding、既format済みcellのplain deterministic tableだけを所有する。accounting、section label、color、terminal stateを持たない。
- `json_text.bqn` — Planned PaymentsとAccount Balancesの2 consumerで一致したexplicit JSON String/ExactNumber/Boolean/Pair/Array/Object text constructor。arbitrary value coercionやbinary-float変換を持たない。
- `catalog.bqn` — source-independentなfinal nine-key catalog。key/order/label/shape/supported surfacesの唯一のdestination owner。
- `request.bqn` — final key/surfaceと`all` selectorをpure admissionし、legacy keyやunsupported surfaceを明示errorにする。aliasを持たない。
- `catalog_text.bqn` — household sourceを読まずcatalog metadataをdeterministic TSVへ描画する。

### `src_next/` (現行production BQN 会計エンジン)

- `context.bqn` — BuildAllRows / BuildPeriodView / BuildContext。Actualはcanonical complete admissionを使い、既存Cube/TBDS向けに一時的な`delta` rowへ変換してplan/budget TSV rowsと合成する。default/explicit cycle解決も同じcomplete transactionsを再利用し、production historical parser fallbackはない。
- `journal_profile_stage1.bqn` — Minimal BQN Journal subsetをordered Transaction IRへ変換するparser。`recur` / `series` / `trip-id`とclosed enumの`payment`は会計意味を解釈せずgeneric `transaction.metadata`へexact保持する。Journal modeのproduction read/write validationで使用する。
- `journal_posting_ir_stage2a.bqn` — admitted Stage 1 Transaction IRをcurrent 16-field Posting IR shapeへ変換するadapter。explicit source file identityを持つnative multi-posting production routingにも使用する。
- `journal_posting_identity_provenance_stage2b.bqn` — admitted Stage 1 Transaction IRと対応するStage 2Aの16-field rowsを受け、identity/provenance local invariantsをall-or-nothingで検査して、rowを変更せず別の6-field carrierを返すpure test-only helper。production provenance carrier、consumer、routingには未接続。
- `currency_arithmetic.bqn` — pre-built B1 row evidence だけを入力に、single-domain 検査、snapshot-wide `amount_scale`、exact normalization、normalized overflow evidence を返す pure B2 owner。source file や projection は扱わない。
- `source_currency_admission.bqn` — supplied account lines と posting snapshot のみを検査する pure source-currency admission owner。closed strict/compatibility policy、privacy-safe diagnostics、no-partial-admission を持ち、I/Oなし・public runtime未配線。
- `friend_travel_jpy_finalization.bqn` — pending friend-travel source-event descriptor、明示 finalization date / JPY amount、既存account descriptor、既存finalization IDだけを入力にするpure validator。成功時は既存JPY liability → JPY expenseのcanonical previewを正確に1行返し、失敗時はprivacy-safe diagnosticsと0行を返す。I/O、status/index mutation、writer、public runtime配線は持たない。
- `friend_travel_source_event.bqn` — Israel用friend-paid pending source eventの固定9列、ILS精度、固定payer/trip/status、既存全行検査、ID一意性、exact preview rowを所有するpure validator。I/Oとfinalizationを持たない。
- `travel_exchange_event.bqn` — Israel用JPY↔ILS bidirectional exchangeの2観測amount、明示source/target currencyごとのprecision、既存account descriptor、ID一意性を検査しstructured previewを返すpure owner。I/O、rate、journal row、valuation、account-name inferenceを持たない。
- `actual_observation.bqn` — prepared Actual datesからreport-local observation coordinateを導くI/O-free policy owner。Daily Flow/Trendの`start + day_count` windowと、Planned Payments/Cycle Summaryのexplicit half-open cycle windowという、consumer間でexact parityが確認された2 policyだけを共有する。invalid-date filtering、source-order、explicit absence、open-ended frontierは統合しない。
- `actual_source.bqn` — configured native Journal resolverとtransitional source-loading adapter。`LoadTransactionRows`とbase-oriented completionはcanonical complete admission→Facts→typed transaction rowsを使う。production `LoadCycleEvidence`はcanonical complete admissionでfail-closedし、historical parser fallbackを持たない。focused legacy contextsだけは明示`actual_transactions_complete`不在時の旧completion interpretationを保持し、Phase 3で削除する。declaration-only Journalは正常なempty Actualとしてadmitされる。
- `loader.bqn` — source ファイル読み込み (`•FChars` 使用)。
- `cube.bqn` — Canonical Daily Cube (`Day × Account × Layer`) の構築。
- `tbds.bqn` — Trial Balance Data Set (period/account/layer/opening/movement/closing)。
- `exact_sparse_grouping.bqn` — explicit keysとalready-admitted exact valuesをfirst-occurrence順でdeterministicにgroupするI/O-free kernel。accounting axes、domain、admission、valuation、provenance ownershipを持たず、contributor indexはsidecar helperで返す。
- `actual_expense_ranking.bqn` — checked selected-domain posting factsから、Actual / selected period / debit / explicit expense AccountKey partitionを選び、exact grouping、zero-net visibility、amount-descending ranking、contributor posting IDsを返す最初のdirect sparse consumer。Cube/TBDSをimportせず、public report wiringはまだ持たない。
- `trial_balance.bqn` — 試算表エクスポート。debit/credit 符号付き。
- `cycle.bqn` — サイクル期間の解決。compatibility `ReadCycle`は単独caller向けsource-loading adapterとして残る。`ReadCycleFromActualEvidence` / `At`はBuildContextのcomplete-or-fallback evidenceを、`ReadCycleFromAdmittedTransactions`はselected adapterのcomplete evidenceを使い、Journalを再読込しない。cycle definition、latest-Actual/no-Actual observation、income account、plan evidence、period constructionはこのmoduleが所有する。
- `account_key.bqn` — 勘定科目のキー解決。
- `projection.bqn` — non-Actual TSV routeのPosting IR construction vocabularyと、現行のLayer / day-coordinate / arithmetic-proof compatibility seamsを共有する。P1後はprojection column list、table formatting、source-balance presentationを所有・exportしない。
- `developer_inspection.bqn` — 非productionの低層診断実装。AccountKey、checked Posting IR table、source-balance表示、Cube sanity、policy diagnosticを出し、直接実行と互換wrapperからの`Run`呼出しの両方を支える。
- `main.bqn` — `developer_inspection.bqn`をimportし、引数を`Run`へ渡すだけの一時的な互換wrapper。診断実装やproduction ownershipを持たない。
- `snapshot.bqn` — Balance Sheet / Snapshot。TBDS closing を使用。構造化された ViewModel JSON 出力（FormatJson）もサポート。
- `selected_domain_context.bqn` — 明示されたregistry-supportedな1通貨を、policy → complete Actual admission → Actual currency-proof carriage → non-Actual evidence/projection preparation → context-scale selection → exact normalization → Cube/TBDS period viewsのflatなstage列で構成する。production source adapterはpreliminary complete admissionをcycleと内部`BuildFromPreparedCore`へ再利用し、date/income evidenceや後続compositionのためにJournalを再admitしない。public `BuildFromPrepared`はpolicy-first admissionとfocused first-failure契約を維持する。`PrepareNonActualRows`と`NormalizeSelectedRows`はmodule内部のsemantic stageで、public exportは増やさない。各stageは前段成功時だけ実行し、failure code/diagnosticsを保持して部分contextを返さない。成功時はchecked posting rows、resolved metadata、Cube/TBDS viewを返し、同domainのposting rowsをdirect sparse projectionへ渡せる。Currency axis、FX、valuationは扱わない。
- `balances.bqn` — 残高表示。human `--section balances --currency CODE`は常にselected-domain contextを使い、対象通貨のaccount残高と累計expenseを全supported currencyで同じsection構造により表示する。default currencyを宣言したledgerではfull/cacheも同じselected-domain bodyを使う。数値書式だけcurrency policyに従い、既存JSON契約は維持する。
- `ytd_summary.bqn` — YTD 集計。
- `cycle_summary.bqn` — サイクル収支。context adapterがprepared Actual dates、plan completion evidence、section inputを揃え、I/O-free `BuildFromPrepared`がTBDS interpretation、remaining-plan join、result VMを所有する。Format / FormatHumanはVMだけを描画する。
- `expense_breakdown.bqn` — サイクル支出内訳。
- `envelope_computation.bqn` — 封筒予算計算。封筒balance/pace、unassigned pool、TBDS backing、execution planned coverage、orchestration、rendererを一ファイルに持つが、一括分割しない。balance/unassigned/backingとexecution comparisonはI/O-free内部責務で、source-order observation policyはsection local。execution adapterはdisabled/missing時にplan sourceを読まないまま、active時だけ`plan_rows.WithValues`を準備する。source-loading tuple/latest-date API、callerのないexports、重複allocation read/calculationは削除済み。
- `planned_payments.bqn` — current-cycle予定支払いsection。context adapterはprepared datesと`plan_rows` evidenceを取得し、I/O-free `BuildViewModelFromPrepared`へ渡す。compactとhuman/JSONは別prepared VMを持ち、pure rendererの外側に既存context entrypointを残す。
- `recent_journal.bqn` — 最近の仕訳表示。
- `readiness_check.bqn` — データ品質チェック。
- `outlook.bqn` — 見通し・日割り計算。adapterがconfig、plan-line next obligations、Envelope summary、Actual Snapshot、remaining-plan、open-ended frontierを準備し、I/O-free `BuildFromPrepared`がOutlook arithmeticとVM assemblyを所有する。default/explicit absence semanticsは分けたまま。frontier policyはprepared dates APIを公開し、source-loading compatibility helperは持たない。
- `daily_capacity.bqn` — 明示された観察日、cycle horizon、単一算術domain、owner-resolved asset / obligation evidenceだけを受ける純粋Daily Capacity計算seam。Outlook compatibility arithmeticとはasset/obligation/reservation契約が異なるため、独立experimentとして保持し、config・source adapter・出力には未接続。
- `daily_flow.bqn` — 日別income/envelope/other/net。context adapterがActual datesを取得し、I/O-free `BuildFromPrepared`は既存Cube view、resolved metadata、cycle、prepared datesだけからVMを作る。Daily Flow固有の明示as_of row anchorを維持する。
- `daily_trend.bqn` — 日次トレンド。context adapterがActual dates、row coordinates、checked plan reserve resultを準備し、I/O-free `BuildFromPrepared`は既存Cube/resolved/cycle、明示coordinates、plan resultだけからVMを作る。current-source coordinate replayとempty cycle-start anchorを維持する。`BuildAt`の引数は計算Oではなくhuman header coordinateである。
- `daily_trend_plan.bqn` — admitted `plan.tsv` Posting IRを`source_row`でplan ID/completion source evidenceへjoinし、D-local fixed reserveを計算するnumeric owner。raw amountは再解析しない。
- `actual_comparison.bqn` — 明示Observation `BuildAt ⟨ctx,O⟩`で前期比較を作る。current/baseline金額はchecked Posting IRからlocal TBDS period viewへ流し、count/anchor/rejected-row診断はposting source identity evidenceを使う。statusは`ok / unavailable / error`。
- `actual_snapshot.bqn` — as_of時点のledger-cumulative Actual snapshot。`BuildFromPrepared`はchecked posting rows、既存Cube view、resolved metadata、明示as_ofだけを受けるI/O-free core。Outlookはこのprepared coreを直接使い、moduleにはdefault-observation `Build`とprepared date policyだけが残る。
- `household_policy.bqn` — 家計ポリシーレイヤ。
- `household_metadata.bqn` — 家計メタデータ診断。
- `plan_rows.bqn` — 予定行の source evidence（`PlanId` / `InCycle` / `BuildBase`）、actual value、temporal status の共有 owner。
- `plan_status.bqn` — 明示 `as_of` に対する `future / due / overdue / completed` 分類の独立した純粋 owner。
- `plan_journal_overlap.bqn` — plan/journal 重複検出。
- `format.bqn` — テキスト整形、ANSI color helper、semantic color/no-color制御。
- `report_labels.bqn` — report presentation labels の正本ローダー (`config/report_labels.tsv`)。
- `issues.bqn` — Issues & Decisions ログの表示フォーマット。
- `util.bqn` — 基本ユーティリティ (Split, ToNum, LoadLines)。
- `json.bqn` — 汎用 BQN JSON シリアライザ（数値、文字列、エスケープ、リスト、オブジェクトのネストに対応）。
- `date.bqn` — 日付操作 (Today, Parts, Ordinal, DaysBetween)。
- `unavailable.bqn` — unavailable sentinel の正本定義と helper (`IsUnavailable`, `StartsWith`)。
- `config.bqn` — config.tsv 読み込み。
- `report_sections.bqn` — report sectionの静的descriptor（key、canonical order、metadata label spec、category、owner path、現行output metadata値）を所有するpure data module。builder、I/O、config、clock、CLIは持たない。
- `report.bqn` — 人間向けレポートの正本入口。`report_sections.bqn`のkey/orderに、localなhuman builderを一対一で対応させ、`--list-sections` / `--section <key>` / full report / cacheを構築する。cache生成時は同じdescriptor orderから`.section-keys` manifestも出力する。builder実行、first-line marker、JSON dispatch、CLIは引き続きこのmoduleが所有する。default currencyを宣言したledgerではhuman `balances`のdirect/full/cache bodyをselected-domain経路へ統一する。明示`--currency`はhuman direct `balances`専用で、full report・他section・cache・JSONとの組合せはfail closed。
- `report_section_metadata.bqn` — `report_sections.bqn`から静的rowを受け、label解決とUI向けstructured metadata export（TSV default / JSON）を所有する。source TSVは読まず、serializerは今回のdescriptor移行では既存実装を維持する。
- `summary.bqn` — 機械向けコンパクト出力。

### `src_edit/` (BQN editor subsystem)

`tools/edit-bqn` を支える BQN editor subsystem。`src_next/` (report) とは独立。

- `src_edit/README.md` — 責務境界と実装対象の定義。
- `src_edit/account_add_cmd.bqn` — 明示role・名前空間・重複・asset typeを検証し、accounts.tsv追記候補を生成。
- `src_edit/account_list_cmd.bqn` — UI向け account candidate export。`accounts.tsv` の role メタ解釈を BQN 側に閉じ込める。
- `src_edit/journal_add_cmd.bqn` — `budget add` のTSV候補を検証・生成する。
- `src_edit/actual_journal_file_cmd.bqn` — BQN resolverが選んだnative Journal相対pathをUI/toolsへ出力する。
- `src_edit/journal_validate_cmd.bqn` — configured native Journalと統合contextをfail closedに検査する書き込み後validator。
- `src_edit/journal_block_add_cmd.bqn` — native Journal transaction blockの検証・append protocol生成。ordinary appendは明示supported currencyを受け、complete-source admissionとStage 2A currency-proof carrierを再利用する。省略時JPY互換、single-domain、account-currency、exact precision、balanceをfail closedに検査する。CLI `trip_id`→native `trip-id`と`payment=cash|card|debit`を含む明示metadataのparse round-tripも検査する。
- `src_edit/travel_friend_add_cmd.bqn` — `friend_travel_events.tsv` の既存全行検査とpending候補APPEND protocol生成。意味検査はpure source-event ownerへ委譲。
- `src_edit/travel_exchange_add_cmd.bqn` — accountsと`travel_exchange_events.tsv`をpure exchange ownerへ渡し、固定10列候補APPEND protocolを生成。
- `src_edit/journal_list_cmd.bqn` — journal reverse UI向け read-only native Journal selection export。
- `src_edit/journal_native_reverse_cmd.bqn` — native Journal reverseの検証および反対仕訳block生成。
- `src_edit/issue_add_cmd.bqn` — issue add 用の検証および TSV 生成。
- `src_edit/issue_list_cmd.bqn` — issue close UI向けの open issue 候補 export。
- `src_edit/issue_close_cmd.bqn` — issue close 用の検証および safe replace TSV 生成。
- `src_edit/plan_add_cmd.bqn` — plan add 用の検証および TSV 生成。
- `src_edit/plan_list_cmd.bqn` — plan list 用の BQN 実装。unfinished candidate exportと、明示`as-of`に対する`all / overdue / upcoming`候補絞り込みを所有する。契約は `docs/UNFINISHED_PLAN_ENTRIES_EXPORT_CONTRACT.md`。
- `src_edit/plan_related_cmd.bqn` — plan finish replenishment UI 用の read-only 関連予定抽出。`series=` → `plan_id` series → exact fallback の順序を所有する。
- `src_edit/plan_finish_cmd.bqn` — plan finishを検証し、native Journal transaction blockを生成する。
- `src_edit/plan_budget_sync_cmd.bqn` — 完了済み固定費予定の `plan_id`、actual、設定、execution envelope、通貨、既存budget linkageを検査し、冪等なbudget companion候補を生成。曖昧な対応や通常収入は扱わない。
- `src_edit/plan_edit_cmd.bqn` — plan edit 用の検証および exact REPLACE protocol 生成。
- `src_edit/journal_reconstructible_identity_cleanup.bqn` — 再構築可能で機能的に参照されていない migration 由来 event-id 削除の純粋 semantic owner & バイト保存 transformer。
- `src_edit/journal_reconstructible_identity_cleanup_cmd.bqn` — reconstructible Journal identity cleanup の CLI command adapter (inspect / candidate / apply)。
- `src_edit/plan_id.bqn` — plan_id 生成補助。
- `src_edit/render.bqn` / `src_edit/validate.bqn` — 共通レンダリング / バリデーション。

責務: edit intent の受取 → 入力バリデーション → 候補 TSV 行や編集操作の生成 → 機械可読出力。
shell safe-write (`tools/lib/`) が実際のファイル書き込みを担当する。

### `tools/edit`

- 日常の公開 editor コマンド入口。
- `tools/edit-bqn` へそのまま委譲する薄いラッパー。`journal multi-add` は選択中のnative Journalへ2件以上の符号付きpostingを1取引として渡し、TSV modeではfail closedする。
- CLI 互換の安定点として扱う。
- UI向け read-only export として `tools/edit account list [--role ROLE]` も提供する。

### `tools/edit-bqn`

- 日常 write path の BQN+shell 実装。
- `account add` / `account list` / `journal add` / `journal list` / `travel friend add` / `travel exchange add` / `budget add` / `issue add` / `issue list` / `issue close` / `plan add` / `plan list` / `plan related` / `plan finish` / `plan budget-sync` / `plan edit` / `journal reverse` を扱う。
- `src_edit` の機械可読プロトコルを受け、`tools/lib/safe-write.sh` で安全に適用する。
- Dispatcher boundary の現行メモは `docs/EDIT_BQN_DISPATCHER.md`。共通 shell helper は `tools/lib/edit-bqn-common.sh`、`issue add` handler は `tools/lib/edit-bqn-issue.sh`。
- Go editor の記述や fallback 前提は現行導線では使わない。

### `checks/` (検証スクリプト)

- `check-src-next-golden.sh` — `developer_inspection.bqn`のpublic fixture goldenチェック。projection header、tabular rows、source-balance表示も固定する。
- `check-ledger-facts-phase1-proof-fixture.sh` — strict public fixtureでTrial Balance、Recent split transaction、Daily Flow dynamic axis、selected Balances、durable Plan JSON、15 section routingの現行semantic baselineを固定する。
- `check-ledger-facts.sh` — canonical fact columns、identity/source provenance、multi-posting zero-sum、empty admission、strict date coordinateと、destinationから旧runtime/I/Oへの依存禁止を検証する。
- `check-src-next-import-graph.sh` — `src_next/**/*.bqn`のdirect `•Import` target、root/nested module観測、required entrypoint、cycle report生成を検証する。`check-repo-index.sh`経由でfull checkに入る。
- `check-developer-inspection-entrypoint.sh` — named entrypointと`main.bqn` wrapperの終了status・stdout・stderr一致、thin-wrapper source shape、`tools/report-next` routingを検証する。
- `check-projection-diagnostic-presentation.sh` — diagnostic presentationが`developer_inspection.bqn`へlocalizeされ、`main.bqn`、`projection.bqn`、production reportへ戻らないことを検証する。
- `check-src-next-minimal-summary.sh` — 最小サマリチェック。
- `check-src-next-cycle-summary.sh` — サイクルサマリチェック。
- `check-src-next-ytd-summary.sh` — YTD サマリチェック。
- `check-src-next-*.sh` — 各セクションの fixture チェック。
- `check-src-next-daily-trend-plan-numeric-owner.sh` — Daily Trend plan金額owner、source join、D-local completion、fail-closed fixtureを検証。
- `check-report-section-metadata.sh` — report section metadata TSV export の契約チェック。
- `check-report-source-readiness-audit.sh` — strict-source readiness auditのreadonly性、missing metadata集計、invalid path failureをsynthetic temp baseで検証する。
- `check-src-next-export-caller-inventory.sh` — export caller inventoryのruntime/test/check scope、ForTest/zero-caller分類、invalid root failureをsynthetic source treeで検証する。
- `check-repo-index.sh` — repo-index ツールのチェック。
- `check-disabled-features.sh` — 無効化機能の隔離チェック。
- `check-edit-bqn-account-list.sh` — BQN account list export チェック。
- `check-edit-bqn-journal-add.sh` — BQN journal/budget/issue add parityチェック。
- `check-journal-canonical-prefix-converter.sh` — public synthetic prefix publication、failure no-publish、suffix byte preservation、concurrent exclusive-publishチェック。
- `check-edit-bqn-journal-post-check-recovery.sh` — mixed JPY/ILS journal source lint、post-check失敗時のexact rollback、後続writer保護チェック。
- `check-edit-bqn-travel-friend-add.sh` — friend pending source-eventのdry-run、exclusive first-write、checked append、stale/duplicate拒否、rollback回帰チェック。
- `check-travel-exchange-pure.sh` — exchange structured previewのpure contractとI/O/rate/journal output不在チェック。
- `check-edit-bqn-travel-exchange-add.sh` — exchange sourceのexclusive first-write、全行検査、checked append、stale/duplicate拒否、rollback回帰チェック。
- `check-israel-travel-four-path-rehearsal.sh` — exchange → ILS cash journal → confirmed-JPY card journal → friend pendingを一つのsynthetic baseで公開入口から実行する統合回帰。
- `check-israel-ils-usable-vertical-slice.sh` — supported-currency ordinary append、mandatory admission/carrier validation、JPY/ILS/USD共通selected-domain経路、empty Actual + plan/budget、共通expense section、domain isolation、失敗時no-writeを公開synthetic baseで検証。
- `check-edit-bqn-issue-close.sh` — BQN issue list/close の履歴保持・dry-run・fail-closed チェック。
- `check-edit-bqn-journal-list.sh` — BQN journal list read-only selection exportチェック。
- `check-edit-bqn-plan-list.sh` — BQN plan list parity / unfinished plan candidate export 契約チェック。
- `check-edit-bqn-plan-add.sh` — BQN plan add parityチェック。
- `check-edit-bqn-plan-finish.sh` — BQN plan finish parityチェック。
- `check-edit-bqn-plan-budget-sync.sh` — `plan_id` linked execution-envelope companionのdry-run、actual amount、冪等retry、NOT_LINKED、stale failure後retryを検証。
- `check-safe-replace-line.sh` — 安全置換 primitive のアサーションチェック。

### `tests/` (ユニットテスト)

- `test_src_next_*.bqn` — src_next 各モジュールのテスト。
- `test_src_next_exact_sparse_grouping.bqn` — empty input、duplicate accumulation、negative values、conservation、first-occurrence order、contributor sidecar、Cube numeric reconstruction、TBDS-like reuse、domain-separated groupingをcharacterizeする。
- `test_src_next_actual_expense_ranking.bqn` — explicit expense AccountKey partition、multi-posting内の非expense debit除外、TBDS relation parity、selected-domain producer integration、JPY/ILS scale、domain/scale fail-closed、deterministic ranking、ranking-order coordinates、contributor posting IDsを検証する。zero-net caseのnegative debitはproducer admissionではなくdefensive synthetic characterizationである。
- `test_journal_posting_ir_adapter_stage2a.bqn` / `test_journal_posting_identity_provenance_stage2b.bqn` — Journal test-only Posting IR success parityとidentity/provenance carrierのfocused tests。
- `test_journal_posting_ir_comparable_rejection_stage2c.bqn` — invalid date / invalid exact-integer amount / unknown accountのJournal・legacy TSV structural rejection parityを既存境界だけで観測するfocused test。
- `test_journal_canonical_prefix_converter.bqn` — deterministic rendering、description/metadata/currency red paths、identity/provenance、Cube/TBDS/Trial Balance/Balances parity、historical profile、synthetic suffix reconstructionのfocused test。
- `test_journal_leading_ascii_space_description_characterization.bqn` — status marker後の必須ASCII SPACEを一文字だけdelimiterとして消費し、残るdescription-owned leading ASCII SPACEをTransaction IRへexactに保存する回帰test。delimiter欠落とempty payloadを区別してrejectし、converterによる一文字・二文字のleading-space exact round-tripとStage 2Aの16-field shape不変も固定する。
- `test_journal_native_three_posting_semantic_parity.bqn` — native Journal 3 rowsとlegacy TSV 4 rowsのtopology差を保持したまま、共通semantic coordinate reductionとnumeric Cube payloadの一致を既存境界だけで検証するfocused test。
- `test_src_next_selected_domain_context.bqn` — mixed Journalとplan/budget evidenceからJPY/ILS/USDを同じ経路で1通貨だけ構成し、empty/other-currency Actual、domain/scale isolation、fail-closed mismatch、同名accountのcurrency coordinate分離に加え、unsupported policyがsource workを止め、Actual admission failureがnon-Actual preparationを止めるfirst-failure stage priorityを検証する。
- `test_src_next_cycle_summary.bqn` — fixture-free prepared TBDS/cycle evidenceからbaseやcontextなしでCycle Summary VMを構成できることと、compatibility context adapter / machine outputを固定する。
- `test_src_next_planned_payments.bqn` — production fixtureのhuman contractに加え、base/contextを持たないprepared evidenceからsemantic/compact VMとcompact/JSON renderingを構成できることを固定する。
- `test_src_next_actual_observation.bqn` — 共有された2つのActual observation policyについて、unsorted dates、half-open終端、empty fallback、unavailable cycle、および不整合なsynthetic cycleで両policyのwindow ownershipが異なることを固定する。
- `test_src_next_cycle_prepared_evidence.bqn` — Actual source fileを持たないfixtureでalready-admitted income evidenceからincome-anchor cycleを解決し、完全production fixtureではsource-loaded routeとmode/start/end/day_countが一致することを検証する。存在しないbaseを持つprepared contextからActual dates、completion amount/identity、cycle-local plan IDsをI/Oなしで抽出できることも固定する。
- `test_lib.bqn` — テストフレームワーク (Assert, AssertEq)。
- `test_find_section.bqn`, `test_simple.bqn` — 汎用テスト。

## tools 地図

### 検査・CI

- `tools/check.sh` — テストランナーの正本。ユニットテスト、エンジン不変条件、各セクションの golden 差分、devtools-check などを一括実行する。
- `tools/devtools-check.sh` — 全開発ツールの健全性チェック（`check.sh` のフェーズ4に組み込み済み）。
- `tools/scaffold-check.sh` — 新しい `checks/check-*.sh` スクリプトのボイラープレート（テンプレート）生成用。
- `tools/coverage` — BQN module / editor-check inventory を出力する。

### 開発・検証支援 (devtools)

- `tools/repo-index` — リポジトリの BQN ファイルやチェックスクリプトの索引を管理。ファイル追加・削除時は `--baseline` で更新する。
- `tools/src-next-import-graph` — `src_next/**/*.bqn`のrelative direct importをread-onlyに列挙し、summary、module degree、cycle、Graphviz DOT、missing-target validationを出す。directory migration前後のtopology evidenceに使う。
- `tools/characterization/report_context_duplication_probe.bqn` — ordinary `BuildContext`、selected adapter、明示prepared-input routeをpublic base上で比較するread-only harness。timing thresholdは契約にせず、direct/prepared selected shape parityをfocused checkで固定する。
- `tools/characterization/report_source_readiness_audit.py` — 明示pathだけをread-only監査し、DEFAULT_CURRENCY、account/Plan/Budget currency、Plan ID、role、Actual layoutのstrict-source readinessをTSVまたは集計で返す。private outputは明示指示なしに公開しない。
- `tools/characterization/src_next_export_callers.py` — final export recordとqualified import aliasをsource-levelに走査し、runtime/editor/test/check/tool caller数、ForTest seam、zero-caller exportをTSVまたは集計で返す。
- `tools/doctor` — 設定とデータディレクトリの整合性診断。
- `tools/bqn-eval` — BQN式の簡易評価用。
- `tools/bqn-dump` — BQN値の型とshape診断用。
- `tools/query` — `report-next-summary` 出力の機械可読検索・抽出フィルタ。
- `tools/envelope-calc` — 封筒予算の対話的計算（P1〜P4 プリミティブ実行）。

### ユーザーインターフェース (UI)

- `tools/main-ui.sh` — 読み込み・閲覧系UI（レポート閲覧・セクション選択、fzf/gumベース）。TTYではcold/stale cacheを待たずselectorを開き、非対話では同期refreshを使う。
- `tools/command-hub-cache-refresh` — command-hub preview cacheをexclusive refreshするshell owner。BQNの単一canonical cache生成をstageし、`.section-keys`由来のpreview fileとmanifestをatomic renameした後、timestampを最後にpublishする。section key配列、本文生成、差し替えは持たない。
- `tools/command-hub-preview` — highlightごとのmanifest/file/status-only reader。生成中・失敗・readyを表示し、report engineを起動しない。section key whitelistは重複保持しない。
- `tools/add-ui.sh` — 書き込み・操作系UI（取引の追加・取消・予定完了処理等、BQN editor への安全な中継）。
- `tools/plan-finish-replenish-ui.sh` — 予定候補をmemo-firstの内容表示で選択し、実績日/金額入力前に内容・予定日・金額・振替・plan IDを再確認させる。pre-apply `Ctrl+C`はstatus 130で`add-ui` mode選択へ戻し、post-apply `Ctrl+C`は完了済み実績を否定せず補充だけを中止する。実績化後は次回予定補充を案内し、`tools/edit plan finish` と`plan add`を合成するだけで低層TSV契約は持たない。
- `tools/journal-prefix` — explicit accounts/snapshot/source identity/cycle/outputだけを受けるcanonical prefix conversion / public reconstruction command。temporary sibling検証後のexclusive atomic createで、production path defaultを持たない。
- `tools/journal-identity-cleanup` — 再構築可能で機能的に参照されていない migration 由来 event-id 削除の safe cleanup CLI (inspect / candidate / apply)。
- `tools/edit` — 公開 editor コマンドの薄い shell wrapper。
- `tools/edit-bqn` — 現行の BQN+shell editor 入口。`src_edit` の write path を実行する。
- `tools/report` — `src_next/report.bqn`を使う人間向けproduction report入口。
- `tools/report-next` — `src_next/developer_inspection.bqn`を使うread-only diagnostic wrapper。名前はhistorical compatibilityでありproduction reportではない。
- `tools/report-next-summary` — `src_next` データの機械向け要約出力。
- `tools/report-section-metadata` — source TSV を読まない report section metadata export（TSV default / JSON）。UI は human report 文字列を parse せず、このような structured export を使う。
- `tools/bl` — 日常操作 Command Hub。report / section / add / check / edit をまとめ、読み取り表示と安全な書き込み導線へルーティングする。`edit` の対話モードは TSV 選択サブメニューを持ち、編集後は同じサブメニューへ戻り、`back` / cancel / Ctrl-C で hub 上位へ戻る。
