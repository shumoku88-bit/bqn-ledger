# AI Task Packet Template

Status: AI作業効率化テンプレート
Date: 2026-06-22

このテンプレートは、pit に小さな作業を渡すときに、読む文書・触ってよい範囲・非目標・検査コマンドを短く固定するためのものです。

## Template

```text
bqn-ledger の <作業名> を進めてください。

目的:
- <何を達成するか。1〜3行>

読む文書:
- AGENTS.md
- TODO.md
- docs/AI_CODEMAP.md
- <今回の active plan / design doc>
- <変更対象に関係する spec doc>

触ってよいファイル:
- <path>
- <path>

触らないファイル:
- data/journal.tsv
- data/plan.tsv
- data/budget_alloc.tsv
- data/accounts.tsv
- <今回の非対象ファイル>

非目標:
- BuildCube の意味を変えない
- Canonical Daily Cube の shape / Layer 契約を変えない
- source TSV の実データを変更しない
- <今回やらないこと>

実装方針:
- 小さい差分にする
- fixture / test を先に、または同時に追加する
- 不正入力は黙って補正せず error / warning / skipped / unavailable にする
- journal-like TSV の分割では SplitKeepEmpty を使う

確認コマンド:
- <短い対象テスト>
- 可能なら ./checks/check.sh

長い出力になりそうなコマンドは rtk または sqz を前置してください。
変更後に rtk git diff でセルフレビューしてください。
```

## Example: BQN failure fixture

```text
bqn-ledger の canonical engine hardening を進めてください。

目的:
- budget mapping 欠落時に、きれいな間違いを出さず failure fixture で検出する。

読む文書:
- AGENTS.md
- TODO.md
- docs/AI_CODEMAP.md
- docs/CANONICAL_ENGINE_HARDENING_TODO.md
- docs/SAFETY_PROFILE.md
- docs/BQN_CONVENTIONS_FOR_AI.md

触ってよいファイル:
- fixtures/<new-fixture>/
- checks/<関連check>
- tests/test_*.bqn
- docs/CANONICAL_ENGINE_HARDENING_TODO.md

触らないファイル:
- data/journal.tsv
- data/plan.tsv
- data/budget_alloc.tsv
- data/accounts.tsv

非目標:
- BuildCube の意味を変えない
- 封筒計算式を変更しない
- 実データを修正しない

確認コマンド:
- rtk ./checks/check.sh
- 必要なら該当 fixture の個別 check
```

## Example: docs-only design task

```text
bqn-ledger の AI作業効率化 docs-only タスクを進めてください。

目的:
- pit が同じ失敗を繰り返さないよう、既存 docs に短い入口を追加する。

読む文書:
- AGENTS.md
- TODO.md
- docs/README.md
- docs/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md

触ってよいファイル:
- docs/<new-doc>.md
- docs/README.md
- TODO.md

触らないファイル:
- data/*.tsv
- src/**/*.bqn
- editor/**

非目標:
- 実装しない
- source TSV を編集しない
- Go editor / Zig TUI の仕様を勝手に決めない

確認コマンド:
- rtk git diff
```
