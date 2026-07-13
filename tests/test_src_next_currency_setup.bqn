#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
setup ← •Import "../src_next/currency_setup.bqn"
loader ← •Import "../src_next/loader.bqn"
util ← •Import "../src_next/util.bqn"

tab ← @+9

# Built-in currency admission and lexical precision have one pure owner.
⟨"JPY", "ILS"⟩ lib.AssertEq setup.supported_currencies
jpyPolicy ← setup.Policy "JPY"
"ok" lib.AssertEq jpyPolicy.state
"JPY" lib.AssertEq jpyPolicy.currency
¯1 lib.AssertEq jpyPolicy.max_fraction_digits
ilsPolicy ← setup.Policy "ILS"
"ok" lib.AssertEq ilsPolicy.state
"ILS" lib.AssertEq ilsPolicy.currency
2 lib.AssertEq ilsPolicy.max_fraction_digits
unknownPolicy ← setup.Policy "USD"
"error" lib.AssertEq unknownPolicy.state
"unsupported_currency" lib.AssertEq unknownPolicy.code
0 lib.AssertEq setup.IsSupportedCurrency "USD"

ReadPreserve ← {𝕊 path:
  raw ← loader.ReadRaw path
  clean ← ((@+13) ≠ raw) / raw
  (@+10) util.SplitKeepEmpty clean
}

base ← "fixtures/currency-m15-migration"
configLines ← ReadPreserve (base ∾ "/config.tsv")
accountLines ← ReadPreserve (base ∾ "/accounts.tsv")
journalLines ← ReadPreserve (base ∾ "/journal.tsv")
planLines ← ReadPreserve (base ∾ "/plan.tsv")
budgetLines ← ReadPreserve (base ∾ "/budget_alloc.tsv")

# Explicit ledger default is required and independently resolved.
defaultResult ← setup.ResolveDefault configLines
"ok" lib.AssertEq defaultResult.state
"DEFAULT_CURRENCY" lib.AssertEq defaultResult.key
"JPY" lib.AssertEq defaultResult.currency
"ledger_config" lib.AssertEq defaultResult.provenance

missingDefault ← setup.ResolveDefault ⟨"POLICY_BUDGET_STYLE=envelope"⟩
"error" lib.AssertEq missingDefault.state
"missing_default_currency" lib.AssertEq missingDefault.code

duplicateDefault ← setup.ResolveDefault ⟨"DEFAULT_CURRENCY=JPY", "DEFAULT_CURRENCY=ILS"⟩
"error" lib.AssertEq duplicateDefault.state
"duplicate_default_currency" lib.AssertEq duplicateDefault.code

unknownDefault ← setup.ResolveDefault ⟨"DEFAULT_CURRENCY=USD"⟩
"error" lib.AssertEq unknownDefault.state
"unsupported_default_currency" lib.AssertEq unknownDefault.code

# Selection provenance distinguishes ledger default from explicit override.
defaultSelection ← setup.ResolveSelection ⟨defaultResult, ""⟩
"ok" lib.AssertEq defaultSelection.state
"JPY" lib.AssertEq defaultSelection.currency
"ledger_default" lib.AssertEq defaultSelection.provenance

explicitSelection ← setup.ResolveSelection ⟨defaultResult, "ILS"⟩
"ok" lib.AssertEq explicitSelection.state
"ILS" lib.AssertEq explicitSelection.currency
"explicit_selection" lib.AssertEq explicitSelection.provenance

unsupportedSelection ← setup.ResolveSelection ⟨defaultResult, "USD"⟩
"error" lib.AssertEq unsupportedSelection.state
"unsupported_selected_currency" lib.AssertEq unsupportedSelection.code

# Full read-only migration audit/preview. Target is explicit JPY, not inherited
# from DEFAULT_CURRENCY.
result ← setup.Build ⟨configLines, accountLines, journalLines, planLines, budgetLines, "JPY"⟩
"ok" lib.AssertEq result.state
"JPY" lib.AssertEq result.default_currency.currency
"JPY" lib.AssertEq result.migration_target
5 lib.AssertEq result.changed_count
0 lib.AssertEq result.error_count
4 lib.AssertEq ≠ result.files

accounts ← 0 ⊑ result.files
journal ← 1 ⊑ result.files
plan ← 2 ⊑ result.files
budget ← 3 ⊑ result.files

2 lib.AssertEq accounts.missing_count
2 lib.AssertEq accounts.explicit_count
0 lib.AssertEq accounts.error_count
1 lib.AssertEq journal.missing_count
2 lib.AssertEq journal.explicit_count
1 lib.AssertEq plan.missing_count
1 lib.AssertEq budget.missing_count

# Exact append-only proposal: account names, metadata, order, comments, blanks,
# and unrelated metadata are retained.
"# account order and metadata must remain exact" lib.AssertEq 0 ⊑ accounts.proposed_lines
("assets:bank" ∾ tab ∾ "role=asset" ∾ tab ∾ "type=liquid" ∾ tab ∾ "currency=JPY") lib.AssertEq 1 ⊑ accounts.proposed_lines
("expenses:food" ∾ tab ∾ "role=expense" ∾ tab ∾ "report_group=food" ∾ tab ∾ "currency=JPY") lib.AssertEq 2 ⊑ accounts.proposed_lines
"" lib.AssertEq 3 ⊑ accounts.proposed_lines
(4 ⊑ accountLines) lib.AssertEq 4 ⊑ accounts.proposed_lines

journalOriginal ← 1 ⊑ journalLines
journalProposed ← 1 ⊑ journal.proposed_lines
(journalOriginal ∾ tab ∾ "currency=JPY") lib.AssertEq journalProposed
originalFields ← tab util.SplitKeepEmpty journalOriginal
proposedFields ← tab util.SplitKeepEmpty journalProposed
(5 ↑ originalFields) lib.AssertEq 5 ↑ proposedFields
"" lib.AssertEq 1 ⊑ originalFields
"party=shop" lib.AssertEq 5 ⊑ proposedFields
"currency=JPY" lib.AssertEq 6 ⊑ proposedFields

# Existing explicit JPY and ILS rows are byte-identical in the preview.
(2 ⊑ journalLines) lib.AssertEq 2 ⊑ journal.proposed_lines
(3 ⊑ journalLines) lib.AssertEq 3 ⊑ journal.proposed_lines

# Idempotence: previewing already-proposed content produces no further change.
second ← setup.Build ⟨configLines, accounts.proposed_lines, journal.proposed_lines, plan.proposed_lines, budget.proposed_lines, "JPY"⟩
"ok" lib.AssertEq second.state
0 lib.AssertEq second.changed_count

# DEFAULT_CURRENCY must not become missing-source authority. Even an ILS default
# does not change the separately explicit JPY migration target.
ilsDefaultLines ← ⟨"DEFAULT_CURRENCY=ILS"⟩
separated ← setup.Build ⟨ilsDefaultLines, ⟨"assets:bank"∾tab∾"role=asset"⟩, ⟨⟩, ⟨⟩, ⟨⟩, "JPY"⟩
"ok" lib.AssertEq separated.state
"ILS" lib.AssertEq separated.default_currency.currency
"JPY" lib.AssertEq separated.migration_target
1 lib.AssertEq separated.changed_count
1 lib.AssertEq ∨´ "currency=JPY" ⍷ (0 ⊑ (0 ⊑ separated.files).proposed_lines)

# Unknown and duplicate row currency fail closed with no proposed replacement.
unknownRow ← "2026-07-01"∾tab∾"x"∾tab∾"assets:bank"∾tab∾"expenses:food"∾tab∾"1"∾tab∾"currency=USD"
unknownFile ← setup.AuditFile ⟨"journal.tsv", "journal", ⟨unknownRow⟩, "JPY"⟩
"error" lib.AssertEq unknownFile.state
1 lib.AssertEq unknownFile.error_count
⟨⟩ lib.AssertEq unknownFile.proposed_lines
"unknown" lib.AssertEq (⊑ unknownFile.rows).classification

duplicateRow ← unknownRow ∾ tab ∾ "currency=JPY"
duplicateFile ← setup.AuditFile ⟨"journal.tsv", "journal", ⟨duplicateRow⟩, "JPY"⟩
"error" lib.AssertEq duplicateFile.state
"duplicate" lib.AssertEq (⊑ duplicateFile.rows).classification

# M1.5 migration target is intentionally finite: JPY only.
wrongTarget ← setup.Build ⟨configLines, accountLines, journalLines, planLines, budgetLines, "ILS"⟩
"error" lib.AssertEq wrongTarget.state
0 lib.AssertEq ≠ wrongTarget.files
1 lib.AssertEq ∨´ "unsupported migration target" ⍷ wrongTarget.message

•Out "test_src_next_currency_setup.bqn: OK"
