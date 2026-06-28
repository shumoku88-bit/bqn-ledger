# AI Review Task: tools/bqn-eval

Status: review request / AI development efficiency cycle
Date: 2026-06-22

Use this packet to ask an AI agent to try `tools/bqn-eval`, review its usability, and propose the next small improvement.

## Task

```text
bqn-ledger の `tools/bqn-eval` Phase 1 をレビューしてください。

目的:
- `tools/bqn-eval` が、小さいBQN式の確認に使えるかを確認する。
- AI作業精度・トークン効率の観点で、使いにくい点を短く指摘する。
- 改善する場合は、Phase 1 の境界を守る小さい差分だけ提案する。

読む文書:
- AGENTS.md
- TODO.md
- docs/AI_CODEMAP.md
- docs/DECISION_AI_DEVELOPMENT_EFFICIENCY_PROPOSALS.md
- docs/BQN_REPL_AND_DUMPER_DESIGN.md
- docs/BQN_CONVENTIONS_FOR_AI.md

触ってよいファイル:
- tools/bqn-eval
- checks/check-negative.sh
- docs/BQN_REPL_AND_DUMPER_DESIGN.md
- docs/AI_REVIEW_BQN_EVAL_TASK.md
- TODO.md

触らないファイル:
- data/journal.tsv
- data/plan.tsv
- data/budget_alloc.tsv
- data/accounts.tsv
- data/*.tsv
- src/reports/**
- src/core/**
- editor/**

非目標:
- repo module loading を実装しない。
- TSV loading を実装しない。
- source TSV を編集しない。
- report engine の挙動を変えない。
- `tools/bqn-probe` / `tools/bqn-dump` をまだ作らない。
- JSON出力を急いで実装しない。必要なら提案だけにする。

確認コマンド:
- bash ./tools/bqn-eval '≢ "OK"'
- bash ./tools/bqn-eval '<"OK"'
- bash ./tools/bqn-eval '⟨<"OK", <"WARN"⟩'
- bash ./tools/bqn-eval --format raw '≢ "OK"'
- bash ./tools/bqn-eval --format json '1+1'  # fail expected
- bash ./checks/check-negative.sh
- rtk git diff

レビュー観点:
- AIがコピペしやすいか。
- エラー文言が短く、次の行動がわかるか。
- 実行ビットがない環境でも `bash ./tools/bqn-eval` で使えるか。
- `--format text|raw` の扱いが十分か。
- stdin入力が便利か、危険でないか。
- Phase 1 の境界（no repo module loading / no TSV loading / no source writes）が守られているか。

出力してほしいもの:
- 使ってみた結果の短い要約。
- 改善が必要な点があれば最大3個。
- すぐ直すべきものと、Phase 2以降に送るものの分離。
- 変更した場合は差分の説明。
```

## Human note

This task is intentionally small. The point is not to build a full REPL. The point is to start a cycle:

```text
make tiny tool -> let AI use it -> collect review -> improve tiny tool
```

Keep the loop small enough that mistakes are easy to see.
