# src_next アーキテクチャ設計

Status: **active design — next ledger engine candidate**
合言葉: `src_next は次期正本エンジン候補。既定化は検証後。`

## 0. この文書の目的

`src_next` を次期 ledger engine candidate として育てるための構造を決める。
保守性・拡張性・会計的整合性を満たしながら、12の本番レポートを再現できる設計を整理する。

実装に入る前に、「どのモジュールが何を知っているか」を決める。
主軸は `ENGINE_DESIGN_COMPARISON.md` の Option 10 (Posting IR) + Option 5 (TBDS) とする。

### 0.1 Accounting-grade correction

2026-06-26 時点で、`src_next` は human report parity より先に accounting engine quality gate を通す。

決定:

```text
cycle / period は ledger 読み込み境界ではない。
cycle / period は report query boundary である。
```

従って、`src_next` の core は次へ寄せる。

```text
BuildLedgerContext(base)
  -> all valid Posting IR rows
  -> validated ledger-wide posting set

BuildPeriod(ctx, period_start, period_end_exclusive, as_of)
  -> TBDS opening / movement / closing
```

残高系 section は TBDS `closing` を使い、期間 flow 系 section は TBDS `movement` を使う。`movement` を `balance` として表示する実装は会計エンジンとして不正であり、`docs/ACCOUNTING_ENGINE_QUALITY_PLAN.md` の Phase A で修正する。

---

## 1. 新旧エンジンの構造比較

### 旧エンジン (`src/`)

```
src/core/          ← 計算の土台（cube, accounts, layers, date, cycle）
    ↓  cube (Day×Account×Layer)
src/views/         ← cube からドメイン集計（cycle_view, envelope_view, liquid_view...）
    ↓  aggregate records
src/reports/report_engine.bqn  ← Build: 全viewを束ねて巨大recordを返す
    ↓  giant record
src/reports/sections/          ← Sec1〜Sec12: 表示整形のみ
    ↓  stdout
```

**長所**: core → views → sections の3層分離が明確。views は純粋関数。
**短所**: report_engine が全viewを束ねる巨大ハブになり、Build の返り値が膨大。section を増やすたびに report_engine を触る必要がある。

### src_next (`src_next/`)

```
src_next/
  projection.bqn    ← TSV → 投影行
  cube.bqn          ← 投影行 → Day×Account×Layer
  cycle_summary.bqn ← 計算 + 表示（両方）
  ytd_summary.bqn   ← 計算 + 表示（両方）
  balances.bqn      ← 計算 + 表示（両方）
  ...               ← 残りのモジュールも同様
  summary.bqn       ← 全モジュールを順に呼ぶ
```

**長所**: 各モジュールが自己完結。依存が少ない。
**短所**: 計算と表示が混在。同じ cube を各モジュールが別々に集計している（重複）。テストしにくい。

---

## 2. 提案: 4層アーキテクチャ

旧エンジンの「core → views → sections」の良さを残しつつ、report_engine の巨大ハブを解体する。

```
Layer 0: Source       data/*.tsv           ← 正本。コードではない。

Layer 1: Infra        loader, projection,   ← TSVを読んで投影行をつくる。
                      account_key, cycle     一度だけ実行。cubeへの入力。

Layer 2: Cube         cube.bqn              ← 投影行 → Day×Account×Layer。
                                             全viewが共有する唯一のmaterialized view。

Layer 3: Views        view_cycle.bqn        ← cube → ドメイン集計。
                      view_ytd.bqn           純粋関数。cube以外の入力は
                      view_balances.bqn      metadata (account_keys等) のみ。
                      view_envelope.bqn      計算ロジックはここだけ。
                      view_outlook.bqn
                      view_trend.bqn
                      view_planned.bqn
                      view_recent.bqn
                      view_readiness.bqn
                      view_actual_cmp.bqn
                      view_snapshot.bqn
                      view_debug.bqn

Layer 4: Format       fmt_cycle.bqn         ← 集計record → 人間向け文字列。
                      fmt_ytd.bqn             表示整形のみ。計算はしない。
                      ...                     どのviewにも対応するfmtがある。

Layer 5: Orchestrate  report.bqn            ← main entrypoint。
                                             Infra→Cube→全View→全Formatを
                                             順に呼んで stdout に出すだけ。
```

### 各層のルール

| 層 | 知っていること | 知らないこと |
|---|---|---|
| Infra | TSVの形式、ファイルパス、日付解析 | 会計意味、封筒、レポート |
| Cube | 投影行のDay/Account/Layer index、delta集約 | 元のTSV行の意味、封筒、表示 |
| Views | cube shape、account keys、cycle範囲 | 表示整形、stdout、ファイルI/O |
| Format | 各viewの出力record shape | cube、TSV、計算ロジック |
| Orchestrate | 全モジュールの呼び出し順 | 個別の計算詳細 |

---

## 3. 12レポートのマッピング

各レポートに view と format のペアを割り当てる。

| # | レポート | View モジュール | Format モジュール | 既存 src_next 相当 |
|---|---|---|---|---|
| 1 | 全体サマリ (Snapshot) | `view_snapshot.bqn` | `fmt_snapshot.bqn` | `snapshot.bqn`（分離必要） |
| 2 | 年初来サマリ (YTD) | `view_ytd.bqn` | `fmt_ytd.bqn` | `ytd_summary.bqn`（分離必要） |
| 3 | 勘定科目一覧 (Balances) | `view_balances.bqn` | `fmt_balances.bqn` | `balances.bqn`（分離必要） |
| 4 | 今サイクル集計 (Cycle) | `view_cycle.bqn` | `fmt_cycle.bqn` | `cycle_summary.bqn` + `expense_breakdown.bqn`（分離必要） |
| 5 | 封筒・予算残高 (Envelopes) | `view_envelope.bqn` | `fmt_envelope.bqn` | `envelope_computation.bqn`（分離必要） |
| 6 | 未来の支払い等予定 (Planned) | `view_planned.bqn` | `fmt_planned.bqn` | `planned_payments.bqn`（分離必要） |
| 7 | 直近の取引 (Recent) | `view_recent.bqn` | `fmt_recent.bqn` | `recent_journal.bqn`（分離必要） |
| 8 | レポート準備チェック (Readiness) | `view_readiness.bqn` | `fmt_readiness.bqn` | `readiness_check.bqn` + `household_metadata.bqn` + `plan_journal_overlap.bqn`（統合＋分離必要） |
| 9 | 見通し・日割り (Outlook) | `view_outlook.bqn` | `fmt_outlook.bqn` | 新規 |
| 10 | 日割り推移 (Trend) | `view_trend.bqn` | `fmt_trend.bqn` | 新規 |
| 11 | Actual比較検証 (Comparison) | `view_actual_cmp.bqn` | `fmt_actual_cmp.bqn` | `actual_comparison.bqn`（分離必要） |
| 12 | デバッグ・由来 (Debug) | `view_debug.bqn` | `fmt_debug.bqn` | `cube.bqn`（分離必要） |

### view の入力・出力の契約

全 view は同じ入力シグネチャを持つ:

```
Input:  result  — cube.Materialize の返り値（namespace）
        ak_keys — account_key の配列
        cy      — cycle info (start, end_exclusive, day_count)
        base2   — データディレクトリパス（recent_journal など TSV直読が必要な場合のみ）

Output: namespace（そのレポートに必要な全フィールド）
```

例外: `view_recent.bqn` は cube からではなく `journal.tsv` を直接読む（cube は集約済みのため個別取引を復元できない）。

---

## 4. 旧エンジン・現 src_next との差分

### 旧エンジンとの差分

| 観点 | 旧エンジン | 提案 |
|---|---|---|
| view の位置 | `src/views/` | `src_next/views/` |
| view の責務 | cube → aggregate record | 同じ |
| format の位置 | `src/reports/sections/` | `src_next/fmt/` |
| format の責務 | 表示整形のみ | 同じ |
| 束ね役 | `report_engine.bqn` (巨大record) | なし。各viewが個別に出力 |
| section 追加時の変更箇所 | report_engine + sections + main | view + fmt + report.bqn 呼び出し1行追加 |

### 現 src_next との差分

| 観点 | 現 src_next | 提案 |
|---|---|---|
| 計算と表示 | 1モジュールに混在 | view と fmt に分離 |
| cube 集計 | 各モジュールが重複して行う | cube.Materialize は1回、結果を全viewに渡す |
| テスト容易性 | 出力文字列の比較のみ | view の出力 record を fixture 比較可能 |
| モジュール数 | 少ない（1 section = 1 module） | 増える（1 section = 2 modules）が責務は明確 |

---

## 5. 移行戦略: 壊さずに組み替える

現 src_next はすでに動作している。これを一気に全撤去して作り直すより、段階的に組み替える。

### 移行の原則

1. **現行の出力を壊さない。** `tools/check.sh` の src_next fixture checks が pass し続けること。
2. **1 section ずつ view/fmt に分離する。** 全 section を一度にやらない。
3. **分離が完了した section から、summary.bqn の呼び出しを新しい view+fmt に切り替える。**
4. **古い一体型モジュールは、全 section の移行が完了してから削除する。**

### 移行順

第1段階の4 section（2,3,4,7）から始める。これらは計算ロジックが最も単純で、view/fmt 分離の効果が見えやすい。

```
Step 1: Sec 4 (Cycle) を view_cycle.bqn + fmt_cycle.bqn に分離
        → summary.bqn で新しい呼び出しに切り替え
        → check.sh で fixture pass 確認
Step 2: Sec 2 (YTD) を view_ytd.bqn + fmt_ytd.bqn に分離
Step 3: Sec 3 (Balances) を view_balances.bqn + fmt_balances.bqn に分離
Step 4: Sec 7 (Recent) を view_recent.bqn + fmt_recent.bqn に分離
```

第2段階以降も同様に、1 section ずつ進める。

---

## 6. ディレクトリ構造（C+F 中間案・推奨）

view と fmt を関数として分離し、1 section = 1 ファイルにまとめる。

```
src_next/
  # Layer 1: Infra（変更なし）
  loader.bqn
  projection.bqn
  account_key.bqn
  cycle.bqn              ← ReadCycle（infra）

  # Layer 2: Cube（変更なし）
  cube.bqn

  # Layer 3+4: Section modules（Build + Format を1ファイルに）
  snapshot.bqn           ← BuildSnapshot + FormatSnapshot
  ytd.bqn                ← BuildYTD + FormatYTD
  balances.bqn           ← BuildBalances + FormatBalances
  cycle_report.bqn       ← BuildCycle + FormatCycle
  envelope.bqn           ← BuildEnvelope + FormatEnvelope
  planned.bqn            ← BuildPlanned + FormatPlanned
  recent.bqn             ← BuildRecent + FormatRecent
  readiness.bqn          ← BuildReadiness + FormatReadiness
  outlook.bqn            ← BuildOutlook + FormatOutlook
  trend.bqn              ← BuildTrend + FormatTrend
  actual_cmp.bqn         ← BuildActualCmp + FormatActualCmp
  debug.bqn              ← BuildDebug + FormatDebug

  # Layer 5: Orchestrate
  report.bqn             ← 全 section を順に呼び出す。
  summary.bqn            ← 既存。移行完了後に report.bqn に統合。

  # 移行完了後に削除
  cycle_summary.bqn      → cycle_report.bqn (BuildCycle + FormatCycle)
  ytd_summary.bqn        → ytd.bqn (BuildYTD + FormatYTD)
  balances.bqn           → balances.bqn (BuildBalances + FormatBalances)
  recent_journal.bqn     → recent.bqn (BuildRecent + FormatRecent)
  ... (他も同様)
```

---

## 7. 設計選択肢の比較

12レポートを出力する方法は、提案した4層アーキテクチャだけではない。
BQN家計簿という制約の中で、少なくとも6つの道がある。

### A. 現 src_next 方式（flat modules）≪ 現状維持

```
cycle_summary.bqn  = 計算 + 表示（混在）
balances.bqn       = 計算 + 表示（混在）
...
summary.bqn が順に呼ぶ
```

| 観点 | 評価 |
|---|---|
| 計算/表示分離 | ✗ 混在 |
| モジュール数 | 最少（12個） |
| テスト容易性 | 低（文字列比較のみ） |
| 実装工数 | 完了済み |
| 拡張の局所性 | 低（表示変更で計算ファイルを触る） |
| 旧エンジン完全置換 | △ 可能 |

所感: 個人ツールとしては実用十分。ただし「一から綺麗に」という動機には合わない。

### B. 旧エンジン方式（giant record hub）

```
core/ → views/ → report_engine.Build (巨大record) → sections/ (表示のみ)
```

| 観点 | 評価 |
|---|---|
| 計算/表示分離 | ◯ 分離済み |
| モジュール数 | 中（~24個） |
| テスト容易性 | 中 |
| 実装工数 | 完了済み |
| 拡張の局所性 | 低（section追加のたびにreport_engineを編集） |
| 旧エンジン完全置換 | — 旧エンジンそのもの |

所感: 実績はあるが、Build の返り値が膨大で、section 追加のたびに巨大ハブを触る必要がある。

### C. 4層方式（views + fmt）≪ 提案

```
cube → views/ (計算) → fmt/ (表示) → report.bqn (順に呼ぶだけ)
```

| 観点 | 評価 |
|---|---|
| 計算/表示分離 | ◯ 明確に分離 |
| モジュール数 | 多（24+個） |
| テスト容易性 | 高（view出力をfixture比較可能） |
| 実装工数 | 中 |
| 拡張の局所性 | 高（view+fmt 追加だけで済む） |
| 旧エンジン完全置換 | ◯ 可能 |

所感: 責務分離は最も明確。ただし12×2=24モジュールはやや大げさかもしれない。

### D. Export-first 方式

```
src_next は機械向け出力（JSON / TSV / machine summary）だけを出す。
表示整形は別ツール（shell+gum / Go / 旧エンジンの sections）に任せる。
```

| 観点 | 評価 |
|---|---|
| 計算/表示分離 | ◯ 完全分離 |
| モジュール数 | 少 |
| テスト容易性 | 最高（JSON diff） |
| 実装工数 | 大（表示側を別途作る必要） |
| 拡張の局所性 | 高 |
| 旧エンジン完全置換 | △ 表示に別ツールが必要 |

所感: 「正しい数値を出す」に集中できるが、人間が読むのに別ツールが要る。12レポートすべてを人間向け整形する手間は結局どこかで発生する。

### E. 旧エンジン views 再利用方式

```
src_next は cube だけ作る。
views の計算ロジックは旧エンジンの src/views/ をそのまま呼ぶ。
表示だけ src_next 側で新しく書く。
```

| 観点 | 評価 |
|---|---|
| 計算/表示分離 | ◯ |
| モジュール数 | 少 + 旧資産 |
| テスト容易性 | 中 |
| 実装工数 | 小 |
| 拡張の局所性 | 低（旧エンジン依存が残る） |
| 旧エンジン完全置換 | ✗ 依存が残る |

所感: 計算ロジックを再実装しなくて済むが、旧エンジンと src_next の cube が別物なので互換性の検証が必要。完全な置き換えにはならない。

### F. 単一ファイル + データ駆動方式

```bqn
sections ← [
  { label: "Cycle Summary",  view: ViewCycle,  fmt: FmtCycle },
  { label: "YTD Summary",    view: ViewYTD,    fmt: FmtYTD   },
  ...
]
{ PrintSection 𝕩 }¨ sections
```

| 観点 | 評価 |
|---|---|
| 計算/表示分離 | △ 関数としては分離、ファイルとしては混在 |
| モジュール数 | 最少（1〜2ファイル） |
| テスト容易性 | 中 |
| 実装工数 | 小 |
| 拡張の局所性 | 中 |
| 旧エンジン完全置換 | ◯ 可能 |

所感: BQNの配列思考と最も相性が良い。section 追加が配列に1行足すだけ。ただし1ファイルが大きくなりすぎるリスクがある。

### 総合比較表

| | A: flat | B: giant hub | C: 4-layer | D: export-first | E: reuse views | F: single-file |
|---|---|---|---|---|---|---|
| 計算/表示分離 | ✗ | ◯ | ◯ | ◯ | ◯ | △ |
| モジュール数 | 12 | ~24 | 24+ | 少 | 少+旧 | 1〜2 |
| テスト容易性 | 低 | 中 | 高 | 最高 | 中 | 中 |
| 実装工数 | 済 | 済 | 中 | 大 | 小 | 小 |
| 拡張の局所性 | 低 | 低 | 高 | 高 | 低 | 中 |
| 旧エンジン完全置換 | △ | — | ◯ | △ | ✗ | ◯ |

### C と F の中間案（推奨）

view と fmt を**概念として**分ける（関数を分ける）が、**ファイルは分けすぎない**。
密接に関連する view+fmt は同じファイルに置く。

```bqn
# cycle.bqn ─ 1ファイルに view と fmt の両方を置く
BuildCycle ← { 𝕊 cube‿ak_keys‿cy: ... }    # view (計算)
FormatCycle ← { 𝕊 cycle_record: ... }        # fmt (表示)
```

```
src_next/
  loader.bqn
  projection.bqn
  account_key.bqn
  cycle.bqn          ← BuildCycle + FormatCycle
  cube.bqn
  snapshot.bqn       ← BuildSnapshot + FormatSnapshot
  ytd.bqn            ← BuildYTD + FormatYTD
  balances.bqn       ← BuildBalances + FormatBalances
  envelope.bqn       ← BuildEnvelope + FormatEnvelope
  planned.bqn        ← BuildPlanned + FormatPlanned
  recent.bqn         ← BuildRecent + FormatRecent
  readiness.bqn      ← BuildReadiness + FormatReadiness
  outlook.bqn        ← BuildOutlook + FormatOutlook
  trend.bqn          ← BuildTrend + FormatTrend
  actual_cmp.bqn     ← BuildActualCmp + FormatActualCmp
  debug.bqn          ← BuildDebug + FormatDebug
  report.bqn         ← 全 section を順に呼ぶ
```

| 観点 | C+F 中間案 |
|---|---|
| 計算/表示分離 | ◯ 関数として分離 |
| モジュール数 | 16前後（cube + infra + 12 section） |
| テスト容易性 | 高（Build* 関数の出力を fixture 比較可能） |
| 実装工数 | 小〜中 |
| 拡張の局所性 | 高（1 section 追加 = 1ファイル追加 + report.bqn 1行） |
| 旧エンジン完全置換 | ◯ 可能 |

---

## 8. 設計判断: なぜこの形か

### Q: なぜ旧エンジンの report_engine (巨大ハブ) を再現しないのか？

旧エンジンでは、`Build` が全 view を呼んで1つの巨大 record に束ねている。これは「全 section が同じ as_of で揃う」という整合性の保証にはなるが、section を追加するたびに report_engine を修正する必要がある。

提案では、各 view が独立した namespace を返し、report.bqn が呼び出し順を決めるだけにする。整合性は「全 view が同じ cube と cycle を入力に取る」ことで保証される。

### Q: なぜ view と fmt を必ず分けるのか？

- **テスト**: view の出力（数値 record）を fixture と比較できる。文字列比較より安定する。
- **再利用**: 同じ view から「人間向け表示」と「機械向け TSV export」の両方を作れる。
- **変更の局所性**: 「表示を変えたい」だけで計算モジュールを触らなくて済む。
- **AI保守**: 責務が明確だと、AIに「fmt_cycle.bqn だけ修正して」と言える。

### Q: 12×2 = 24 モジュールは多すぎないか？

責務が明確な小さいモジュールは、1つの大きいモジュールより保守しやすい。BQN の `•Import` は軽量で、モジュール数が増えても実行時コストはほぼ変わらない。

どうしても減らしたい場合は、密接に関連する view を統合してもよい（例: `view_cycle.bqn` と `view_ytd.bqn` はどちらも cube の時間集計なので統合候補）。ただし、最初は分けて始めて、重複が目立ったら統合する方が安全。

---

## 9. いまは決めないこと

- **モジュールの統合判断**: 分けて実装した後、重複が目立つものだけ統合を検討する。
- **機械向け export**: まず人間向け表示を揃えてから。
- **旧エンジンの削除**: src_next が production default になるまで残す。
- **ディレクトリ名**: `views/` `fmt/` は仮。`view/` `format/` など実装時に決める。
- **report.bqn と summary.bqn の統合**: 移行完了時に判断。

---

## 10. 関連文書

- `docs/ARCHITECTURE.md` — 旧エンジンのアーキテクチャ
- `docs/ARCHITECTURE_NEXT.md` — 旧 src_next 設計メモ（cycle-ledger-core）
- `docs/CANONICAL_DAILY_CUBE.md` — Cube の契約
- `docs/SRC_NEXT_REPORT_SECTION_PARITY.md` — 12-report parity target
- `docs/SRC_NEXT_STAGE4B_IMPLEMENTATION_TODO.md` — 実装TODO
- `docs/MAIN_SECTIONS.md` — 本番 section map
