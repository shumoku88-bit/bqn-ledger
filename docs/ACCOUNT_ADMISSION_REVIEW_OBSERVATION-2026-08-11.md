# Legacy Account admission review — 2026-08-11

## Baseline

- repository: `shumoku88-bit/bqn-ledger`
- reviewed main: `45686e5728292541df1c42628823a871c20a8264`
- Phase 2 cursor: `src/ledger/account_admission.bqn`
- separate open Draft #550 tracks canonical Household recovery closeout and legacy-source retirement

## Finding

`src/ledger/account_admission.bqn` is not the canonical Account source owner.

The canonical application path is:

```text
accounts.journal
  -> src/application/account_source_adapter.bqn
  -> src/ledger/account_journal_admission.bqn
  -> admitted Account carrier
```

Canonical Actual loading then passes that admitted carrier directly to `snapshot.BuildFromAccounts`. It does not convert canonical `accounts.journal` back through the TSV admission owner.

The retained TSV owner instead admits the legacy one-row-per-Account `accounts.tsv` shape. Its direct production consumers on reviewed main are:

1. `src/ledger/snapshot.bqn`, through the legacy convenience `Build(accountLines, rawJournal, registry)` entry point;
2. `src/application/editor_accounts.bqn`.

The canonical Actual adapter uses `snapshot.BuildFromAccounts`, bypassing the legacy `Build` path.

## Live legacy dependency

`src/application/editor_accounts.bqn` is still reached by `src_edit/travel_exchange_add_cmd.bqn`.

That command reads the Account source through `system_defaults.Load.DefaultAccountsFile`, and `config/system_defaults.tsv` currently sets:

```text
DEFAULT_ACCOUNTS_FILE	accounts.tsv
```

This is therefore a real legacy-basename dependency, not merely dead source or historical test evidence.

The canonical Household recovery closeout in Draft #550 already defines active legacy basename dependencies as retirement work. Its recorded policy also keeps the travel friend/exchange experiment outside the eight-file Household authority: if revisited, it must be mapped onto canonical owners or retired rather than preserving a ninth Household source.

## BQN-native review decision

Do **not** polish or structurally refactor `account_admission.bqn` now.

The file still contains array-native subtraction candidates, including:

- line-by-line mutable row/diagnostic accumulation;
- token-by-token mutable metadata accumulation;
- repeated metadata scans through `MetaOr`;
- a retained hand-built supported-key membership helper.

But improving those internals would invest in a source grammar whose live dependency is already classified for retirement. It would also risk obscuring the more important ownership problem: a production editor path still selects `accounts.tsv` despite canonical Account authority living in `accounts.journal`.

The correct subtraction is architectural, not local notation cleanup.

## Protected behavior until retirement

While the legacy owner remains reachable, keep its current laws unchanged:

- explicit Account currency;
- registry-supported currency;
- optional role with warning rather than rejection;
- metadata shape/support/uniqueness diagnostics;
- Account-key uniqueness;
- source-row diagnostics and order;
- fail-closed Account publication on any error.

PR #464 already replaced mutable uniqueness reconstruction with major-cell Deduplicate `⍷`; there is no reason to reopen that bounded decision merely to shorten the file.

## Next review cursor

Advance the BQN-native owner review to the actual canonical Account grammar owner:

```text
src/ledger/account_journal_admission.bqn
```

Retirement or rewiring of the legacy TSV owner, `editor_accounts`, `DEFAULT_ACCOUNTS_FILE`, and the travel editor dependency belongs to the canonical legacy-reference closeout reason-to-change, not to a local array-kernel refactor.
