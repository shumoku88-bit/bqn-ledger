#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
converter ← •Import "../src_next/journal_canonical_prefix_converter.bqn"
ak ← •Import "../src_next/account_key.bqn"
context ← •Import "../src_next/context.bqn"
cube ← •Import "../src_next/cube.bqn"
trial ← •Import "../src_next/trial_balance.bqn"
balances ← •Import "../src_next/balances.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"

lf ← @+10 ⋄ tab ← @+9
JoinFields ← {𝕊 fields: ∾ (((¯1↓fields) ∾¨ <tab) ∾ ¯1↑fields)}
accounts ← ⟨
  "assets:orchard"∾tab∾"role=asset"∾tab∾"type=liquid"∾tab∾"kind=liquid",
  "expenses:market"∾tab∾"role=expense"∾tab∾"budget=daily",
  "expenses:studio"∾tab∾"role=expense",
  "income:workshop"∾tab∾"role=income"
⟩
resolved ← ak.Resolve accounts
cycleStart ← "2042-03-01"

metaAll ← ⟨
  "income_budget=exclude", "currency=JPY", "cashflow=fixed_obligation",
  "plan_id=plan-orchard-2042", "party=Public Cooperative",
  "txn_id=txn-shared-public", "receipt=receipt-public-7",
  "due_on=2042-03-20", "note=synthetic note", "invoice=ok",
  "biz=1", "tax=business"
⟩
row1 ← JoinFields (⟨"2042-03-03", "青空  市場, morning!", "assets:orchard", "expenses:market", "1200"⟩ ∾ metaAll)
row2 ← JoinFields ⟨"2042-03-04", "Shared linkage second", "assets:orchard", "expenses:studio", "300", "txn_id=txn-shared-public", "currency=JPY"⟩
row3 ← JoinFields ⟨"2042-03-05", "Workshop income", "income:workshop", "assets:orchard", "5000"⟩
snapshot ← "# invented comment"∾lf∾lf∾row1∾lf∾"\\ another invented comment"∾lf∾row2∾lf∾row3∾lf

converted ← converter.Convert ⟨snapshot,"journal.tsv",accounts,cycleStart⟩
"ok" lib.AssertEq converted.state
0 lib.AssertEq ≠converted.diagnostics
3 lib.AssertEq converted.validation_summary.source_row_count
3 lib.AssertEq converted.validation_summary.transaction_count
6 lib.AssertEq converted.validation_summary.posting_count
1 lib.AssertEq converted.validation_summary.parser_pass
1 lib.AssertEq converted.validation_summary.account_resolver_pass
1 lib.AssertEq converted.validation_summary.stage2a_pass
1 lib.AssertEq converted.validation_summary.stage2b_pass
1 lib.AssertEq converted.validation_summary.accounting_parity_pass
1 lib.AssertEq converted.validation_summary.identity_parity_pass
1 lib.AssertEq converted.validation_summary.metadata_parity_pass

prefix ← converted.canonical_prefix_bytes
lf lib.AssertEq ¯1⊑prefix
lib.Assert ¬ ∨´ (@+13) = prefix
lib.Assert 0 < +´ "commodity JPY" ⍷ prefix
1 lib.AssertEq +´ "commodity JPY" ⍷ prefix
3 lib.AssertEq +´ " * " ⍷ prefix
lib.Assert 0 < +´ "2042-03-03 * 青空  市場, morning!" ⍷ prefix
lib.Assert 0 < +´ "    ; event-id: legacy:journal.tsv:0" ⍷ prefix
lib.Assert 0 < +´ "    ; event-id: legacy:journal.tsv:1" ⍷ prefix
lib.Assert 0 < +´ "    ; event-id: legacy:journal.tsv:2" ⍷ prefix
⟨"legacy:journal.tsv:0","legacy:journal.tsv:1","legacy:journal.tsv:2"⟩ lib.AssertEq {𝕩.source_event_id}¨converted.transactions
⟨"txn-shared-public","txn-shared-public",""⟩ lib.AssertEq {𝕩.txn_id}¨converted.transactions
⟨0,1,0,1,0,1⟩ lib.AssertEq {𝕩.posting_index}¨converted.provenance_rows
lib.Assert ∧´ {𝕩.identity_kind≡"durable"}¨converted.provenance_rows
lib.Assert ∧´ {𝕩.status≡"ok"}¨converted.posting_rows
lib.Assert ∧´ {𝕩.layer_name≡"actual"}¨converted.posting_rows
lib.Assert ∧´ {0=+´{𝕩.delta}¨𝕩.postings}¨converted.transactions
expectedMetadataKeys ← ⟨"event-id","layer","tax","biz","invoice","note","due-on","receipt","txn-id","party","plan-id","cashflow","currency","income-budget"⟩
expectedMetadataValues ← ⟨
  "legacy:journal.tsv:0","actual","business","1","ok","synthetic note","2042-03-20",
  "receipt-public-7","txn-shared-public","Public Cooperative","plan-orchard-2042",
  "fixed_obligation","JPY","exclude"
⟩
expectedMetadataKeys lib.AssertEq {𝕩.key}¨(⊑converted.transactions).metadata
expectedMetadataValues lib.AssertEq {𝕩.value}¨(⊑converted.transactions).metadata
⟨"event-id","layer"⟩ lib.AssertEq {𝕩.key}¨(2⊑converted.transactions).metadata
⟨"legacy:journal.tsv:2","actual"⟩ lib.AssertEq {𝕩.value}¨(2⊑converted.transactions).metadata

# The exact metadata parity seam rejects changed values, keys, and extras.
actualMetadata ← (⊑converted.transactions).metadata
valueMismatch ← ⟨⊑actualMetadata,{key⇐"layer",value⇐"plan",source_line⇐0}⟩ ∾ 2↓actualMetadata
lib.Assert ¬converter.MetadataEntriesEqual ⟨actualMetadata,valueMismatch⟩
keyMismatch ← ⟨⊑actualMetadata,{key⇐"action",value⇐"actual",source_line⇐0}⟩ ∾ 2↓actualMetadata
lib.Assert ¬converter.MetadataEntriesEqual ⟨actualMetadata,keyMismatch⟩
unexpectedMetadata ← actualMetadata ∾ ⟨{key⇐"action",value⇐"extra",source_line⇐0}⟩
lib.Assert ¬converter.MetadataEntriesEqual ⟨actualMetadata,unexpectedMetadata⟩

parsedDeclarations ← parser.ParseWithProfile ⟨prefix,"historical_external_plan"⟩
⟨"asset","expense","expense","income"⟩ lib.AssertEq {𝕩.role}¨parsedDeclarations.accounts
⟨"liquid","","",""⟩ lib.AssertEq {𝕩.kind}¨parsedDeclarations.accounts
⟨"daily"⟩ lib.AssertEq ({𝕩.account_key≡"expenses:market"}¨parsedDeclarations.accounts)/{𝕩.default_envelope}¨parsedDeclarations.accounts
"ok" lib.AssertEq (converter.DeclarationParity ⟨parsedDeclarations,resolved⟩).state

# Declaration parity is exact and independently detects each represented field.
Decl ← {𝕊 key‿role‿kind‿envelope: {account_key⇐key,role⇐role,kind⇐kind,default_envelope⇐envelope}}
expectedDecls ← ⟨
  Decl ⟨"assets:orchard","asset","liquid",""⟩,
  Decl ⟨"expenses:market","expense","","daily"⟩,
  Decl ⟨"expenses:studio","expense","",""⟩,
  Decl ⟨"income:workshop","income","",""⟩
⟩
Commodity ← {𝕊 value: {commodity⇐value}}
AssertDeclarationFailure ← {𝕊 decls‿commodities‿code:
  parity ← converter.DeclarationParity ⟨{accounts⇐decls,commodities⇐commodities},resolved⟩
  "error" lib.AssertEq parity.state
  lib.Assert ∨´0∾{𝕩.code≡code}¨parity.diagnostics
}
roleMismatch ← ⟨Decl ⟨"assets:orchard","expense","liquid",""⟩⟩ ∾ 1↓expectedDecls
AssertDeclarationFailure ⟨roleMismatch,⟨Commodity "JPY"⟩,"account_declaration_parity_failed"⟩
kindMismatch ← ⟨Decl ⟨"assets:orchard","asset","other",""⟩⟩ ∾ 1↓expectedDecls
AssertDeclarationFailure ⟨kindMismatch,⟨Commodity "JPY"⟩,"account_declaration_parity_failed"⟩
envelopeMismatch ← ⟨⊑expectedDecls,Decl ⟨"expenses:market","expense","","other"⟩⟩ ∾ 2↓expectedDecls
AssertDeclarationFailure ⟨envelopeMismatch,⟨Commodity "JPY"⟩,"account_declaration_parity_failed"⟩
AssertDeclarationFailure ⟨⌽expectedDecls,⟨Commodity "JPY"⟩,"account_declaration_parity_failed"⟩
AssertDeclarationFailure ⟨expectedDecls,⟨Commodity "JPY",Commodity "JPY"⟩,"commodity_declaration_parity_failed"⟩
duplicateIdentityDiagnostics ← converter.SourceIdentityDiagnostics ⟨⟨{source_row⇐4},{source_row⇐4}⟩,"journal.tsv"⟩
1 lib.AssertEq ≠duplicateIdentityDiagnostics
"source_identity_duplicate" lib.AssertEq (⊑duplicateIdentityDiagnostics).code

# Fixed metadata order is independent of TSV metadata input order.
row1Reordered ← JoinFields (⟨"2042-03-03", "青空  市場, morning!", "assets:orchard", "expenses:market", "1200"⟩ ∾ ⌽metaAll)
reorderedSnapshot ← "# invented comment"∾lf∾lf∾row1Reordered∾lf∾"\\ another invented comment"∾lf∾row2∾lf∾row3∾lf
reordered ← converter.Convert ⟨reorderedSnapshot,"journal.tsv",accounts,cycleStart⟩
"ok" lib.AssertEq reordered.state
prefix lib.AssertEq reordered.canonical_prefix_bytes
prefix lib.AssertEq (converter.Convert ⟨snapshot,"journal.tsv",accounts,cycleStart⟩).canonical_prefix_bytes
prefix lib.AssertEq (converter.Convert ⟨snapshot,"journal.tsv",⌽accounts,cycleStart⟩).canonical_prefix_bytes

# Existing strict behavior remains strict while converter validation uses the
# explicit historical profile for the synthetic external plan reference.
"error" lib.AssertEq (parser.Parse prefix).state
"ok" lib.AssertEq (parser.ParseWithProfile ⟨prefix,"historical_external_plan"⟩).state

# Cube, TBDS, Trial Balance, and Balances parity over independent route rows.
cy ← {start⇐"2042-03-01",end_exclusive⇐"2042-04-01",day_count⇐31,mode⇐"fixed"}
legacyView ← context.BuildPeriodView ⟨converted.legacy_posting_rows,resolved,cy⟩
journalView ← context.BuildPeriodView ⟨converted.posting_rows,resolved,cy⟩
legacyView.cube.cube lib.AssertEq journalView.cube.cube
TbdsFields ← {𝕊 row: ⟨<row.account_key,row.layer_index,row.opening,row.debit_movement,row.credit_movement,row.movement,row.closing⟩}
(TbdsFields¨legacyView.tbds) lib.AssertEq TbdsFields¨journalView.tbds
legacyCtx ← {cy⇐cy,resolved⇐resolved,tbds⇐legacyView.tbds}
journalCtx ← {cy⇐cy,resolved⇐resolved,tbds⇐journalView.tbds}
legacyTrial ← trial.Build ⟨legacyCtx,cube.layer_actual⟩
journalTrial ← trial.Build ⟨journalCtx,cube.layer_actual⟩
⟨<legacyTrial.accounts,<legacyTrial.openings,<legacyTrial.debits,<legacyTrial.credits,<legacyTrial.closings⟩ lib.AssertEq ⟨<journalTrial.accounts,<journalTrial.openings,<journalTrial.debits,<journalTrial.credits,<journalTrial.closings⟩
(balances.Build legacyCtx) lib.AssertEq balances.Build journalCtx

HasCode ← {𝕊 code‿result: ∨´0∾{𝕩.code≡code}¨result.diagnostics}
AssertFailure ← {𝕊 badSnapshot‿code:
  failed ← converter.Convert ⟨badSnapshot,"journal.tsv",accounts,cycleStart⟩
  "error" lib.AssertEq failed.state
  "" lib.AssertEq failed.canonical_prefix_bytes
  0 lib.AssertEq ≠failed.posting_rows
  lib.Assert HasCode ⟨code,failed⟩
}
MakeOne ← {𝕊 date‿description‿from‿to‿amount‿metas:
  (JoinFields ⟨date,description,from,to,amount⟩∾metas)∾lf
}
AssertFailure ⟨"broken"∾lf,"tsv_required_fields_missing"⟩
"ok" lib.AssertEq (converter.Convert ⟨snapshot,"journal.tsv",accounts,cycleStart⟩).state
{𝕊 identity:
  failedIdentity ← converter.Convert ⟨snapshot,identity,accounts,cycleStart⟩
  "error" lib.AssertEq failedIdentity.state
  lib.Assert HasCode ⟨"source_file_identity_invalid",failedIdentity⟩
}¨ ⟨"directory/file","C:\path","\\server\share"⟩
AssertFailure ⟨MakeOne ⟨"2042-02-30","Bad date","assets:orchard","expenses:market","1",⟨⟩⟩,"date_invalid"⟩
AssertFailure ⟨MakeOne ⟨"2042-03-01","Bad amount","assets:orchard","expenses:market","1.5",⟨⟩⟩,"amount_not_exact_integer_jpy"⟩
AssertFailure ⟨MakeOne ⟨"2042-03-01","Unknown account","assets:missing","expenses:market","1",⟨⟩⟩,"account_unresolved"⟩
incompatibleAccounts ← ⟨"assets:orchard"∾tab∾"role=asset"∾tab∾"currency=ILS","expenses:market"∾tab∾"role=expense"⟩
incompatible ← converter.Convert ⟨MakeOne ⟨"2042-03-01","Incompatible account currency","assets:orchard","expenses:market","1",⟨⟩⟩,"journal.tsv",incompatibleAccounts,cycleStart⟩
"error" lib.AssertEq incompatible.state
lib.Assert HasCode ⟨"account_currency_incompatible",incompatible⟩
duplicateAccountMetadata ← ⟨"assets:orchard"∾tab∾"role=asset"∾tab∾"role=expense","expenses:market"∾tab∾"role=expense"⟩
duplicateRegistry ← converter.Convert ⟨MakeOne ⟨"2042-03-01","Duplicate account metadata","assets:orchard","expenses:market","1",⟨⟩⟩,"journal.tsv",duplicateAccountMetadata,cycleStart⟩
"error" lib.AssertEq duplicateRegistry.state
lib.Assert HasCode ⟨"account_metadata_duplicate",duplicateRegistry⟩
# Description admission is intentionally distinct from SafeValue: leading ASCII
# SPACE is source-owned and must survive converter rendering and Stage 1 exactly.
AssertLeadingAdmission ← {𝕊 description‿dateText:
  leadingSnapshot ← MakeOne ⟨dateText,description,"assets:orchard","expenses:market","1",⟨⟩⟩
  leading ← converter.Convert ⟨leadingSnapshot,"journal.tsv",accounts,cycleStart⟩
  "ok" lib.AssertEq leading.state
  0 lib.AssertEq ≠leading.diagnostics
  lib.Assert 0 < +´ (dateText∾" * "∾description∾lf) ⍷ leading.canonical_prefix_bytes
  leadingParsed ← parser.ParseWithProfile ⟨leading.canonical_prefix_bytes,"historical_external_plan"⟩
  "ok" lib.AssertEq leadingParsed.state
  0 lib.AssertEq ≠leadingParsed.diagnostics
  description lib.AssertEq (⊑leadingParsed.transactions).description
  description lib.AssertEq (⊑leading.transactions).description
  1 lib.AssertEq leading.validation_summary.parser_pass
  1 lib.AssertEq leading.validation_summary.stage2a_pass
  1 lib.AssertEq leading.validation_summary.stage2b_pass
  1 lib.AssertEq leading.validation_summary.accounting_parity_pass
  1 lib.AssertEq leading.validation_summary.identity_parity_pass
  1 lib.AssertEq leading.validation_summary.metadata_parity_pass
}
oneLeadingSynthetic ← " Leading synthetic description"
twoLeadingSynthetic ← "  Leading synthetic description"
lib.Assert converter.DescriptionRepresentable oneLeadingSynthetic
lib.Assert converter.DescriptionRepresentable twoLeadingSynthetic
AssertLeadingAdmission ⟨oneLeadingSynthetic,"2042-03-06"⟩
AssertLeadingAdmission ⟨twoLeadingSynthetic,"2042-03-07"⟩

# Empty, trailing ASCII SPACE, C0 controls, and DEL remain rejected.
AssertFailure ⟨MakeOne ⟨"2042-03-01","","assets:orchard","expenses:market","1",⟨⟩⟩,"description_not_canonically_representable"⟩
AssertFailure ⟨MakeOne ⟨"2042-03-01","trailing ","assets:orchard","expenses:market","1",⟨⟩⟩,"description_not_canonically_representable"⟩
lib.Assert ¬converter.DescriptionRepresentable "tab"∾tab∾"inside"
lib.Assert ¬converter.DescriptionRepresentable "line"∾lf∾"inside"
lib.Assert ¬converter.DescriptionRepresentable "carriage"∾(@+13)∾"inside"
AssertFailure ⟨MakeOne ⟨"2042-03-01","carriage"∾(@+13)∾"inside","assets:orchard","expenses:market","1",⟨⟩⟩,"description_not_canonically_representable"⟩
lib.Assert ¬converter.DescriptionRepresentable "nul"∾(@+0)∾"inside"
AssertFailure ⟨MakeOne ⟨"2042-03-01","nul"∾(@+0)∾"inside","assets:orchard","expenses:market","1",⟨⟩⟩,"description_not_canonically_representable"⟩
lib.Assert ¬converter.DescriptionRepresentable "del"∾(@+127)∾"inside"
AssertFailure ⟨MakeOne ⟨"2042-03-01","del"∾(@+127)∾"inside","assets:orchard","expenses:market","1",⟨⟩⟩,"description_not_canonically_representable"⟩
AssertFailure ⟨MakeOne ⟨"2042-03-01","Unknown metadata","assets:orchard","expenses:market","1",⟨"mystery=value"⟩⟩,"metadata_unknown"⟩
AssertFailure ⟨MakeOne ⟨"2042-03-01","Duplicate metadata","assets:orchard","expenses:market","1",⟨"tax=private","tax=business"⟩⟩,"metadata_duplicate"⟩
AssertFailure ⟨MakeOne ⟨"2042-03-01","Empty metadata","assets:orchard","expenses:market","1",⟨"note="⟩⟩,"metadata_value_invalid"⟩
AssertFailure ⟨MakeOne ⟨"2042-03-01","Leading metadata remains unsafe","assets:orchard","expenses:market","1",⟨"note= leading"⟩⟩,"metadata_value_invalid"⟩
AssertFailure ⟨MakeOne ⟨"2042-03-01","Controlled metadata","assets:orchard","expenses:market","1",⟨"biz=yes"⟩⟩,"metadata_value_invalid"⟩
AssertFailure ⟨MakeOne ⟨"2042-03-01","Foreign currency","assets:orchard","expenses:market","1",⟨"currency=ILS"⟩⟩,"metadata_value_invalid"⟩

# A native three-posting suffix is copied, not rendered. It starts with one LF,
# creating the required blank line without changing either operand.
suffix ← lf ∾ "2042-03-06 * Native split suffix" ∾ lf ∾ "    ; event-id: native-suffix-public-001" ∾ lf ∾ "    ; layer: actual" ∾ lf ∾ "    expenses:market 40 JPY" ∾ lf ∾ "    expenses:studio 60 JPY" ∾ lf ∾ "    assets:orchard -100 JPY" ∾ lf
reconstructed ← converter.Reconstruct ⟨converted,suffix,resolved,cycleStart⟩
"ok" lib.AssertEq reconstructed.state
(prefix∾suffix) lib.AssertEq reconstructed.reconstructed_candidate_bytes
1 lib.AssertEq +´ suffix ⍷ reconstructed.reconstructed_candidate_bytes
4 lib.AssertEq reconstructed.validation_summary.transaction_count
9 lib.AssertEq reconstructed.validation_summary.posting_count
suffix lib.AssertEq (≠prefix)↓reconstructed.reconstructed_candidate_bytes
mixedAccounts ← accounts ∾ ⟨"assets:foreign"∾tab∾"role=asset"∾tab∾"currency=ILS"⟩
mixedConverted ← converter.Convert ⟨snapshot,"journal.tsv",mixedAccounts,cycleStart⟩
"ok" lib.AssertEq mixedConverted.state
foreignSuffix ← lf ∾ "2042-03-06 * Native foreign suffix" ∾ lf ∾ "    ; event-id: native-suffix-public-foreign" ∾ lf ∾ "    ; layer: actual" ∾ lf ∾ "    expenses:market 40 JPY" ∾ lf ∾ "    assets:foreign 60 JPY" ∾ lf ∾ "    assets:orchard -100 JPY" ∾ lf
foreignReconstruction ← converter.Reconstruct ⟨mixedConverted,foreignSuffix,ak.Resolve mixedAccounts,cycleStart⟩
"error" lib.AssertEq foreignReconstruction.state
"" lib.AssertEq foreignReconstruction.reconstructed_candidate_bytes
lib.Assert HasCode ⟨"account_currency_incompatible",foreignReconstruction⟩

badVerified ← {state⇐"error",canonical_prefix_bytes⇐""}
failedReconstruction ← converter.Reconstruct ⟨badVerified,suffix,resolved,cycleStart⟩
"error" lib.AssertEq failedReconstruction.state
"" lib.AssertEq failedReconstruction.reconstructed_candidate_bytes
lib.Assert HasCode ⟨"verified_prefix_required",failedReconstruction⟩
duplicateSuffix ← converter.Reconstruct ⟨converted,suffix∾suffix,resolved,cycleStart⟩
"error" lib.AssertEq duplicateSuffix.state
"" lib.AssertEq duplicateSuffix.reconstructed_candidate_bytes
lib.Assert HasCode ⟨"suffix_transaction_duplicate",duplicateSuffix⟩

SuffixTransaction ← {𝕊 eventId‿description:
  ∾ ⟨
    lf, "2042-03-07 * ", description, lf,
    "    ; event-id: ", eventId, lf, "    ; layer: actual", lf,
    "    expenses:market 1 JPY", lf, "    assets:orchard -1 JPY", lf
  ⟩
}
prefixIdentitySuffix ← SuffixTransaction ⟨"legacy:journal.tsv:0","Prefix identity duplicate"⟩
prefixIdentityDuplicate ← converter.Reconstruct ⟨converted,prefixIdentitySuffix,resolved,cycleStart⟩
"error" lib.AssertEq prefixIdentityDuplicate.state
lib.Assert HasCode ⟨"suffix_transaction_duplicate",prefixIdentityDuplicate⟩
withinSuffixBlock ← SuffixTransaction ⟨"native-suffix-public-duplicate","Suffix duplicate one"⟩
withinSuffixBlock ∾↩ SuffixTransaction ⟨"native-suffix-public-duplicate","Suffix duplicate two"⟩
withinSuffixDuplicate ← converter.Reconstruct ⟨converted,withinSuffixBlock,resolved,cycleStart⟩
"error" lib.AssertEq withinSuffixDuplicate.state
lib.Assert HasCode ⟨"suffix_transaction_duplicate",withinSuffixDuplicate⟩

•Out "test_journal_canonical_prefix_converter.bqn: OK"
