#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
issues ← •Import "../src/ledger/issue_admission.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry

tab ← @+9
Tsv ← {𝕊 fields: 1↓∾tab⊸∾¨fields}
CheckOk ← {𝕊 label‿value:
  {𝕊:
    •Out "DEBUG " ∾ label ∾ " state=" ∾ value.state
    {𝕊 diagnostic: •Out diagnostic.code ∾ " row=" ∾ (•Fmt diagnostic.source_row) ∾ ": " ∾ diagnostic.message}¨ value.diagnostics
    •Exit 1
  }⍟(value.state≢"ok") @
}

lines ← loader.ReadLines "fixtures/ledger-facts-phase1-proof/issues.destination.tsv"
result ← issues.Admit ⟨lines,registry⟩
CheckOk ⟨"legacy fixture",result⟩
"ok" lib.AssertEq result.state
3 lib.AssertEq result.issues.count
⟨"subscription-review","missing-receipt","resolved-demo"⟩ lib.AssertEq result.issues.issue_id
⟨"open","open","resolved"⟩ lib.AssertEq result.issues.status
⟨"undetermined","undetermined","undetermined"⟩ lib.AssertEq result.issues.due
⟨1,0,1⟩ lib.AssertEq result.issues.amount_present
123 lib.AssertEq 0⊑result.issues.coefficient
1 lib.AssertEq 0⊑result.issues.scale
"ILS" lib.AssertEq 0⊑result.issues.currency
⟨⟩ lib.AssertEq 1⊑result.issues.coefficient
⟨⟩ lib.AssertEq 1⊑result.issues.date_ordinal
⟨⟩ lib.AssertEq 0⊑result.issues.due_ordinal
"issues.tsv:row:2" lib.AssertEq 0⊑result.issues.source_ref

legacyHeader ← Tsv ⟨"issue_id","status","date","category","title","amount","currency","details"⟩
dueHeader ← Tsv ⟨"issue_id","status","date","due","category","title","amount","currency","details"⟩

emptyLegacy ← issues.Admit ⟨⟨legacyHeader⟩,registry⟩
CheckOk ⟨"empty legacy",emptyLegacy⟩
"ok" lib.AssertEq emptyLegacy.state
0 lib.AssertEq emptyLegacy.issues.count
emptyDue ← issues.Admit ⟨⟨dueHeader⟩,registry⟩
CheckOk ⟨"empty due",emptyDue⟩
"ok" lib.AssertEq emptyDue.state
0 lib.AssertEq emptyDue.issues.count
absent ← issues.Admit ⟨⟨⟩,registry⟩
CheckOk ⟨"absent",absent⟩
"ok" lib.AssertEq absent.state
0 lib.AssertEq absent.issues.count

knownRow ← Tsv ⟨"known","open","2026-08-01","2026-08-15","want","Auction item","1000","JPY","buy if still available"⟩
knownFields ← loader.SplitTsvKeepEmpty knownRow
"2026-08-15" lib.AssertEq 3⊑knownFields
lib.Assert dates.IsValid 3⊑knownFields

current ← issues.Admit ⟨
  ⟨
    dueHeader,
    knownRow,
    Tsv ⟨"none","open","2026-08-02","none","want","Bookshelf","","","no deadline"⟩,
    Tsv ⟨"unknown","open","2026-08-03","undetermined","waiting","Repair date","","","waiting for reply"⟩
  ⟩,
  registry
⟩
CheckOk ⟨"due-aware fixture",current⟩
"ok" lib.AssertEq current.state
⟨"2026-08-15","none","undetermined"⟩ lib.AssertEq current.issues.due
lib.Assert 0<≠0⊑current.issues.due_ordinal
⟨⟩ lib.AssertEq 1⊑current.issues.due_ordinal
⟨⟩ lib.AssertEq 2⊑current.issues.due_ordinal

Reject ← {𝕊 rows‿code:
  rejected ← issues.Admit ⟨rows,registry⟩
  "error" lib.AssertEq rejected.state
  0 lib.AssertEq rejected.issues.count
  lib.Assert ∨´code⊸≡¨{𝕩.code}¨rejected.diagnostics
}
h ← legacyHeader
Reject ⟨⟨h,Tsv ⟨"x","pending","2026-01-01","decision","Title","","","Details"⟩⟩,"issue_status_invalid"⟩
Reject ⟨⟨h,Tsv ⟨"x","open","2026-02-30","decision","Title","","","Details"⟩⟩,"issue_date_invalid"⟩
Reject ⟨⟨h,Tsv ⟨"x","open","","decision","Title","10","","Details"⟩⟩,"issue_amount_currency_pair_invalid"⟩
Reject ⟨⟨h,Tsv ⟨"x","open","","decision","Title","1.234","ILS","Details"⟩⟩,"issue_amount_precision_exceeded"⟩
Reject ⟨⟨dueHeader,Tsv ⟨"x","open","2026-08-01","soon","want","Title","","","Details"⟩⟩,"issue_due_invalid"⟩
Reject ⟨⟨dueHeader,Tsv ⟨"x","open","2026-08-01","2026-02-30","want","Title","","","Details"⟩⟩,"issue_due_invalid"⟩

duplicateIssues ← issues.Admit ⟨
  ⟨
    h,
    Tsv ⟨"x","open","","decision","One","","","A"⟩,
    Tsv ⟨"y","resolved","","decision","Two","","","B"⟩,
    Tsv ⟨"x","dropped","","decision","Three","","","C"⟩
  ⟩,
  registry
⟩
"error" lib.AssertEq duplicateIssues.state
0 lib.AssertEq duplicateIssues.issues.count
1 lib.AssertEq ≠duplicateIssues.diagnostics
"issue_identity_duplicate" lib.AssertEq (⊑duplicateIssues.diagnostics).code
0 lib.AssertEq (⊑duplicateIssues.diagnostics).source_row

•Out "test_ledger_issue_admission: ok"
