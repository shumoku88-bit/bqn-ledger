# bqn-ledger 監査報告 (2026-06-09)

## 総合評価

このリポジトリは、**「正データは TSV、人間が直接読める・書けることを優先し、BQN 側は派生ビュー・レポート・検査に徹する」**という大方針をよく守れている。

`journal.tsv` / `plan.tsv` / `budget_alloc.tsv` / `accounts.tsv` は正データとして扱われ、`budget_journal.tsv` や各種 export は派生物として扱われている。`tools/add.bqn` も budget 操作を `budget_alloc.tsv` に書く導線になっており、思想と日常運用の入口は良い。

ただし、Canonical Daily Cube への移行は **「思想としては成功、実装・docs・tests の同期は未完了」** という評価。`report_engine.bqn` は `report_tx_updates.BuildCube` を中心に動き、Day × Account × Layer の 4 layer（actual / plan / budget / forecast）を前提にしているが、同じリポジトリ内に `BuildDays` / `day_updates` / `day_balances` / 256×2 前提の説明・検査・export がかなり残っている。

設計の芯は良い。特に cycle、outlook、daily-trend、cycle-consult は「plan を Actual に混ぜない」方向で整理されている。一方で、封筒予測の plan 扱い、Actual layer の純度、cycle 表示境界、legacy 2-layer 説明の残存は、次に pit が作業するときに誤実装を誘発しやすい危険箇所。

> この監査は静的読解ベース。BQN 実行環境なしの監査だったため、「壊れている可能性が高い」はコードと文書の整合から判断した高信頼の静的所見として扱う。

## 重要所見

| 観点 | 評価 | 要点 |
|---|---|---|
| 正データと派生ビューの境界 | 良好だが一部は慣習依存 | SoT 宣言は強い。生成物も概ね派生物。ただし不正な `budget:*` 行を `journal.tsv` / `plan.tsv` に入れても lint/strict check で明確には止めない。 |
| Canonical Daily Cube | 設計は良いが invariant が未完成 | Dense day axis と 4 layer は妥当。ただし Actual に `budget_alloc.tsv` が混入する実装になっていた。 |
| cycle 境界 | 内部計算は概ね良い | 内部は `[start, end_exclusive)`。表示はまだ `〜 <end>` が残り、仕様とズレる箇所がある。 |
| plan layer の扱い | セクション別方針は整理済み、封筒だけ実装ズレ | outlook・daily-trend・cycle-consult は概ね意図に合う。envelopes は docs の説明どおりに future plan を控除できていない可能性が高い。 |
| tests / checks | legacy 互換寄り | `BuildCube` の layer invariant、future-only/empty bootstrap、cycle 境界 fixture が不足。 |

## 今すぐ直すべき危険点

最優先で直すべきなのは、**Canonical Daily Cube の invariant と、封筒予測の plan セマンティクス**。

| 危険点 | なぜ危険か | 優先度 |
|---|---|---|
| Actual layer に `budget_alloc.tsv` が混入している | docs では Actual=`journal.tsv`、Budget=`budget_alloc.tsv`+journal 由来消費と書くが、実装では `budget_alloc` の col0 が BuildCube layer0 に入る。表示で隠すだけでは invariant が壊れる。 | 高 |
| envelopes が docs どおりに future plan を控除していない | `plan.tsv` の `assets:* -> expenses:* budget=...` は `GetTxUpd` の col1 に envelope projection を持つが、BuildCube layer1 は col0 だけを使う。`report_envelope_trend.bqn` は layer1 の budget account を見ようとするため通常の変動費予定を拾えない。 | 高 |
| `plan.tsv` / `journal.tsv` に `budget:*` 行が入っても境界違反として止めない | 方針上は `budget_alloc.tsv` が配賦の SoT。lint/strict check は `budget:* -> budget:*` 行を禁止していない。 | 高 |
| future-only cube / as_of before cube で envelopes が壊れる可能性 | cube が future plan/budget だけで埋まると `has_history` が真になり、`trend_dns_cube` が空のまま末尾参照や平均計算へ進む危険がある。 | 高 |
| checks がまだ 256×2 / BuildDays 前提に寄る | `report_engine` は 256×4 snapshot を使うが、検査は legacy view の整合確認が中心。cube invariant の false confidence が出やすい。 | 高 |

## 急がなくてよい整理点

| 整理点 | いまの状態 | なぜ整理すると良いか |
|---|---|---|
| cycle 表示境界を `start〜end_exclusiveの前日` に統一 | 内部は半開区間、表示には `<end>` 形式が残る | ユーザー運用規約と表示を揃える。helper 化すると安全。 |
| archive を読む順番 | archive 監査を序盤で読ませる導線がある | 古い 256×2 / BuildDays 文脈に引っ張られやすい。現行 docs を先、archive は背景資料へ。 |
| `fixtures/basic` の封筒方針 | rent envelope など旧モデルが残る | 現行の daily/flex/reserve・固定費封筒外方針と学習導線を揃える。 |
| snapshot 文書 drift | 現行出力と一部ズレる | check に使っていないため古く見える。学習資料として更新したい。 |
| `report_tx_updates.bqn` の概念密度 | Load/StrictCheck、legacy BuildDays、BuildCube が同居 | ファイル分割より、入口コメントと helper 整理が効く。 |

## docs と実装のズレ一覧

| 文書/箇所 | ズレ | 影響 |
|---|---|---|
| `docs/AI_CODEMAP.md` | `BuildDays` / 256×2 / day view 中心の説明が残る | pit が canonical を誤認しやすい。 |
| `docs/ARCHITECTURE.md` | 2-layer 説明と cube-first 説明が混在 | 現役設計書として読むと理解を壊す。 |
| `docs/REPORT_FIELD_MAP.md` | `bal_final` を raw 256×2 と説明する箇所が残る | 公開 contract の shape を誤解する。 |
| `docs/REPORT_DESIGN.md` | envelopes の future variable plan 控除説明と実装がズレる | docs を信じて plan を増やすと警告が期待より甘くなる。 |
| `docs/CANONICAL_DAILY_CUBE.md` | Actual に `budget:*` が混入しない invariant を明記しているが、実装が守れていなかった | 「実装完了」とは言いにくい。 |
| `docs/CYCLE.md` / `docs/AI_TERMINAL_HANDOFF.md` | 表示は start〜前日と書くが、main 出力は `<end>` が残る | 人間向け表示が仕様に追随していない。 |
| `fixtures/basic` | 学習 fixture が現行 envelope 方針からズレる | 初学者/pit が旧モデルを現行設計と誤解しやすい。 |

## 追加した方がよいテスト

| テスト | 期待値 | 重要性 |
|---|---|---|
| empty journal bootstrap | journal が空、plan/budget_alloc が future-only でも outlook/envelopes/cycle-consult が壊れない | 高 |
| as_of が cube 範囲より前 / 後 / cube empty | BuildAt、trend、envelopes が zero/last snapshot を安全に出す | 高 |
| Actual layer invariant | `budget_alloc.tsv` を入れても layer0 の `budget:*` が必ずゼロ | 高 |
| cycle end_exclusive 境界 | 終端日の収入・支出は current cycle に入らず next cycle 側だけに入る | 高 |
| cycle 終端日ちょうどの variable plan | daily-trend / envelopes / cycle-consult で境界解釈が揃う | 高 |
| future variable plan → envelope forecast | `expenses:*` に `budget=...` が付いていれば封筒予測が減る | 高 |
| `plan.tsv` / `journal.tsv` の `budget:*` 行扱い | lint error にするか許可するかを fixture で固定 | 高 |
| forecast layer zero-safe | layer3 未使用でも shape と consumer が壊れない | 中 |
| ledger export memo/meta | `;` memo 変換、6列目以降 metadata を落とす仕様を golden test 化 | 中 |
| docs 同期 test | public field 数・section key と docs の drift を検出 | 中 |

推奨 fixture 名:

- `fixtures/empty-journal`
- `fixtures/cycle-end-exclusive`
- `fixtures/envelope-plan`
- `fixtures/cube-before-start`
- `fixtures/forecast-zero`

## Canonical Daily Cube の設計評価

採用すべき設計。dense day axis と ordinal index による snapshot / trend は筋が良い。

ただし、次の layer contract を code と tests で固定して初めて canonical と呼べる。

| Layer | あるべき意味 | 現状評価 |
|---|---|---|
| actual | `journal.tsv` 由来の現実の動きだけ | 未達だった。`budget_alloc.tsv` が layer0 に混入。 |
| plan | `plan.tsv` 由来の raw planned movement | 概ね達成。ただし consumer が envelope projection と誤解している箇所あり。 |
| budget | `budget_alloc.tsv` + journal 由来の envelope 消費 | 概ね達成。 |
| forecast | 派生ヒューリスティック | 未使用だが zero layer として予約済み。 |

## BQN 学習用に読むべき順番

1. `README.md`
2. `docs/README.md`
3. `docs/ARCHITECTURE.md`（2-layer 記述は古い可能性を意識）
4. `docs/CANONICAL_DAILY_CUBE.md`
5. `docs/CYCLE.md` と `docs/REPORT_DESIGN.md`
6. `core.bqn` の `GetTxUpd` 周辺
7. `report_tx_updates.bqn`
8. `report_engine.bqn`
9. `report_outlook.bqn` → `report_trend.bqn` → `report_cycle_consult.bqn` → `report_envelope_trend.bqn`
10. `report_sections.bqn` と `docs/MAIN_SECTIONS.md` / `docs/REPORT_FIELD_MAP.md`

## 小さな作業タスク案

1タスク = 1目的 = 小さい差分で進める。

| タスク | 変更範囲 | 完了条件 |
|---|---|---|
| Actual layer から budget_alloc を外す | `report_tx_updates.BuildCube` + invariant test | budget_alloc を足しても layer0 の `budget:*` が全ゼロ |
| envelope plan 控除を正す | `report_envelope_trend.bqn` + fixture | future variable expense が `budget=...` 経由で封筒警告に効く |
| `plan.tsv` / `journal.tsv` の `budget:*` 行を lint で明示化 | lint helper + docs | 許可/禁止方針が docs と test で固定 |
| cycle 表示 helper | `cycle.bqn` or helper + renderers | 全表示が `start〜前日` に統一 |
| docs を cube-first に更新 | docs only | `BuildDays` を互換 view と明示 |
| fixtures/basic を現行方針へ寄せる | fixtures/basic + snapshot | fixed cost は封筒外、daily/flex/reserve 中心 |
| empty bootstrap fixture | fixture + `tools/check.sh` | empty journal / future-only plan で envelopes が壊れない |
| docs 同期検査 | small shell/BQN script | fields/section docs drift を自動検出 |

## 作業方針

この repo で BQN・配列・家計管理・複式簿記を学ぶ目的に照らすと、最も価値が高い次の一手は、小さな fixture と invariant test を増やすこと。

大きな実装変更より、まず **「1 取引がどの layer を動かすか」「cycle end_exclusive でどこに入るか」「plan が section ごとにどう効くか」** を 5〜10 行の fixture で見える化する。
