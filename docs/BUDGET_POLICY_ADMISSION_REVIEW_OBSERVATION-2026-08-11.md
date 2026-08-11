# Canonical Budget policy admission review — 2026-08-11

## Baseline

- repository: `shumoku88-bit/bqn-ledger`
- review base: `d6c44df6924f7cd9622434f42095f8fe4b130877`
- active owner: `src/ledger/budget_policy_admission.bqn`
- focused review PR: #650
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

## Four different kinds of work live inside Admit

The review began by separating four materially different stages rather than treating every visible loop or mutation as one defect.

### 1. Literal / lexical state

`ArrayClosed`, `ParseString`, and `SplitArrayItems` track quote and escape state while reading characters. Their mutation is not automatically structural debt: quote/escape recognition is genuinely sequential lexical state.

In particular:

- `]` inside a quoted string must not close a TOML array;
- `,` inside a quoted string must not split an array item;
- only `\"` and `\\` are supported escapes in the retained string subset;
- malformed literal diagnostics are later remapped to their logical key/value source line.

The review deliberately leaves this state explicit. No generic TOML parser or parser framework is introduced.

### 2. Physical lines -> logical key/value rows

One TOML string array may span several physical lines. The implementation carries `pending / pendingText / pendingRow`, appends continuation text, and closes the logical row when `ArrayClosed` succeeds.

The first physical line is retained as the diagnostic coordinate for the resulting logical row.

This stage is coupled to lexical state because whether a physical line closes the logical row depends on quote-aware array closure. The review therefore does not mechanically copy the Account Journal segmentation rewrite across this boundary.

### 3. Logical rows -> table blocks

Once quote-aware logical rows exist, the grammar is structural. Canonical headers are exactly:

- `[[backing-pools]]`
- `[[envelopes]]`

The previous implementation used file-wide mutable:

```text
active / activeKind / activeLine / activePairs / Finalize
```

and walked logical rows one at a time.

The retained production form instead exposes the source relation:

```text
logical rows
  -> ignored / backing-pool-header / envelope-header classification
  -> header mask
  -> Scan table coordinate
  -> Group ordered source segments
  -> local ParseSegment
```

In BQN this is centered on:

```bqn
header ← poolHeader ∨ envelopeHeader
segmentIds ← +`header
segments ← segmentIds⊔indices
```

`ParseSegment` then handles either the outside-table prefix or one source-ordered canonical table segment. Empty group zero, comments/blanks, rows before the first canonical header, invalid header-looking rows, source order, and physical line coordinates remain covered by focused and repository-wide laws.

This is the same broad array idea seen in Account Journal review, but it is applied only after the lexical boundary rather than copied wholesale into the physical-line parser.

### 4. Block semantics and policy relations

For each admitted table block, the owner still validates the fixed key set and parses field values. It then owns cross-block relations:

- backing-pool IDs unique;
- envelope IDs and labels unique;
- each envelope references a declared backing pool;
- one Expense Account belongs to at most one envelope;
- one Asset Account belongs to at most one backing pool;
- Expense Account keys resolve to `expense` Accounts;
- backing Account keys resolve to `asset` Accounts.

The previous Account-resolution path nested loops over every Envelope/Pool key and called scalar `IndexOf` for each key.

The retained production form makes the policy axes explicit instead:

```text
ragged Expense / Asset policy lists
  -> flattened policy-key axes
  -> replicated owner-line axes
  -> Account coordinates with dyadic Index Of
  -> known masks
  -> role cells with vector Select
  -> role-valid masks
  -> key-major diagnostic cells
```

Envelope backing-pool references are likewise classified once onto the declared pool ID axis before unknown diagnostics are published.

The publication order is intentionally unchanged: Expense Account diagnostics remain before backing Asset Account diagnostics, and within each family diagnostics remain policy-key-major with the owning Envelope/Pool source line.

## Diagnostic frontier retained intentionally

There is an important global-state contract inside block semantic admission:

```bqn
blockClean ← 0=≠diagnostics
```

Because this tests the complete diagnostic vector rather than only the current block's structural diagnostics, one semantic error in an earlier block prevents later structurally valid blocks from being semantically parsed. Structural key checks still run for later blocks, but semantic diagnostics beyond that frontier are suppressed.

The review characterized this behavior before production work and keeps it unchanged. Turning block semantics into an independent map would otherwise change public diagnostics and ordering even though final publication remained fail-closed.

This frontier may deserve a separate future diagnostic-ownership decision, but it is not incidental cleanup inside the present BQN-native review.

## Characterization before production work

The focused `tests/test_ledger_budget_policy_admission.bqn` was strengthened before each production boundary.

Source-shape characterization protects:

1. quoted `]` does not close a multiline array and quoted `,` does not split an Account key;
2. malformed literal diagnostics in a multiline array retain the first physical line of the logical key/value row;
3. a key before the first canonical table header remains outside every block and retains its own physical line;
4. the current semantic diagnostic frontier suppresses later semantic block diagnostics after the first semantic failure;
5. invalid policy publication remains fail-closed with empty admitted pool/envelope axes.

Relation characterization additionally fixes current Account diagnostic order and owner coordinates. For a mixed unknown/wrong-role policy, the public order is:

```text
Expense unknown
Expense wrong role
Asset unknown
Asset wrong role
```

with each diagnostic retaining the source line of the owning Envelope or backing-pool block.

## Failed probes retained as BQN evidence

Two failed production probes were useful because they exposed scalar notation that had survived after the relation itself became an array.

### CI #2616: string cell versus character axis

The first classify-once spelling selected roles with scalar Pick and then attempted:

```bqn
"expense"⊸≡¨expenseRoles
```

The observed value was not yet the intended vector of role-string cells. CBQN reported a Mapping shape mismatch. The comparison was rewritten as an explicit role-cell mask, but the next run showed that comparison spelling was not the underlying issue.

### CI #2617: Pick versus Select

The remaining failure occurred at:

```bqn
expenseKnown ∧ ¬expenseRoleValid
```

with a one-key known axis against the seven-character axis of the string `"expense"`.

The cause was precise: `accounts.key⊐expenseKeys` produces a vector of Account coordinates, but the first production spelling used scalar Pick `⊑` to project `accounts.role`. A one-element coordinate vector therefore picked one role string as a character vector instead of selecting one role cell on the policy-key axis.

Repository-native examples confirm the correct relation idiom:

```bqn
indices ← accounts.key⊐keys
roles ← indices⊏(accounts.role∾⟨""⟩)
```

Changing role projection from `⊑` to vector Select `⊏` restored the intended aligned key axis. CI #2618 then passed the full repository check and coverage.

The failed probes are therefore not hidden as noise. They document a useful BQN rule for this codebase: once a relation is expressed as a coordinate array, subsequent projection must preserve that array axis rather than falling back to scalar Pick notation.

## What was deliberately not changed

The review does not pursue minimum mutation count.

Retained intentionally:

- quote/escape state in literal parsing;
- pending multiline logical-row assembly;
- block semantic mutation and the current global diagnostic frontier;
- domain-specific local parsing rather than a generic TOML abstraction.

Changed structurally:

- table boundary state after logical rows exist;
- repeated backing-pool lookup;
- repeated scalar Account key lookup and role resolution.

This makes the remaining state easier to justify: it corresponds either to real lexical transition or to current diagnostic publication semantics, not merely to source segmentation or repeated relation search.

## Protected contracts

Preserved by focused and full qualification:

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
- source-shape characterization CI #2613: SUCCESS;
- table Scan/Group segmentation CI #2614: SUCCESS;
- Account relation diagnostic-order characterization CI #2615: SUCCESS;
- Account classify-once CI #2616: FAILED on the first role-axis spelling;
- role-cell comparison adjustment CI #2617: FAILED and exposed remaining scalar Pick versus vector Select mismatch;
- corrected Account coordinate projection CI #2618: SUCCESS with full repository check and coverage.

## Review decision

Retain `src/ledger/budget_policy_admission.bqn` as the canonical deterministic Budget policy owner.

Its BQN-native architecture should make the different state classes visible rather than flatten them into one aesthetic rule:

```text
physical source
  -> explicit lexical/multiline state
  -> logical rows
  -> whole-array header classification / Scan / Group
  -> ordered local table semantics
  -> classify-once pool and Account relations
  -> source-ordered diagnostics
  -> fail-closed policy publication
```

Do not replace the remaining lexical state merely because it is mutable. Do not introduce a generic parser abstraction. The coherent improvement is to remove structural table staging and repeated relation search while retaining state that still carries lexical or diagnostic meaning.
