# AI Working Feedback Classification Review — 2026-07-04

Status: review snapshot / no implementation authorization

この文書は、AI 作業品質・トークン効率・デバッグ効率・安全性に関する既存の提案と active feedback を、根本原因の層で仕分けした review snapshot です。

**この文書は実装計画ではありません。**

- classification item は implementation backlog ではありません。
- priority signal は承認済み TODO ではありません。
- 実装は、別途作成された approved plan からのみ開始します。

Process:

- `docs/AI_WORKING_FEEDBACK_PROCESS.md`

Sources reviewed:

- `docs/archive/completed-plans/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md`
- `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md`
- `AGENTS.md`
- `docs/AI_CODEMAP.md`

## Classification layers

| Code | Layer | 判断基準 |
|---|---|---|
| A | Tool / Environment | 観測、実行、検索、圧縮、デバッグの道具や実行環境が不足している |
| B | Coding / Implementation | 言語固有の罠、局所的なコード記法、実装パターンに問題がある |
| C | Architecture / Design | 責務、契約、SSOT、データ表現、副作用境界、設定意味論に問題がある |
| D | Verification / Test | test、lint、CI、negative path、drift detection、assertion ownership に問題がある |
| E | Workflow / Information Architecture | 作業順序、handoff、docs導線、監査方法、context persistence に問題がある |

## Classification table

| ID | Item | Primary | Secondary | Root cause hypothesis | Local fix | Systemic fix | Toolify? |
|---|---|---|---|---|---|---|---|
| 1 | Output Squeezer | A | E | 巨大出力に対する狭い観測経路がない | section/key 抽出 | machine-readable query surface を安定化 | yes |
| 2 | BQN REPL / Variable Dumper | A | B | 実行時の値・型・shape 観測能力が弱い | eval/dump helper | デバッグ可能な観測境界を標準化 | yes |
| 3 | TSV Alignment Linter | D | C | TSV 間契約が人間の目視に依存 | 静的 lint | cross-file invariants を明文化 | yes |
| 4 | Structured TSV Patch Applier | C | A | edit intent、validation、write 責務が曖昧 | structured patch interface | write boundary / Operation IR を正本化 | maybe |
| 5 | Golden Diff Summary | A | D | test failure 出力が AI 文脈に対して過大 | diff 圧縮 | failure output contract を標準化 | yes |
| 6 | Context Unload / Task-focused Subagents | A | E | 長時間会話に探索文脈が蓄積 | subagent 分離 | task-scoped context policy | yes |
| 7 | Fail-safe Path 自動検証 | D | C | happy path のみが検証され error route が無保証 | negative tests | failure semantics を契約化 | no |
| 8 | System Defaults SSOT | C | E | 既定値が複数言語・複数ファイルへ分散 | defaults 集約 | single source of truth 維持 | no |
| 9 | Docs / Code Drift Linter | D | C | docs と実装が独立して変化 | dead-link/path check | current contract から派生検証 | yes |
| 10 | BQN Homogenization 型揺らぎ | B | C | collection element shape 契約が暗黙 | Enclose/Disclose 規約 | representation contract 明示 | no |
| 11 | `git diff` Self-review | E | A | 全体再読で変更文脈が埋没 | diff 中心レビュー | pre-test/pre-commit routine | no |
| 12 | Docs 更新漏れ即時検知 | D | C | code field contract と docs が二重管理 | drift lint | ownership 削減・生成可能性検討 | maybe |
| 13 | Check Scaffolder | A | C | test boilerplate 重複 | generator | 共通 test harness を先に検討 | maybe |
| 14 | Fragile Test 防止 | D | C | human-readable message を API 契約扱い | assertion 緩和 | structured error code 契約 | no |
| 15 | Impact Summary | A | D | 変更影響を見る狭い比較面がない | changed-key summary | stable machine-readable snapshot comparison | yes |
| 16 | `git mv` 優先 | E | A | rename intent が履歴上不明瞭になる | git mv rule | move/rename workflow 標準化 | no |
| 17 | No-Mutation Assertions | C | D | 副作用禁止境界が暗黙 | checksum test | no-mutation contract | no |
| 18 | Migration / Handoff Template | E | C | scope・非目標・境界を毎回再推論 | plan template | migration contract 標準化 | no |
| 19 | Audit → Drift Table → Fix Plan | E | C | 発見と修正を同時化し文脈が膨張 | 3段階運用 | audit workflow 標準化 | no |
| 20 | 存在しない Guard | C | E | safety claim と実体 check の対応がない | historical status 明示 | guard registry / evidence linkage | maybe |
| 21 | Command Wrapper 実測 | A | E | docs 上の tool capability と実環境が不一致 | baseline 実行確認 | environment capability record | maybe |
| 22 | Soft-gated Tests | C | D | 「pass」の意味が曖昧 | `|| true` 除去または明示 | CI gating semantics 契約 | no |
| 23 | Historical Docs Status Note | E | C | current knowledge と historical knowledge が混線 | status note 追加 | current reading path 設計 | no |
| 24 | Follow-up TODO | E | C | 会話終端で残作業が自然文に蒸発 | follow-up doc | context persistence 標準化 | no |
| A1 | Archive move link validation | D | E | docs 移動後の相対リンク整合性が手作業 | link checker | archive link policy 定義 | yes |
| A2 | BQN precedence / function role gotchas | B | E | 言語固有評価規則が作業者記憶依存 | gotcha guide | safe idiom 集 | no |
| A3 | BQN `⎊` outer-scope catch | B | C | error boundary 内部が外部 lexical state 依存 | `𝕩` 使用規約 | catch-safe function pattern | no |
| A4 | Partial `config.tsv` | C | D | config が snapshot か override か不明確 | full config fixture | merge/replace semantics 明文化・実装 | no |
| A5 | Golden + exact grep 重複 | D | C | 同一期待値を複数 test surface が所有 | duplicate assertion 削除 | assertion ownership policy | no |

## Cross-cutting root-cause clusters

### 1. Contract ownership duplication

Examples:

- golden file と exact `grep`
- code field と docs count
- error message と test assertion

Signal:

同じ意味を複数場所が所有し、変更時に同期漏れが起きる。

Review principle:

> 一つの期待値には、一つの主所有者を決める。

### 2. Semantic ambiguity

Examples:

- partial config は override か complete snapshot か
- test pass は本当に gating success か
- historical docs は current spec か

Signal:

AI が探索で意味を推測する。

Review principle:

> 推測させる前に意味を固定できないか確認する。

### 3. Observation surface shortage

Examples:

- full report しかない
- BQN local value が見えない
- impact だけ見たいのに full diff しかない

Signal:

小さい質問に巨大な入力が必要。

Review principle:

> narrow question には narrow output を用意する。

### 4. Safety claim / executable evidence separation

Examples:

- 存在しない guard
- soft-gated tests
- no-mutation 保証

Signal:

「安全」と書いてあるが current tree で証明できない。

Review principle:

> safety claim は current executable evidence へ接続する。

### 5. Language-specific knowledge not fixed

Examples:

- BQN homogenization
- precedence
- function naming role
- `⎊` scope

Signal:

各 AI が同じ罠を再発見する。

Review principle:

> 一度踏んだ言語罠は、次の AI に再発見させない。

### 6. Context persistence shortage

Examples:

- follow-up TODO
- migration handoff
- audit 三段階
- historical/current reading path

Signal:

次のセッションが、何が終わり、何が残り、何を触るな、を再構成する。

Review principle:

> 会話の終端を次の作業の入口へ変換する。

## Planning signals only

以下は **approved plan ではありません**。次回 Planning stage で検討するための signal です。

### Strong architecture/design signals

- A4 Partial `config.tsv` semantics
- 22 Soft-gated test semantics
- A5 Assertion ownership duplication
- 20 Guard claim / evidence linkage

### Strong BQN coding/representation signals

- 10 Homogenization / shape contract
- A2 precedence / function role gotchas
- A3 `⎊` catch scope

### Strong observation/tool signals

- 1 narrow report query surface
- 2 BQN eval/dump observation
- 15 impact summary
- A1 archive link validation

### Observe before toolifying

- 4 Structured TSV Patch Applier
- 12 docs update drift helpers
- 13 check scaffolder
- 21 command wrapper handling

Reason:

これらは tool shortage に見えて、責務設計、ownership duplication、environment baseline の問題である可能性がある。

## Review conclusion

既存の AI efficiency proposal は、単一の tooling backlog として扱わない方がよい。

今回の review では、AI のトークン浪費やデバッグ往復の多くが次の構造的 signal と重なっていた。

- 曖昧な意味
- 分散した正本
- 不明確な責務
- 観測面不足
- 重複した契約
- current / historical knowledge の混線
- safety claim と executable evidence の分離

次の段階は、この分類から **選んだ項目だけ** を Planning stage へ移すことです。

この review 自体は実装を許可しません。
