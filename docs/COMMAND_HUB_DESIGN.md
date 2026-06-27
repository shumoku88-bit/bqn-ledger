# Command Hub Design

Status: planning note only / no implementation approved yet  
Date: 2026-06-19

This note describes a possible single entry command for everyday `bqn-ledger` use.
It is separate from the Go source TSV editor design.

## Purpose

The command hub is a doorway into the existing tools.

It should make everyday operations easier to discover and run:

- show reports
- show specific report sections
- add a transaction through the existing input flow
- show plans
- run checks
- open source TSV files in `$EDITOR`
- call exporters
- later, call the future Go source TSV editor

The command hub is not an accounting engine and not a source TSV editor by itself.

## Name

The public command name is not decided yet.

Candidates:

- `bq`
- `bk`
- `bqk`
- `gbk`
- `kakei`
- `ledger`

For now, documents may call it `command hub` or `tools/<name>` until the name is decided.

## Boundary

```text
BQN = scale
Go editor = gloves
command hub = doorway
shell/gum = signboard
```

The command hub may call other tools, but must not reimplement them.

Allowed responsibilities:

- route commands
- show a menu
- pass arguments to existing tools
- keep common commands discoverable
- make daily use more comfortable

Forbidden responsibilities:

- calculate balances
- calculate envelopes
- calculate cycle reports
- parse Canonical Daily Cube
- edit source TSV files by itself
- delete source TSV rows
- implement `plan finish apply`
- merge source-of-truth files into a single event log
- replace the future Go editor

## Source-of-truth policy

The command hub must preserve the current multi-file source-of-truth design.

Current source files remain separate:

```text
journal.tsv
plan.tsv
budget_alloc.tsv
accounts.tsv
cycle.tsv
config.tsv
```

The command hub may feel event-like from the user's point of view, but it must not unify these files into a single `events.tsv` or treat that as the project direction.

## Relationship to Go editor

The command hub and the Go editor are different tracks.

```text
tools/edit
  future Go source TSV editor candidate

command hub
  launcher/menu that may call reports, add-ui, checks, exporters, $EDITOR, and later tools/edit
```

The command hub can exist before the Go editor.
It may call the existing BQN and shell tools first.

## Relationship to gum/fzf

`gum` is a good fit for the command hub.

Initial UI preference:

```text
plain shell command + optional gum menu
```

Possible menu entries:

```text
report
report section
add transaction
plans
checks
edit source TSV
exports
help
```

`fzf` may remain useful for fuzzy selection. `gum` may be enough for everyday menu, table, and confirmation flows.

## Relationship to tview

`tview` remains a later UI candidate, not part of this command hub's first design.

If a TUI is later useful, it should start as a read-only viewer or browser, not as an editor that writes source TSV files.

## Possible command shape

The exact command name is undecided, so examples use `<hub>`.

```sh
<hub>
<hub> report
<hub> report envelopes
<hub> report cashflow
<hub> add
<hub> plan
<hub> check
<hub> edit journal
<hub> edit plan
<hub> export summary
```

Possible routing:

```text
<hub> report
  -> bqn main.bqn

<hub> report <section>
  -> bqn main.bqn --section <section>

<hub> add
  -> tools/add-ui.sh

<hub> plan
  -> current plan view, later tools/edit plan list

<hub> check
  -> tools/check.sh

<hub> edit journal
  -> $EDITOR journal.tsv

<hub> edit plan
  -> $EDITOR plan.tsv
```

## Implementation preference

Initial implementation, if approved later:

- shell script, not Go
- no source TSV mutation by the hub itself
- gum menu optional
- direct subcommands should work without gum
- keep it small enough to understand at a glance

Do not make this the Go editor.
Do not make this a TUI project.
Do not make this an accounting engine.

## Implementation gate

No implementation is approved by this document.

A future approval should say something like:

```text
Approve a shell-only command hub prototype.
No source TSV mutation by the hub itself.
No Go editor implementation.
No TUI.
No event-log unification.
```
