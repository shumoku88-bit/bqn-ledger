# AI Working Feedback Process

Status: current process

この文書は、AI 作業中に見つかった摩擦を、すぐ実装へ直結させず、観察・分類・計画・小さな実装・再観察へ進めるための現行プロセスです。

対象は、作業品質、トークン効率、デバッグ効率、安全性、開発体験に関する気づきです。

## 中核ルール

1. **Feedback entry is not an implementation request.**
2. **Classification is not an implementation backlog.**
3. **Only an approved plan authorizes implementation work.**

日本語では次のように扱います。

- フィードバック記録は実装指示ではない。
- 分類結果はそのまま実装バックログではない。
- 実装は、分類後に選ばれた承認済み計画からのみ開始する。

AI は intake log や classification review を読んだだけで、未承認の改善案を勝手に実装してはいけません。

## 全体フロー

```text
実作業
  ↓
1. Intake
  ↓
2. Classification / Triage
  ↓
3. Planning
  ↓
4. Execution
  ↓
5. Review / Learning
  └──────────────→ Intake
```

## Stage 1: Intake

正本入口:

- `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md`

目的:

- 実作業中に見つかった摩擦を失わない。
- まだ根本原因を断定しない。
- まだ実装を始めない。

記録するもの:

- Context
- Friction
- Idea
- Candidate type
- Related tool/doc

`Idea` は仮説であり、採用案ではありません。

## Stage 2: Classification / Triage

分類レビューは、日付付き review snapshot として次へ置きます。

```text
docs/archive/audits/AI_WORKING_FEEDBACK_CLASSIFICATION-YYYY-MM-DD.md
```

分類レビューでは、intake log と過去の提案文書を読み、各項目を主に次の5層へ分けます。

| Code | Layer | 判断基準 |
|---|---|---|
| A | Tool / Environment | 観測、実行、検索、圧縮、デバッグの道具や実行環境が不足している |
| B | Coding / Implementation | 言語固有の罠、局所的なコード記法、実装パターンに問題がある |
| C | Architecture / Design | 責務、契約、SSOT、データ表現、副作用境界、設定意味論に問題がある |
| D | Verification / Test | test、lint、CI、negative path、drift detection、assertion ownership に問題がある |
| E | Workflow / Information Architecture | 作業順序、handoff、docs導線、監査方法、context persistence に問題がある |

必要に応じて Primary / Secondary を分けます。

分類時には最低限、次を考えます。

- Symptom
- Primary cause layer
- Secondary cause layer
- Root cause hypothesis
- Local fix
- Systemic fix
- Toolify? yes / maybe / no

### 分類時の確認順

1. これは単に観測できないだけか。
2. 言語固有の安全な書き方で防げるか。
3. 契約、責務、正本、設定意味論が曖昧ではないか。
4. 機械検証すべき invariant ではないか。
5. AI の作業順序や情報導線の問題ではないか。
6. それでも残る反復摩擦か。

6 まで残った場合に、初めて新ツールを強く検討します。

## Stage 3: Planning

Classification review から、実際に進める項目だけを選びます。

計画は次のどちらかに置きます。

```text
docs/archive/active-plans/AI_WORKING_IMPROVEMENT_PLAN-YYYY-MM-DD.md
```

または、対象が十分に独立している場合は専用 active plan を作ります。

計画には最低限、次を含めます。

- 対象・目的・現在地
- 採用する classification item
- 非目標
- 触る可能性があるファイル
- 触ってはいけないファイル
- acceptance criteria
- 推奨 checks
- handoff 案

分類表の全項目を自動的に計画へ移してはいけません。

## Stage 4: Execution

承認済み plan からのみ実装を開始します。

既存の bqn-ledger 作業原則を守ります。

- 1目的ずつ
- 小さい差分
- 正データ保護
- fail closed
- 必要な test / check
- 実装前に責務所有者を決める

実装途中で新しい摩擦が見つかった場合、その場で別改善を始めず、必要なら Intake へ戻します。

## Stage 5: Review / Learning

実装後は、元の friction に対して結果を確認します。

推奨 status:

- `resolved`
- `mitigated`
- `observe-more`
- `rejected`
- `superseded`

確認すること:

- 本当にトークン消費や往復が減ったか。
- 新しい摩擦を生んでいないか。
- 根本原因仮説は正しかったか。
- 新しい helper / rule / check が別の二重正本を作っていないか。

必要なら結果を再び Intake へ戻します。

## Toolification gate

新しい helper、wrapper、lint、scaffolder、devtool を作る前に、次を確認します。

- 既存ツールで代替できないか。
- コードの安全な書き方で防げないか。
- 設計契約を明確にすれば消える問題ではないか。
- test ownership の重複ではないか。
- workflow の問題ではないか。
- 十分に頻出するか。

ツール化は改善の既定値ではありません。

## Review trigger

Classification review は毎回必須ではありません。

次の場合に行います。

- feedback がある程度溜まった。
- 同種の friction が繰り返された。
- moko が review を依頼した。
- 大きな改善計画を作る前。
- 既存の AI efficiency proposal を再評価する時。

## Current related documents

- Intake: `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md`
- Historical proposal set: `docs/archive/completed-plans/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md`
- First classification snapshot: `docs/archive/audits/AI_WORKING_FEEDBACK_CLASSIFICATION-2026-07-04.md`

## Non-goals

- feedback ごとに即 issue / PR を作らない。
- すべての friction をツール化しない。
- classification review を TODO として扱わない。
- process のために大量の管理文書を増やさない。
- AI に autonomous improvement mandate を与えない。
