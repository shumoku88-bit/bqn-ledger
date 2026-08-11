# Currency registry review observation — 2026-08-11

## Baseline and ownership

- repository: `shumoku88-bit/bqn-ledger`
- review base: `4f158ba96880cec29cd5ce2c4ae6291d0a6032d4`
- active owner: `src/ledger/currency_registry.bqn`
- focused review PR: #655

`currency_registry.bqn` is a live canonical owner rather than a legacy qualification seam. Current editor, report, issue-validation, and test paths consume its `Build` result, `Policy`, and `IsSupportedCurrency` surface.

The retained source transformation is small and explicit:

```text
physical currency rows
  -> ignored-line classification
  -> parsed currency / fraction / symbol row cells
  -> aligned registry axes
  -> whole-registry validation
  -> Policy / IsSupportedCurrency publication
```

The review therefore treats source-line totality and registry-wide relations as worthwhile BQN work, while preserving the existing public validation and policy contract.

## Empty-line classifier was partial

The previous ignored-line classifier was:

```bqn
(0=≠line) ∨ ((0<≠line) ∧ (((⊑line)='#') ∨ ((⊑line)=⊑"\\")))
```

Its intent was clear: blank lines and comment lines are ignored. The problem is that `⊑line` is partial for an empty character vector, while ordinary boolean composition is not a control-flow boundary that makes the later expression total.

The corrected focused characterization was run first against baseline production. PR head `d4257c2ea1f902f5d888059ab00809c859e66a4c` changed only the focused test and asserted that a blank line preceding a valid JPY row is ignored. CI #2636 attempt 2 reached that focused test and failed, establishing the production defect independently of the later fix.

The retained implementation mirrors the already proven line-classification idiom in `src/application/source_io.bqn`:

```bqn
IsIgnored ← {𝕊 line:
  (0<≠line) ? (((⊑line)='#') ∨ ((⊑line)=⊑"\\")) ; 1
}
```

The nonempty body owns first-character inspection. The fallback body owns the empty-line result. This makes the partial operation unreachable for the empty shape instead of relying on a boolean guard around it.

## A failed characterization probe was an authoring error, not evidence

The first characterization draft accidentally bound a string to the uppercase name `ValidLine`. In BQN, the name role did not match the subject value being assigned. CI #2632 and #2633 therefore failed because of the test itself.

Those runs are not counted as production evidence. The test variable was corrected to lowercase `validLine`, production was restored to the exact main baseline, and the characterization was rerun before drawing the empty-line conclusion.

This failure is worth retaining in the review record because syntactic role is part of BQN program structure; a failing test is only evidence about production after the test itself has been qualified.

## Currency uniqueness is a direct array relation

The previous duplicate check sorted the boxed currency-code axis and then compared adjacent cells:

```bqn
sorted ← (⍋ codes) ⊏ codes
duplicate ← 0 < +´ ((1↓sorted) ≡¨ (¯1↓sorted))
```

No ordering is semantically required. Registry admission asks only whether the code axis contains duplicate cells.

The retained implementation states that relation directly:

```bqn
duplicate ← (≠codes) ≠ ≠⍷codes
```

This removes the incidental sort and adjacent-pair construction while preserving the existing duplicate diagnostic and successful code order. Full repository CI #2646 passed with this form.

## Diagnostic priority remains explicit scalar control

Focused laws now protect the current validation precedence, including:

- row shape before later row semantics;
- empty currency code before invalid fraction digits;
- invalid fraction digits before duplicate-code rejection when both defects are present;
- duplicate valid currency rejection;
- fail-closed publication with an empty error registry.

The review explored replacing the mutable `result ↩ Failure` admission ladder and `Policy` publication branch with a compact predicate-body chain. A temporary early review gate demonstrated that the broad rewrite was not behaviorally correct (CI #2642), so it was rejected rather than polished into the production change.

That is an intentional architectural decision. Registry uniqueness is a whole-array relation and benefits from `⍷`. Validation precedence and one requested-currency lookup are ordered scalar decisions with public diagnostic behavior. This review does not equate BQN-native code with minimizing every branch or mutation regardless of semantic shape.

## Public registry laws strengthened

`tests/test_ledger_currency_registry_short_rows.bqn` now protects more than short-row rejection:

- a valid JPY row publishes its code, fraction policy, and symbol;
- `Policy "JPY"` succeeds;
- `Policy "USD"` remains the documented unsupported-currency result for a one-code test registry;
- `IsSupportedCurrency` agrees with `Policy` for supported and unsupported requests;
- blank lines are ignored;
- a source containing only ignored rows reports `currency_registry_empty`;
- validation-priority cases remain fail-closed.

No generic parser, registry framework, or compatibility path was introduced.

## CI evidence and review discipline

During the review, several workflow attempts stopped earlier at `tests/test_accounting_account_balance.bqn`. The same baseline-production characterization run later progressed past that test on rerun and failed at the intended currency focused test, so those earlier stops were kept separate from currency-registry evidence.

A temporary `tests/test_000_currency_registry_review.bqn` was used only to move focused evidence ahead of the unrelated early stop while isolating candidate implementations. It was removed before final qualification.

Qualified production milestones:

- CI #2645: SUCCESS with total ignored-line classification and the original admission/Policy structure;
- CI #2646: SUCCESS after replacing sort-based uniqueness detection with `⍷`;
- final no-temporary-gate qualification: pending at the time this observation was written.

## Review conclusion

The retained owner is deliberately modest:

```text
make shape-sensitive classification total
+ express true whole-array uniqueness with Deduplicate
+ strengthen public laws
+ retain ordered diagnostic control where it carries domain behavior
```

The useful BQN lesson is not glyph density. It is to identify what is actually an array relation, expose that relation directly, and keep different semantic kinds of control distinct.
