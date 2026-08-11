# Facts and Household review closeout — 2026-08-11

## Final state

- `src/ledger/facts.bqn`: PR #664, squash-merged main `b085574654167e200e7435ec2a3380ad69763609`; merged-main CI #2678 SUCCESS.
- `src/ledger/household_policy_admission.bqn` section review: PR #665, squash-merged main `1c21045f88a5042b139404e068c3312e75bc808c`; merged-main CI #2682 SUCCESS.
- `src/ledger/household_policy_admission.bqn` Account-relation review: PR #666, squash-merged main `36bd3f91a1034b2470979cd03dd84a67f38da200`; merged-main CI #2686 SUCCESS.
- next normal Phase 2 owner: `src/ledger/issue_admission.bqn`.

The final owners were reread from merged `main` before the queue was advanced.

## Facts

The canonical Fact projection remains a fail-closed projection-invariant boundary. The review did not delete date, Domain, Layer, Account, balance, or identity guards merely because canonical Journal admission already owns related source semantics.

The structural change was narrower:

```text
admitted Transactions
  -> classify Domain / Layer coordinates once
  -> flatten Posting cells once in transaction-major order
  -> classify Posting Account coordinates once
  -> reuse the same coordinates for diagnostics and publication
  -> publish Fact columns directly
```

The temporary Posting-row namespace and repeated join discovery were removed. Transaction-major diagnostic order remains explicit and protected.

Detailed evidence: `docs/FACTS_REVIEW_OBSERVATION-2026-08-11.md`.

## Household policy

The Household owner exposed three different kinds of structure that had previously looked superficially similar.

### 1. Lexical history

Multiline TOML Account arrays retain genuine quote/pending state because later physical characters depend on earlier lexical context.

### 2. Section coordinates

After logical rows exist, section ownership is not lexical history. PR #665 replaced `active / current / Finalize` with total header classification, prefix Scan, and Grouped source segments. Unsupported sections remain non-owning and preserve source-ordered diagnostics.

Detailed evidence: `docs/HOUSEHOLD_POLICY_SECTION_REVIEW_OBSERVATION-2026-08-11.md`.

### 3. Account coordinates

Household Account references are now classified once onto the admitted Account axis. Known/role masks and the same coordinates drive both diagnostics and publication. Dense Account-policy labels are reconstructed from sparse Account coordinates without one rescan per Account.

Detailed evidence: `docs/HOUSEHOLD_POLICY_ACCOUNT_RELATION_REVIEW_OBSERVATION-2026-08-11.md`.

## Review lesson

The repeated lesson across these owners is not “remove state” or “use more glyphs.” It is to ask what the state actually represents:

```text
prior-character dependence -> genuine sequential state
completed row ownership     -> section coordinate
Account reference           -> Account coordinate
projection join             -> reusable semantic coordinate
```

Only incidental discovery/staging was removed. Exact arithmetic, diagnostics, identity/provenance, fail-closed publication, source ownership, and writer authority remain where their semantics require them.