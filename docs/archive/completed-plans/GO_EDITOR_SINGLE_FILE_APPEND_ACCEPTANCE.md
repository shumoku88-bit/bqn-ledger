# Go Editor: Single-file Append Acceptance Criteria

Status: `journal add`, `budget add`, and `plan finish --apply` safe append implemented
Date: 2026-06-20

This document defines the next Go editor phase after the read-only `plan list` / `plan finish` preview implementation.

The goal is to make source TSV writes boring, inspectable, recoverable, and delegated to BQN for final validation.

```text
BQN = scale
Go  = gloves
```

Go may touch source TSV files only as a safe editor. It must not become a second accounting engine.

---

## 1. Phase scope

### Initial write target

The write-capable commands are limited to single-file append:

```sh
tools/edit journal add ...
tools/edit budget add ...
tools/edit plan finish ... --apply
```

`budget add` writes only `budget_alloc.tsv`. `plan finish --apply` behaves as a safe append to `journal.tsv` using the same infrastructure (as we do not delete plan rows from `plan.tsv`, dynamic closed status is resolved using `plan_id` existence in `journal.tsv`).

### Explicitly out of scope

Do not implement in this phase:

- any two-file updates (e.g. modifying `plan.tsv` and `journal.tsv` at the same time)
- deletion of source TSV rows
- in-place row editing
- account creation
- cycle/config mutation
- operation-log-based regeneration
- balance / envelope / cycle / residual calculation in Go
- TUI editing

---

## 2. CLI contract

Candidate shapes:

```sh
tools/edit journal add \
  --date 2026-06-19 \
  --memo コンビニ \
  --from assets:cash \
  --to expenses:food \
  --amount 500 \
  --meta receipt=yes

tools/edit budget add \
  --date 2026-06-19 \
  --memo alloc \
  --from budget:unassigned \
  --to budget:daily \
  --amount 1000
```

Required global behavior:

```sh
tools/edit --base <dir> journal add ...
```

Required modes:

```text
(default)  preview + confirm, then write if confirmed
--dry-run  preview only, no write
--yes      preview is still printed, but confirmation prompt is skipped
```

The default must never silently write without showing the exact TSV line that will be appended.

---

## 3. Input validation before preview

Go should reject obvious structural mistakes before any write attempt:

- date must be strict `YYYY-MM-DD`
- amount must be an integer string
- `from` account must exist in `accounts.tsv`
- `to` account must exist in `accounts.tsv`
- metadata tokens must be `key=value`
- metadata key must be non-empty and limited to the existing key character policy
- metadata value must not contain TAB or newline
- first five journal-like fields must not contain TAB or newline

Go must not decide accounting semantics beyond this light structural validation.

BQN remains responsible for canonical validation and accounting invariants.

---

## 4. TSV append contract

When appending to `journal.tsv` or `budget_alloc.tsv`, Go must preserve the existing file as much as possible.

Required behavior:

- read the existing file completely
- preserve all existing bytes except the append boundary
- preserve comments, blank lines, ordering, and empty fields
- append exactly one journal-like TSV row
- ensure the resulting file ends with a newline
- if the original file does not end with a newline, insert one before the appended row
- do not rewrite or normalize existing rows

The appended row format is journal-like:

```tsv
date<TAB>memo<TAB>from<TAB>to<TAB>amount<TAB>meta...
```

If no metadata is supplied, the row has exactly five fields.

---

## 5. Preview / confirm contract

Before writing, Go must print:

- target file path
- mode (`dry-run`, `confirm`, or `yes`)
- exact TSV row to append
- post-write check mode
- backup destination that will be used, if writing

`--dry-run` output must be stable enough for fixture tests.

Default confirmation accepts only an explicit affirmative answer such as `y` or `yes`. Empty input must cancel.

---

## 6. Backup contract

Backups are stored under the dataset base directory:

```text
<base>/.backup/YYYYMMDD-HHMMSS/<filename>
```

For this phase:

- backup must be created before replacement
- backup must contain the original file bytes
- backup directory creation failure must abort the write
- backup path must be printed in the preview/confirmation output
- restore instructions must be printed on post-write check failure

This phase does not require multi-file operation logs.

---

## 7. Stale check contract

Go must refuse to write if the file changed between read and replacement.

At minimum, stale check compares:

- path
- size
- modtime and/or content hash
- SHA-256 content hash before replacement

If stale, Go must:

- abort without writing
- leave the source file unchanged
- print a clear error explaining that the file changed during editing

---

## 8. Atomic write contract

The write sequence for a single file is:

1. read source file and record identity/hash
2. build proposed content in memory
3. print preview
4. confirm unless `--yes`
5. create backup
6. re-check stale source file
7. write temporary file in the same directory
8. preserve file permissions as much as practical
9. fsync temp file if supported/practical
10. rename temp file over the source file
11. run post-write check

Failure before rename must leave the source file unchanged.

Failure after rename must leave a backup and clear recovery instructions.

---

## 9. Post-write check default

Default post-write check:

```text
lint
```

Candidate CLI:

```text
--post-check lint   # default
--post-check none
--post-check full
```

Meaning:

- `lint`: run the BQN lint command for the target base directory
- `none`: skip post-write check
- `full`: run the heavier project check script, only when explicitly requested

If post-write check fails, Go must not auto-rollback in this phase. It should print:

- failure command
- backup path
- source path
- manual restore command suggestion

---

## 10. Test requirements before implementation is accepted

All mutation tests must use temporary directories copied from fixtures. Tests must never mutate real source TSV files.

Required tests:

### Dry-run / preview

- `journal add --dry-run` does not mutate `journal.tsv`
- preview contains exact TSV row
- preview shows target path and post-check mode

### Validation

- invalid date is rejected
- non-integer amount is rejected
- unknown from/to account is rejected
- invalid metadata token is rejected
- TAB/newline inside fields is rejected

### Append result

- appending to file with trailing newline produces expected content
- appending to file without trailing newline inserts exactly one boundary newline
- appending with empty memo preserves the empty second field
- append with no metadata produces exactly five fields
- append with metadata preserves metadata order
- existing comments / blank lines / rows are unchanged

### Backup / atomicity

- backup is created before replacement
- backup content equals original content
- temp file is not left behind on successful write
- simulated failure before rename leaves source unchanged

### Stale check

- if file changes after read but before write, write is refused
- stale refusal leaves source unchanged and does not append duplicate rows

### Post-write check

- default mode invokes BQN lint command or injectable test runner equivalent
- `--post-check none` skips it
- check failure reports backup and restore instructions

---

## 11. Implementation gate

This phase was implemented for `journal add`, `budget add`, and `plan finish --apply` after moko approval. Any broader write-capable phase still requires a new explicit approval like:

```text
Approve Go editor <next write command> only.
Default post-check lint.
Backup under .backup/.
Default preview + confirm.
No deletion.
No TUI.
```

Until then, this document is an acceptance contract, not permission to implement write behavior.

