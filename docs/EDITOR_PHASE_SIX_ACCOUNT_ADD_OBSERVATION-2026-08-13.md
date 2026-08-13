# `src_edit/account_add_cmd.bqn` Phase 6 observation — 2026-08-13

## Scope

This review resumes the normal Phase 6 cursor after the `src/editor/` closeout in #734.

Owner under review:

- `src_edit/account_add_cmd.bqn`

Directly relevant boundaries were also read to distinguish production semantics from stale UI/compatibility residue:

- `src/ledger/account_journal_admission.bqn`;
- `src/application/account_source_adapter.bqn`;
- `tools/edit-bqn` Account Add routing;
- `tools/add-ui.sh` Account Add interaction;
- `src_edit/validate.bqn` historical `ValidateAccountAdd`;
- `src_edit/render.bqn` historical `RenderAccountRow`;
- current editor usage documents and Account checks.

## BQN-native result

`account_add_cmd.bqn` does not justify a broad rewrite.

Its core Account declaration relation is already explicit as aligned vectors:

```text
role      asset liability equity income expense budget
type      Asset Liability Equity Income Expense Budget
namespace assets: ...    equity: income: expenses: budget:
```

One role index selects the corresponding canonical type and namespace. Commodity inference is derived from admitted canonical Accounts, and the candidate declaration is re-admitted as a complete `accounts.journal` before publication. The final admitted Account is then checked for exact name / role / type / Commodity round-trip.

These are useful semantic and writer-safety boundaries, not incidental machinery to remove for compactness.

The candidate construction's local mutation is also deliberate. It assembles source bytes behind the existing safe-write/application boundary and does not model mutable Household domain state.

## Concrete defect found

The canonical writer checked that the Account name began with the selected role namespace, but did not require any identity text after that prefix.

Therefore a value such as:

```text
equity:
```

could pass the writer's namespace check even though it contains no Account-specific suffix.

This is different from the broader canonical Journal admission law, which deliberately does not own project-specific namespace naming policy. Account Add is the correct writer boundary for the stronger interactive naming rule.

The closeout therefore adds only this fail-closed condition:

```text
length(name) > length(selected namespace)
```

No Account identity is synthesized and no existing Account is reinterpreted.

## Canonical six-role contract

The writer's six roles are intentional, not an accidental implementation detail:

- `asset` -> `assets:` -> `Asset`;
- `liability` -> `liabilities:` -> `Liability`;
- `equity` -> `equity:` -> `Equity`;
- `income` -> `income:` -> `Income`;
- `expense` -> `expenses:` -> `Expense`;
- `budget` -> `budget:` -> `Budget`.

The focused Account Add check exercises all six through the public writer path and requires exact canonical declaration text while remaining dry-run/read-only.

Legacy `--type=liquid|savings|invest` is not Account declaration meaning anymore. The canonical writer continues to reject it because Household classification belongs to `household.toml` rather than being smuggled back into `accounts.journal`.

## Residue deliberately not folded into this owner

The review also exposed old Account Add topology outside the current semantic owner:

1. `src_edit/validate.bqn::ValidateAccountAdd` still describes the former four-role TSV + optional asset `type=` contract. Repository search finds no production consumer; its remaining consumer is its unit characterization.
2. `src_edit/render.bqn::RenderAccountRow` similarly renders the former `accounts.tsv` row shape and is only characterized by the edit unit test.
3. `tools/add-ui.sh` currently offers only the four ordinary daily Account roles (`asset`, `liability`, `income`, `expense`) even though the direct canonical writer accepts six.
4. the current BQN editor operational guide still contains four-role / `--type` examples from the retired Account TSV contract.

Do not create a second Account role registry merely to repair these residues. `account_add_cmd.bqn` and canonical Account admission already own the actual declaration meaning.

The two dead BQN helpers belong to their normal `render.bqn` / `validate.bqn` Phase 6 owner reviews, where they can be removed without pretending those entire files were reviewed early. The add-ui role subset and stale operational wording belong to the existing cross-cutting selector/UI/documentation cleanup lane. They are not reasons to move Account semantics into shell.

## Evidence

`checks/check-edit-bqn-account-add-contract.sh` proves:

1. all six canonical roles produce the correct Account declaration in dry-run mode;
2. explicit Commodity survives exactly;
3. dry-run does not mutate `accounts.journal`;
4. namespace-only Account names fail without mutation;
5. legacy `--type` fails without mutation;
6. role/namespace mismatch fails without mutation.

The existing multi-currency Account writer checks remain responsible for single-Commodity inference, required explicit Commodity on mixed-Commodity roots, unsupported Commodity rejection, safe publication, and legacy-file non-mutation.

## Decision

`src_edit/account_add_cmd.bqn` is reviewed.

Production changes only for the concrete missing suffix gate. The aligned role/type/prefix relation, canonical Account observation, complete-source admission, exact round-trip check, and safe-write protocol are retained.

The normal Phase 6 cursor can advance to:

`src_edit/account_list_cmd.bqn`
