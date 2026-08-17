#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
io ← •Import "../src/application/source_io.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
entitlementAdmission ← •Import "../src/ledger/entitlement_journal_admission.bqn"

lf ← @+10
tab ← @+9
Raw ← {𝕊 lines: ∾lines∾¨lf}
registry ← (registryCore.Build io.ReadLines "config/currencies.tsv").registry

history ← {
  registry⇐{id⇐⟨"food","transport","savings"⟩}
}

Admit ← {𝕊 lines: entitlementAdmission.Admit ⟨Raw lines, history, registry⟩}

# 1. Empty source is valid clean epoch
emptyResult ← Admit ⟨⟩
"ok" lib.AssertEq emptyResult.state
0 lib.AssertEq emptyResult.origins.count
0 lib.AssertEq emptyResult.transfers.count
0 lib.AssertEq ≠emptyResult.declared_domains

# 2. Origin only is valid
originOnly ← Admit ⟨
  "# Pure origin declaration",
  "2026-01-01 origin USD ; clean epoch"
⟩
"ok" lib.AssertEq originOnly.state
1 lib.AssertEq originOnly.origins.count
0 lib.AssertEq originOnly.transfers.count
⟨"USD"⟩ lib.AssertEq originOnly.declared_domains
"USD" lib.AssertEq ⊑originOnly.origins.commodity
"clean epoch" lib.AssertEq ⊑originOnly.origins.memo
(dates.Ordinal "2026-01-01") lib.AssertEq ⊑originOnly.origins.date_ordinal
2 lib.AssertEq ⊑originOnly.origins.source_line
"entitlement.journal:line:2" lib.AssertEq ⊑originOnly.origins.source_event_id

# 3. Canonical origin + transfers
validFlow ← Admit ⟨
  "2026-01-01 origin USD ; epoch start",
  "2026-01-01 transfer unallocated -> food 100 USD ; initial allocation",
  "2026-01-02 transfer food -> transport 30 USD ; reallocate",
  "2026-01-03 transfer transport -> unallocated 10 USD ; release"
⟩
"ok" lib.AssertEq validFlow.state
1 lib.AssertEq validFlow.origins.count
3 lib.AssertEq validFlow.transfers.count
⟨"USD"⟩ lib.AssertEq validFlow.declared_domains
⟨"unallocated","food","transport"⟩ lib.AssertEq validFlow.transfers.from
⟨"food","transport","unallocated"⟩ lib.AssertEq validFlow.transfers.to
⟨100,30,10⟩ lib.AssertEq validFlow.transfers.coefficient
⟨"initial allocation","reallocate","release"⟩ lib.AssertEq validFlow.transfers.memo
⟨2,3,4⟩ lib.AssertEq validFlow.transfers.source_line
⟨"entitlement.journal:line:2","entitlement.journal:line:3","entitlement.journal:line:4"⟩ lib.AssertEq validFlow.transfers.source_event_id

# Entitlement admission receives only the stable Envelope identity relation and
# Currency registry. An Account-looking EnvelopeId needs no Account declaration.
accountIndependentHistory ← {registry⇐{id⇐⟨"Assets:Cash"⟩}}
accountIndependent ← entitlementAdmission.Admit ⟨Raw ⟨
  "2026-01-01 origin USD",
  "2026-01-01 transfer unallocated -> Assets:Cash 1 USD"
⟩,accountIndependentHistory,registry⟩
"ok" lib.AssertEq accountIndependent.state
⟨"Assets:Cash"⟩ lib.AssertEq accountIndependent.transfers.to

# 4. Same-day effects combine before historical nonnegative validation.
sameDay ← Admit ⟨
  "2026-01-01 origin USD",
  "2026-01-01 transfer unallocated -> food 50 USD",
  "2026-01-01 transfer food -> transport 20 USD",
  "2026-01-01 transfer unallocated -> food 10 USD"
⟩
"ok" lib.AssertEq sameDay.state
3 lib.AssertEq sameDay.transfers.count

# Source order must not manufacture a same-day intermediate negative state.
# The debit appears before the grant, but the day closes food at +30 USD.
sameDayDebitFirst ← Admit ⟨
  "2026-01-01 origin USD",
  "2026-01-01 transfer food -> transport 20 USD",
  "2026-01-01 transfer unallocated -> food 50 USD"
⟩
"ok" lib.AssertEq sameDayDebitFirst.state
2 lib.AssertEq sameDayDebitFirst.transfers.count

# 5. Memo lexical semantics match the shared canonical contract.
bareMemo ← Admit ⟨
  "2026-01-01 origin USD bare origin memo"
⟩
"ok" lib.AssertEq bareMemo.state
"bare origin memo" lib.AssertEq ⊑bareMemo.origins.memo

decoratedMemo ← Admit ⟨
  "2026-01-01 origin USD ; decorated origin memo"
⟩
"ok" lib.AssertEq decoratedMemo.state
"decorated origin memo" lib.AssertEq ⊑decoratedMemo.origins.memo

internalMemo ← Admit ⟨
  "2026-01-01 origin USD clean ; epoch # one",
  "2026-01-01 transfer unallocated -> food 10 USD payment ; revised # kept"
⟩
"ok" lib.AssertEq internalMemo.state
"clean ; epoch # one" lib.AssertEq ⊑internalMemo.origins.memo
"payment ; revised # kept" lib.AssertEq ⊑internalMemo.transfers.memo

tabSeparated ← Admit ⟨
  "2026-01-01"∾⟨tab⟩∾"origin"∾⟨tab⟩∾"USD ; tab separated memo"
⟩
"ok" lib.AssertEq tabSeparated.state
"tab separated memo" lib.AssertEq ⊑tabSeparated.origins.memo

# 6. Duplicate origin for same commodity fails closed
dupOrigin ← Admit ⟨
  "2026-01-01 origin USD ; first",
  "2026-01-02 origin USD ; duplicate"
⟩
"error" lib.AssertEq dupOrigin.state
"entitlement_origin_duplicate" lib.AssertEq (⊑dupOrigin.diagnostics).code

# 7. Transfer without origin fails closed
missingOrigin ← Admit ⟨
  "2026-01-01 transfer unallocated -> food 50 USD"
⟩
"error" lib.AssertEq missingOrigin.state
"entitlement_origin_missing" lib.AssertEq (⊑missingOrigin.diagnostics).code

# 8. Transfer before origin fails closed
transferBeforeOrigin ← Admit ⟨
  "2026-01-05 origin USD",
  "2026-01-02 transfer unallocated -> food 50 USD"
⟩
"error" lib.AssertEq transferBeforeOrigin.state
"entitlement_origin_after_transfer" lib.AssertEq (⊑transferBeforeOrigin.diagnostics).code

# 9. Unknown commodity fails closed
unknownComm ← Admit ⟨
  "2026-01-01 origin XYZ"
⟩
"error" lib.AssertEq unknownComm.state
"entitlement_commodity_unknown" lib.AssertEq (⊑unknownComm.diagnostics).code

# 10. Unknown envelope identity fails closed
unknownEnvelope ← Admit ⟨
  "2026-01-01 origin USD",
  "2026-01-01 transfer unallocated -> luxury 50 USD"
⟩
"error" lib.AssertEq unknownEnvelope.state
"envelope_id_unknown" lib.AssertEq (⊑unknownEnvelope.diagnostics).code

# 11. Same endpoint fails closed
sameEndpoint ← Admit ⟨
  "2026-01-01 origin USD",
  "2026-01-01 transfer food -> food 50 USD"
⟩
"error" lib.AssertEq sameEndpoint.state
"entitlement_transfer_same_endpoint" lib.AssertEq (⊑sameEndpoint.diagnostics).code

# 12. Zero amount fails closed
zeroAmount ← Admit ⟨
  "2026-01-01 origin USD",
  "2026-01-01 transfer unallocated -> food 0 USD"
⟩
"error" lib.AssertEq zeroAmount.state
"entitlement_transfer_amount_invalid" lib.AssertEq (⊑zeroAmount.diagnostics).code

# 13. Negative amount fails closed
negAmount ← Admit ⟨
  "2026-01-01 origin USD",
  "2026-01-01 transfer unallocated -> food -50 USD"
⟩
"error" lib.AssertEq negAmount.state
"entitlement_transfer_amount_invalid" lib.AssertEq (⊑negAmount.diagnostics).code

# 14. Historical nonnegative law violation across days fails closed
negativeEntitlement ← Admit ⟨
  "2026-01-01 origin USD",
  "2026-01-01 transfer unallocated -> food 20 USD",
  "2026-01-02 transfer food -> transport 30 USD"
⟩
"error" lib.AssertEq negativeEntitlement.state
"envelope_entitlement_negative" lib.AssertEq (⊑negativeEntitlement.diagnostics).code

# 15. Forbidden source keywords fail closed
forbiddenAlloc ← Admit ⟨
  "2026-01-01 origin USD",
  "2026-01-01 alloc unallocated -> food 50 USD"
⟩
"error" lib.AssertEq forbiddenAlloc.state
"entitlement_syntax_invalid" lib.AssertEq (⊑forbiddenAlloc.diagnostics).code

forbiddenMove ← Admit ⟨
  "2026-01-01 origin USD",
  "2026-01-01 move food -> transport 10 USD"
⟩
"error" lib.AssertEq forbiddenMove.state
"entitlement_syntax_invalid" lib.AssertEq (⊑forbiddenMove.diagnostics).code

forbiddenRelease ← Admit ⟨
  "2026-01-01 origin USD",
  "2026-01-01 release food -> unallocated 10 USD"
⟩
"error" lib.AssertEq forbiddenRelease.state
"entitlement_syntax_invalid" lib.AssertEq (⊑forbiddenRelease.diagnostics).code

forbiddenStockOrigin ← Admit ⟨
  "2026-01-01 stock-origin USD"
⟩
"error" lib.AssertEq forbiddenStockOrigin.state
"entitlement_syntax_invalid" lib.AssertEq (⊑forbiddenStockOrigin.diagnostics).code

prefixLessTransfer ← Admit ⟨
  "2026-01-01 origin USD",
  "2026-01-01 unallocated -> food 50 USD"
⟩
"error" lib.AssertEq prefixLessTransfer.state
"entitlement_syntax_invalid" lib.AssertEq (⊑prefixLessTransfer.diagnostics).code

# 16. Invalid date fails closed
badDate ← Admit ⟨
  "2026-02-31 origin USD"
⟩
"error" lib.AssertEq badDate.state
"entitlement_date_invalid" lib.AssertEq (⊑badDate.diagnostics).code

•Out "test_ledger_entitlement_journal_admission: ok"