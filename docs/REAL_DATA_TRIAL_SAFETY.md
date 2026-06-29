# Real Data Trial Safety Guide

Status: current operational guide
Date: 2026-06-30

## Purpose

This guide defines a small trial workflow for using `bqn-ledger` with real household data without widening the write surface.

The goal is not to prove that real-data operation is permanently safe. The goal is to run a narrow, observable trial, check the safety path before each write, and record whether any operation problem appears during daily use.

## Scope

This guide covers:

- confirming the effective real data directory before operation
- using sandbox data before real data
- keeping AI-assisted work read-only or dry-run only
- doing the first real write through the existing confirmation path
- recording observations after each write

This guide does not change TSV schema, report calculation, `tools/edit-bqn`, safe-write behavior, or source data files.

## Hard rule for AI-assisted operation

AI / pit may help by reading docs, proposing commands, and preparing dry-run examples.

AI / pit must not run commands that write source TSV during the trial.

Allowed AI-assisted commands:

```sh
tools/doctor
tools/report
tools/add-ui.sh --check
tools/edit ... --dry-run
tools/edit plan finish ...
```

Notes:

- `tools/edit plan finish ...` without `--apply` is preview-only by design.
- `tools/edit plan finish ... --apply` is a write command and is not AI-allowed during the trial.
- `tools/add-ui.sh` without `--check` may lead to writes and is not AI-allowed during the trial.

Forbidden AI-assisted commands:

```sh
tools/edit ... --yes
tools/edit plan finish ... --apply
tools/add-ui.sh
sed -i ... <base>/*.tsv
echo ... >> <base>/*.tsv
python/perl/ruby/go scripts that rewrite <base>/*.tsv
```

AI may prepare an edit proposal for human review, but the human performs the final write locally.

## Phase 0: sandbox rehearsal

Before touching real data, run one sandbox rehearsal.

```sh
tools/doctor
tools/report fixtures/src-next-golden
tools/add-ui.sh --check
```

Then try one dry-run or fixture write against a copied sandbox directory.

```sh
mkdir -p sandbox/real-data-trial
cp fixtures/src-next-golden/*.tsv sandbox/real-data-trial/

tools/edit --base sandbox/real-data-trial journal add \
  --date 2026-06-30 \
  --memo "trial" \
  --from assets:cash \
  --to expenses:food \
  --amount 100 \
  --dry-run
```

Only continue if the target path, proposed row, and no-write behavior are understandable.

## Phase 1: real data preflight

For daily use, prefer an absolute `LEDGER_DATA_DIR`.

```sh
echo "$LEDGER_DATA_DIR"
case "$LEDGER_DATA_DIR" in
  /*) echo "OK: absolute LEDGER_DATA_DIR" ;;
  *) echo "STOP: LEDGER_DATA_DIR is not absolute" ; exit 1 ;;
esac

tools/doctor
tools/report
tools/add-ui.sh --check
```

Expected result:

- `tools/doctor` shows the intended real data directory.
- required TSV files are present.
- `tools/report` produces the expected report.
- `tools/add-ui.sh --check` completes without writing.

Stop if the base directory is surprising, empty, stale, relative when absolute was expected, or points at public `data/` when real data was intended.

## Phase 2: first real write

The first real write should use the ordinary confirmation path, not `--yes`.

Example flow:

```sh
# Preview first.
tools/edit journal add \
  --date YYYY-MM-DD \
  --memo "MEMO" \
  --from assets:... \
  --to expenses:... \
  --amount N \
  --dry-run

# If the preview is correct, run the same command without --dry-run.
# Do not add --yes during the trial.
tools/edit journal add \
  --date YYYY-MM-DD \
  --memo "MEMO" \
  --from assets:... \
  --to expenses:... \
  --amount N
```

Before answering `y`, check:

- `Target:` is the intended real source TSV.
- the proposed TSV row is exactly the intended row.
- `Post-check:` is acceptable, normally `lint`.
- no source TSV was edited by another terminal between preview and confirmation.

After the write, keep the terminal output until the post-check result is visible.

## Phase 3: observation log

For the trial, keep a short observation note outside source TSV.

Suggested format:

```text
Date:
Operation:
Base dir:
Dry-run first: yes/no
Confirmation path used: yes/no
--yes used: no
Post-check result:
Backup path:
Unexpected behavior:
Decision:
```

Good trial outcomes:

- the base directory was obvious every time
- dry-run output matched the later write preview
- confirmation prevented accidental writes
- backup path was printed on writes
- post-check passed
- no AI tool touched source TSV

Stop and investigate if:

- the target path is surprising
- a write happens without a visible preview
- `--yes` appears in a command proposal
- post-check fails
- stale-write protection triggers
- a backup path is missing for an existing source TSV write
- the report changes in a way not explained by the new row

## Restore posture

If post-check fails, do not keep editing forward blindly.

Use the restore suggestion printed by `run_post_check` as the first recovery hint. Inspect the backup and target before copying anything back.

For real data, prefer this sequence:

```sh
# inspect first
ls -l <backup-path> <target-path>
diff -u <backup-path> <target-path>

# restore only after confirming the backup is the intended previous state
cp <backup-path> <target-path>
tools/report
tools/doctor
```

## Trial exit criteria

The trial can be considered calm enough for normal daily use when several real writes have all met these conditions:

- absolute `LEDGER_DATA_DIR` was used
- `tools/doctor` matched the intended data directory
- writes went through preview and human confirmation
- `--yes` was not used
- post-check passed
- backups were created for existing TSV writes
- no unexplained report drift appeared

Do not treat this as approval for multi-user concurrent writing. The current practical model remains one human operator at a time.