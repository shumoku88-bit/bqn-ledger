#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
issues ← •Import "../src/ledger/issue_admission.bqn"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
lines ← loader.ReadLines "fixtures/ledger-facts-phase1-proof/issues.destination.tsv"
result ← issues.Admit ⟨lines,registry⟩
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

legacyHeader ← "issue_id\tstatus\tdate\tcategory\ttitle\tamount\tcurrency\tdetails"
dueHeader ← "issue_id\tstatus\tdate\tdue\tcategory\ttitle\tamount\tcurrency\tdetails"

emptyLegacy ← issues.Admit ⟨⟨legacyHeader⟩,registry⟩
"ok" lib.AssertEq emptyLegacy.state
0 lib.AssertEq emptyLegacy.issues.count
emptyDue ← issues.Admit ⟨⟨dueHeader⟩,registry⟩
"ok" lib.AssertEq emptyDue.state
0 lib.AssertEq emptyDue.issues.count
absent ← issues.Admit ⟨⟨⟩,registry⟩
"ok" lib.AssertEq absent.state
0 lib.AssertEq absent.issues.count

current ← issues.Admit ⟨
  ⟨
    dueHeader,
    "known\topen\t2026-08-01\t2026-08-15\twant\tAuction item\t1000\tJPY\tbuy if still available",
    "none\topen\t2026-08-02\tnone\twant\tBookshelf\t\t\tno deadline",
    "unknown\topen\t2026-08-03\tundetermined\twaiting\tRepair date\t\t\twaiting for reply"
  ⟩,
  registry
⟩
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
Reject ⟨⟨h,"x\tpending\t2026-01-01\tdecision\tTitle\t\t\tDetails"⟩,"issue_status_invalid"⟩
Reject ⟨⟨h,"x\topen\t2026-02-30\tdecision\tTitle\t\t\tDetails"⟩,"issue_date_invalid"⟩
Reject ⟨⟨h,"x\topen\t\tdecision\tTitle\t10\t\tDetails"⟩,"issue_amount_currency_pair_invalid"⟩
Reject ⟨⟨h,"x\topen\t\tdecision\tTitle\t1.234\tILS\tDetails"⟩,"issue_amount_precision_exceeded"⟩
Reject ⟨⟨dueHeader,"x\topen\t2026-08-01\tsoon\twant\tTitle\t\t\tDetails"⟩,"issue_due_invalid"⟩
Reject ⟨⟨dueHeader,"x\topen\t2026-08-01\t2026-02-30\twant\tTitle\t\t\tDetails"⟩,"issue_due_invalid"⟩

duplicateIssues ← issues.Admit ⟨
  ⟨
    h,
    "x\topen\t\tdecision\tOne\t\t\tA",
    "y\tresolved\t\tdecision\tTwo\t\t\tB",
    "x\tdropped\t\tdecision\tThree\t\t\tC"
  ⟩,
  registry
⟩
"error" lib.AssertEq duplicateIssues.state
0 lib.AssertEq duplicateIssues.issues.count
1 lib.AssertEq ≠duplicateIssues.diagnostics
"issue_identity_duplicate" lib.AssertEq (⊑duplicateIssues.diagnostics).code
0 lib.AssertEq (⊑duplicateIssues.diagnostics).source_row

•Out "test_ledger_issue_admission: ok"
