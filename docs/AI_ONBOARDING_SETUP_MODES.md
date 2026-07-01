# AI onboarding setup modes

Status: draft / discussion-only / docs-only

This document sketches how a new user could start using bqn-ledger with help from the AI service they already use, such as Codex, Claude Code, Gemini CLI, or another terminal-based coding assistant.

The goal is not to make bqn-ledger fully automatic. The goal is to make the first usable ledger possible for a beginner while preserving the core rule that canonical data must be handled deliberately.

## Core idea

A beginner should be able to open a terminal, start their AI assistant, and say something like:

```text
bqn-ledger の初期セットアップをしたいです。
このリポジトリの docs/AI_ONBOARDING_SETUP_MODES.md を読んで、質問しながら進めてください。
```

The AI assistant should then ask questions, create the initial TSV files, summarize the result, and ask for confirmation before setup is considered complete.

After setup is complete, the AI assistant must switch to a more restrictive daily-use mode.

## Beginner terminal entry sketch

For a Mac beginner, the onboarding document may eventually say something like:

```text
1. Start the Mac.
2. Press Command + Space.
3. Type: terminal
4. Press Enter.
5. In Terminal, type the command for the AI service you use, for example:
   codex
   claude
   gemini
   agy
6. Press Enter.
7. Tell the AI:
   bqn-ledger の初期セットアップをしたいです。
```

This is only a sketch. It should not be treated as finished installation documentation yet.

## Modes

### 1. Initial setup mode

Initial setup mode is active before the first usable ledger exists.

In this mode, the AI assistant may create and edit the initial canonical TSV files, because a beginner may not yet know how to create them by hand.

Expected files may include:

```text
data/accounts.tsv
data/journal.tsv
data/cycle.tsv
data/plan.tsv
data/budget_alloc.tsv
```

The AI assistant should ask for at least:

- setup start date
- managed accounts
- opening balances
- next income date or cycle boundary
- whether cash is managed
- whether planned payments should be entered now
- whether envelope/budget management should be skipped for now

At the end of initial setup, the AI assistant must summarize the generated files and ask:

```text
この内容で bqn-ledger を開始してよいですか？
```

Only after user confirmation should setup be considered complete.

### 2. Daily-use mode

Daily-use mode is active after initial setup is complete.

In daily-use mode, the AI assistant may read files, explain reports, answer questions, and propose edits.

The AI assistant must not edit canonical TSV files unless the user gives an explicit edit instruction.

Examples of questions that do not grant edit permission:

```text
今日のお金の状況を見て。
次の収入日まで持ちそう？
食費を使いすぎてる？
今期の予算をどうしたらいい？
```

Examples of explicit edit instructions:

```text
journal.tsv に今日の支出を追記して。
plan.tsv のこの予定を完了扱いにして。
accounts.tsv に新しい支出カテゴリを追加して。
budget_alloc.tsv をこの内容で更新して。
```

### 3. Plan setup mode

A user may not understand planned payments during initial setup.

Plan setup mode is a later guided mode for creating or revising `plan.tsv`.

This mode may be entered when the user says something like:

```text
予定管理を始めたい。
固定費の予定を bqn-ledger に入れたい。
plan.tsv の使い方を一緒に整理したい。
```

`plan.tsv` is important, but it is less dangerous than `journal.tsv`: it describes expectations, not historical evidence.

The AI assistant may help more actively here, but should still summarize changes before applying them when the user is unsure.

### 4. Budget / envelope setup mode

A user may not want envelope budgeting from day one.

Budget / envelope setup mode is a later guided mode for creating or revising budget-related data such as `budget_alloc.tsv` and account metadata used for budget grouping.

This mode may be entered when the user says something like:

```text
封筒予算管理を始めたい。
食費だけ予算管理したい。
今期の budget_alloc.tsv を一緒に作りたい。
```

Budget data is allowed to be experimental. If it is wrong, the reports may be unhelpful, but the historical journal is still intact.

### 5. Repair / review mode

Repair / review mode is for investigating inconsistent or confusing output.

The AI assistant should first inspect reports and TSV files without editing. It should identify whether the issue is in journal data, account metadata, plan data, budget data, or report interpretation.

Editing rules remain governed by file protection levels and explicit user instructions.

## File protection levels

Not all TSV files have the same weight.

### Strongly protected

```text
data/journal.tsv
```

`journal.tsv` is historical evidence. It records what actually happened. It must not be edited without an explicit user instruction.

Edits to `journal.tsv` should normally be append-only. If correction is needed, prefer an explicit correction entry or a clearly explained targeted edit.

### Protected

```text
data/accounts.tsv
data/cycle.tsv
```

These files shape interpretation. They may be edited with explicit user instruction, but the AI assistant should explain expected report impact before destructive changes such as renaming or removing accounts.

### Flexible / experimental

```text
data/plan.tsv
data/budget_alloc.tsv
```

These files describe expectations and budget plans. They are important for reports, but if they break, the historical journal is still preserved.

The AI assistant may provide more active setup help here, especially inside plan setup mode or budget / envelope setup mode.

## Draft setup-complete marker idea

A future implementation may create a small marker after initial setup, for example:

```text
data/.setup-complete
```

or

```text
data/SETUP_STATE.tsv
```

The marker would tell AI assistants and tooling that initial setup mode is over and daily-use mode should apply.

This is only a design idea. No implementation is specified by this draft.

## Non-goals for this draft

- Do not implement a setup wizard yet.
- Do not change current report behavior.
- Do not change canonical TSV formats yet.
- Do not make AI edits impossible.
- Do not let AI edit canonical files silently.

## Open questions

- What exact phrase should mark explicit edit permission?
- Should initial setup write directly to `data/`, or write to `setup-draft/` first?
- Should `journal.tsv` corrections be append-only by policy?
- Should plan and budget setup modes require confirmation before every write?
- What should be the smallest beginner-friendly initial setup?
- How should non-Mac users be guided?

## Merge readiness checklist

This PR should not be merged until the onboarding policy is clearer.

- [ ] Initial setup mode is defined clearly enough for an AI assistant.
- [ ] Daily-use edit rules are unambiguous.
- [ ] `journal.tsv` protection level is agreed.
- [ ] `plan.tsv` setup mode is described.
- [ ] Budget / envelope setup mode is described.
- [ ] Beginner terminal entry is written carefully.
- [ ] AI prompt examples are tested conversationally.
- [ ] Merge readiness is reviewed separately.
