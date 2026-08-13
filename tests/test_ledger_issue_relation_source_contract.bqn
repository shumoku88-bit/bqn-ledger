#!/usr/bin/env bqn
# Non-canonical Issue relation source owner contract.
#
# Production admission/rendering lives in src/ledger/issue_relation_admission.bqn.
# This test proves its six semantic coordinates without registering a canonical
# Household path or writer.

lib ← •Import "test_lib.bqn"
relation ← •Import "../src/ledger/issue_relation_admission.bqn"

tab ← @+9
Tsv ← {𝕊 fields: 1↓∾tab⊸∾¨fields}
headerLine ← relation.header

source ← ⟨
  "# synthetic relation-source characterization",
  headerLine,
  Tsv ⟨"rel-001","2026-08-13","issue-001","concerns-plan","plan-old","review current commitment"⟩,
  Tsv ⟨"rel-002","2026-08-13","issue-001","planning-withdrawn","plan-old","decision changed"⟩,
  Tsv ⟨"rel-003","2026-08-13","issue-001","planned-as","plan-new","replacement commitment"⟩,
  Tsv ⟨"rel-004","2026-08-13","issue-001","funded-by","actual-transfer","move funding first"⟩,
  Tsv ⟨"rel-005","2026-08-13","issue-001","realized-as","actual-payment","payment occurred"⟩
⟩

result ← relation.Admit source
"ok" lib.AssertEq result.state
5 lib.AssertEq result.relations.count
⟨"rel-001","rel-002","rel-003","rel-004","rel-005"⟩ lib.AssertEq result.relations.relation_event_id
⟨"2026-08-13","2026-08-13","2026-08-13","2026-08-13","2026-08-13"⟩ lib.AssertEq result.relations.recorded_on
⟨"issue-001","issue-001","issue-001","issue-001","issue-001"⟩ lib.AssertEq result.relations.issue_id
⟨"concerns-plan","planning-withdrawn","planned-as","funded-by","realized-as"⟩ lib.AssertEq result.relations.relation_kind
⟨"plan-old","plan-old","plan-new","actual-transfer","actual-payment"⟩ lib.AssertEq result.relations.target_id
⟨"review current commitment","decision changed","replacement commitment","move funding first","payment occurred"⟩ lib.AssertEq result.relations.details

roundTrip ← relation.Admit relation.Render result.relations
"ok" lib.AssertEq roundTrip.state
result.relations.relation_event_id lib.AssertEq roundTrip.relations.relation_event_id
result.relations.recorded_on lib.AssertEq roundTrip.relations.recorded_on
result.relations.issue_id lib.AssertEq roundTrip.relations.issue_id
result.relations.relation_kind lib.AssertEq roundTrip.relations.relation_kind
result.relations.target_id lib.AssertEq roundTrip.relations.target_id
result.relations.details lib.AssertEq roundTrip.relations.details

blank ← relation.Admit ⟨"","# no relation history yet"⟩
"ok" lib.AssertEq blank.state
0 lib.AssertEq blank.relations.count
⟨headerLine⟩ lib.AssertEq relation.Render blank.relations

wrongCorrection ← relation.Admit ⟨headerLine,Tsv ⟨"rel-correct","2026-08-13","issue-001","realized-as","actual-wrong","mistaken target"⟩⟩
fixedCorrection ← relation.Admit ⟨headerLine,Tsv ⟨"rel-correct","2026-08-13","issue-001","realized-as","actual-right","corrected mistaken target"⟩⟩
"ok" lib.AssertEq wrongCorrection.state
"ok" lib.AssertEq fixedCorrection.state
"rel-correct" lib.AssertEq ⊑wrongCorrection.relations.relation_event_id
"rel-correct" lib.AssertEq ⊑fixedCorrection.relations.relation_event_id
"actual-wrong" lib.AssertEq ⊑wrongCorrection.relations.target_id
"actual-right" lib.AssertEq ⊑fixedCorrection.relations.target_id

Reject ← {𝕊 rows‿code:
  rejected ← relation.Admit rows
  "error" lib.AssertEq rejected.state
  0 lib.AssertEq rejected.relations.count
  lib.Assert ∨´code⊸≡¨{𝕩.code}¨rejected.diagnostics
}

Reject ⟨⟨Tsv ⟨"id","recorded_on","issue_id","relation_kind","target_id","details"⟩⟩,"issue_relation_header_invalid"⟩
Reject ⟨⟨headerLine,Tsv ⟨"rel-001","2026-08-13","issue-001"⟩⟩,"issue_relation_field_count_invalid"⟩
Reject ⟨⟨headerLine,Tsv ⟨"rel-001","2026-02-30","issue-001","concerns-plan","plan-old","bad day"⟩⟩,"issue_relation_recorded_on_invalid"⟩
Reject ⟨⟨headerLine,Tsv ⟨"rel-001","2026-08-13","issue-001","linked-to","plan-old","generic relation forbidden"⟩⟩,"issue_relation_kind_invalid"⟩
Reject ⟨⟨headerLine,Tsv ⟨"rel-001","2026-08-13","issue-001","concerns-plan","plan old","invalid Plan identity"⟩⟩,"issue_relation_target_identity_invalid"⟩
Reject ⟨⟨headerLine,Tsv ⟨"rel-dup","2026-08-13","issue-001","concerns-plan","plan-old","first"⟩,Tsv ⟨"rel-dup","2026-08-14","issue-001","planned-as","plan-new","second"⟩⟩,"issue_relation_event_identity_duplicate"⟩
Reject ⟨⟨headerLine,Tsv ⟨"rel-001","2026-08-13","issue-001","concerns-plan","plan-old"," leading space"⟩⟩,"issue_relation_details_invalid"⟩

•Out "test_ledger_issue_relation_source_contract: ok"
