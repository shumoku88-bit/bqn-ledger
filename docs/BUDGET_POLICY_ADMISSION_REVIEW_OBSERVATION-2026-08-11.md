# Canonical Budget policy admission review — 2026-08-11

## Baseline

- repository: `shumoku88-bit/bqn-ledger`
- review base: `d6c44df6924f7cd9622434f42095f8fe4b130877`
- active owner: `src/ledger/budget_policy_admission.bqn`
- repository cursor reached this owner after #649 closed `amount_text.bqn` and `budget_journal_admission.bqn`

## Reachability and history

This is a live canonical owner, not a legacy compatibility seam.

The owner entered production in #558, the canonical Budget evidence cutover, alongside `budget.journal` admission, canonical Budget loading, and Envelope consumption from `budget.toml`. #559 then exposed canonical Budget policy admission separately while Household policy and Budget movements were split into their own contexts.

The direct application adapter remains `src/application/budget_source_adapter.bqn`. It reads the canonical `budget.toml`, calls `policyAdmission.Admit ⟨raw,accounts⟩`, and can load policy independently of Budget movement validity. Full Budget loading requires both movement and policy admission before Facts publication.

The retained canonical fixture is intentionally small:

```toml
[[backing-pools]]
id = "main"
asset-accounts = ["Assets:Bank"]

[[envelopes]]
id = "Daily"
label = "Daily"
pacing = "daily"
backing-pool = "main"
expense-accounts = ["Expenses:Groceries"]
```

The owner therefore remains authoritative for the deterministic `budget.toml` subset shared with the canonical Household contract.

## Current pipeline hidden inside one Admit

The file currently contains four materially different stages.

### 1. Literal / lexical state

`ArrayClosed`, `ParseString`, and `SplitArrayItems` track quote and escape state while reading characters. Their mutation is not automatically structural debt: quote/escape recognition is genuinely sequential lexical state.

In particular:

- `]` inside a quoted string must not close a TOML array;
- `,` inside a quoted string must not split an array item;
- only `\"` and `\\` are supported escapes in the retained string subset;
- malformed literal diagnostics are later remapped to their logical key/value source line.

A review must not replace these with a compact whole-array expression merely to remove visible state if the lexical transition becomes less explicit.

### 2. Physical lines -> logical key/value rows

One TOML string array may span several physical lines. The current implementation carries mutable `pending / pendingText / pendingRow`, appends continuation text, and closes the logical row when `ArrayClosed` succeeds.

The first physical line is retained as the diagnostic coordinate for the resulting logical row.

This stage is related to lexical state: whether a physical line ends the logical row depends on quote-aware array closure. It should not be mechanically rewritten using the Account Journal segmentation recipe.

### 3. Logical rows -> table blocks

After logical rows exist, the grammar is simpler. Canonical headers are exactly:

- `[[backing-pools]]`
- `[[envelopes]]`

The current implementation nevertheless uses file-wide mutable:

```text
active / activeKind / activeLine / activePairs / Finalize
```

and walks logical rows one at a time.

Unlike physical-to-logical assembly, this stage has a plausible structural relation:

```text
logical rows
  -> header / ignored / key-row classification
  -> table-segment coordinate
  -> ordered blocks
```

A Scan/Group form may be clearer here, but only if it preserves the exact treatment of rows before the first valid header, invalid header-looking rows, comments/blanks, source order, and line coordinates.

### 4. Block semantics and Account relations

For each admitted table block, the owner validates the fixed key set and parses the field values. It then validates cross-block relations:

- backing-pool IDs unique;
- envelope IDs and labels unique;
- each envelope references a declared backing pool;
- one Expense Account belongs to at most one envelope;
- one Asset Account belongs to at most one backing pool;
- Expense Account keys resolve to `expense` Accounts;
- backing Account keys resolve to `asset` Accounts.

The final Account-resolution loops currently resolve each flattened policy key repeatedly through `IndexOf`. These relations are candidates for classify-once coordinates over the canonical Account axis, but they are independent of the lexical parser and should be judged on their own clarity.

## Diagnostic frontier observation

There is an important global-state contract inside block admission:

```bqn
blockClean ← 0=≠diagnostics
```

Because this tests the complete diagnostic vector rather than only the current block's structural diagnostics, one semantic error in an earlier block prevents later structurally valid blocks from being semantically parsed. Structural key checks still run for later blocks, but semantic diagnostics beyond that frontier are suppressed.

This may be deliberate fail-fast diagnostic publication or incidental coupling. The review must not silently turn it into independent per-block diagnostic accumulation, because that would change public diagnostics and their order even though the final result remains fail-closed.

The first characterization records the current frontier explicitly. A later change may deliberately revise it only with a separate diagnostic-ownership decision.

## Characterization added before production work

The focused `tests/test_ledger_budget_policy_admission.bqn` is extended to protect source-shape behavior that was previously left mostly to downstream integration tests:

1. quoted `]` does not close a multiline array and quoted `,` does not split an Account key;
2. malformed literal diagnostics in a multiline array retain the first physical line of the logical key/value row;
3. a key before the first canonical table header remains outside every block and retains its own physical line;
4. the current semantic diagnostic frontier is transaction/table-source ordered and suppresses later semantic block diagnostics after the first semantic failure;
5. invalid policy publication remains fail-closed with empty admitted pool/envelope axes.

No production behavior is changed by this characterization commit.

## Candidate review boundary

Do not treat every loop in this file as one defect.

The likely useful boundary is:

- keep quote/escape state explicit where it is genuine lexical state unless a clearer Scan transition is demonstrated;
- investigate structural Scan/Group segmentation only after logical rows exist;
- investigate Account key resolution as aligned policy-key -> Account-axis classification;
- keep diagnostic publication semantics explicit, especially the current global frontier;
- do not introduce a generic TOML parser or generic parser framework.

The goal is a visible pipeline of named source and semantic axes, not the minimum number of lines.

## Protected contracts

Preserve unless a separate review decision says otherwise:

- canonical `budget.toml` ownership and basename;
- deterministic backing-pool / envelope table grammar;
- multiline string-array support;
- quote/escape semantics of the retained subset;
- first-physical-line provenance for logical rows;
- source/table order;
- fixed key sets and duplicate/missing/unsupported-key diagnostics;
- backing-pool and envelope identity uniqueness;
- backing-pool references;
- Expense/Asset membership uniqueness;
- canonical Account existence and role checks;
- current public diagnostic ordering/frontier;
- fail-closed empty publication on any diagnostic;
- application independence of Budget policy loading from Budget movement validity;
- no writer, path, fallback, or Household allocation-account policy ownership added here.

## Qualification

- review base main `d6c44df6924f7cd9622434f42095f8fe4b130877` follows docs closeout #649;
- merged-main #649 CI #2612: SUCCESS before the review branch was cut;
- characterization CI: pending at the time this observation was first written.

## Current decision

Observation only. Do not yet copy the Account Journal refactor into this owner. First qualify the lexical/source-coordinate and diagnostic-frontier laws, then decide whether the clearest coherent production change is table segmentation, Account relation classification, both, or no change.
