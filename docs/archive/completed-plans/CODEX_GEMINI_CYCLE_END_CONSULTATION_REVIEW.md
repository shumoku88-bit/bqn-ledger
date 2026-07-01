# Codex / Gemini Instruction: Cycle-end Consultation Review

Status: handoff instruction / review-only by default
Date: 2026-06-22

Use this instruction when asking Codex, Gemini, or another AI coding agent to review the cycle-end consultation setup.

Default mode is review-only. Do not change files unless the human explicitly asks for a docs-only patch after review.

## Copy-paste instruction

```text
bqn-ledger の cycle-end envelope consultation setup をレビューしてください。

目的:
- `docs/CYCLE_END_ENVELOPE_CONSULTATION_TASK.md` が、AI consultant に渡す手動相談パケットとして使えるか確認する。
- 次サイクルの Daily / flex / reserve 配賦相談に必要な入力材料が足りているか確認する。
- plan.tsv に書かれていない actual 支出のペース・タイミング・余白を見る方針が、文書上で安全に表現されているか確認する。
- 警戒・リスク・使いすぎ・削るべき等の意味づけ語が混ざっていないか確認する。

読む文書:
- AGENTS.md
- TODO.md
- docs/README.md
- docs/EXTERNAL_REASONING_BOUNDARY.md
- docs/EXTERNAL_REASONING_NEUTRAL_LANGUAGE_POLICY.md
- docs/CYCLE_END_ENVELOPE_CONSULTATION_TASK.md
- docs/SAFETY_PROFILE.md
- docs/PLAN.md
- docs/CYCLE.md
- docs/archive/completed-plans/ACTUAL_COMPARISON_REPORT_PLAN.md

触ってよいファイル:
- なし。まずはレビューのみ。

触らないファイル:
- data/journal.tsv
- data/plan.tsv
- data/budget_alloc.tsv
- data/accounts.tsv
- data/*.tsv
- src/**
- editor/**
- tools/**

非目標:
- 実装しない。
- BQN export を追加しない。
- source TSV を編集しない。
- budget_alloc.tsv を更新しない。
- BQN の正本値を再計算しない。
- consultant automation を作らない。
- plan外 actual 支出を悪い支出として扱わない。
- `警戒`, `リスク`, `使いすぎ`, `削るべき`, `失敗` などの意味づけ語を使わない。

レビュー観点:
1. 境界:
   - BQN が canonical number engine のままか。
   - 外部推論が observation / suggestion / proposal に留まっているか。
   - `do_not_apply_automatically: true` が十分に強調されているか。

2. 入力材料:
   - 手動相談に必要なBQN出力が何か、十分に明確か。
   - current cycle / next cycle / envelope balances / food actual / tobacco actual / actual-comparison / section status の扱いが明確か。
   - まだ足りないBQN export があるなら、それを実装せず「不足候補」として列挙できるか。

3. plan外 actual:
   - `plan.tsv spending = known / already noticed spending` の前提が守られているか。
   - `unplanned actual spending = living rhythm` として扱われているか。
   - planned spending と unplanned pace signal が混ざっていないか。

4. 中立語彙:
   - ペース / リズム / タイミング / 余白 / 確認候補 / 見直し候補 / 変化 の語彙に寄っているか。
   - 警戒・リスク・使いすぎ・削るべき・失敗などの語が残っていないか。
   - BQN の `WARN` / `UNAVAILABLE` を生活判断に変換していないか。

5. 実用性:
   - 人間がBQN出力を貼ってすぐ使えるか。
   - 出力形式がレビューしやすいか。
   - 次に試すなら manual consultation で足りるか、先に compact input bundle が必要か。

出力してほしいもの:
- 全体評価: 3〜7行。
- 良い点: 最大5個。
- 曖昧または不足している点: 最大5個。
- すぐ直すなら docs-only で直すべき点: 最大3個。
- 実装に進む前に試すべき manual consultation の手順案。
- まだ実装しない方がよいこと。

禁止:
- ファイル変更をしない。
- patch を直接当てない。
- source TSV を読んで編集しない。
- 実装コードを変更しない。
```

## Optional second instruction after review

Only use this if the human approves a docs-only cleanup after reading the review.

```text
上のレビュー結果をもとに docs-only cleanup をしてください。

触ってよいファイル:
- docs/CYCLE_END_ENVELOPE_CONSULTATION_TASK.md
- docs/EXTERNAL_REASONING_BOUNDARY.md
- docs/EXTERNAL_REASONING_NEUTRAL_LANGUAGE_POLICY.md
- TODO.md
- docs/README.md

触らないファイル:
- data/*.tsv
- src/**
- editor/**
- tools/**

非目標:
- 実装しない。
- BQN export を追加しない。
- source TSV を変更しない。
- budget_alloc.tsv を変更しない。

変更方針:
- 意味づけ語を中立語彙へ直す。
- manual consultation に必要な入力材料を明確にする。
- planned spending と unplanned actual pace signal を混ぜない。
- 変更後に `rtk git diff` でセルフレビューする。
```

## Human note

This is intentionally not an implementation task.

The desired loop is:

```text
review the packet -> try one manual consultation -> identify missing inputs -> decide whether an export is needed
```

Do not jump directly to automation.
