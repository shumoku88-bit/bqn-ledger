#!/usr/bin/env bqn
# Non-canonical Issue relation cross-source reference characterization.
#
# This deliberately does not add a ninth Household source or production owner.
# It starts from already-admitted relation values and already-admitted identity
# collections. Actual IDs supplied here mean source-durable event identities,
# never physical source fallback identities.

lib ← •Import "test_lib.bqn"
relation ← •Import "../src/ledger/issue_relation_admission.bqn"

empty ← ⟨⟩
tab ← @+9
planKinds ← ⟨"concerns-plan","planned-as","planning-withdrawn"⟩
actualKinds ← ⟨"realized-as","funded-by"⟩
Tsv ← {𝕊 fields: 1↓∾tab⊸∾¨fields}
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 code‿eventId‿message:
  {stage⇐"issue_relation_reference_characterization",code⇐code,relation_event_id⇐eventId,message⇐message}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}

# Synthetic candidate for the future pure Household-level reference owner.
# There is intentionally no lifecycle or filesystem input here.
AdmitReferences ← {𝕊 relations‿issueIds‿planIds‿durableActualIds:
  diagnostics ← empty
  {𝕊 i:
    eventId ← i⊑relations.relation_event_id
    issueId ← i⊑relations.issue_id
    kind ← i⊑relations.relation_kind
    target ← i⊑relations.target_id
    issueKnown ← Contains ⟨issueId,issueIds⟩
    planRelation ← Contains ⟨kind,planKinds⟩
    planKnown ← Contains ⟨target,planIds⟩
    actualRelation ← Contains ⟨kind,actualKinds⟩
    actualKnown ← Contains ⟨target,durableActualIds⟩
    diagnostics ∾↩ AddIf ⟨¬issueKnown,
      Diagnostic ⟨"issue_relation_issue_unknown",eventId,"relation issue_id must name an admitted Issue"⟩⟩
    diagnostics ∾↩ AddIf ⟨planRelation ∧ ¬planKnown,
      Diagnostic ⟨"issue_relation_plan_target_unknown",eventId,"Plan relation target must name an admitted PlanId"⟩⟩
    diagnostics ∾↩ AddIf ⟨actualRelation ∧ ¬actualKnown,
      Diagnostic ⟨"issue_relation_actual_target_unknown",eventId,"Actual relation target must name a source-durable Actual event-id"⟩⟩
  }¨↕relations.count
  qualified ← @
  {𝕊: qualified↩relations}⍟(0=≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",relations⇐qualified,diagnostics⇐diagnostics}
}

Admitted ← {𝕊 rows:
  admitted ← relation.Admit rows
  "ok" lib.AssertEq admitted.state
  admitted.relations
}

header ← relation.header
source ← ⟨
  header,
  Tsv ⟨"rel-001","2026-08-13","issue-001","concerns-plan","plan-old","historical plan"⟩,
  Tsv ⟨"rel-002","2026-08-13","issue-001","planning-withdrawn","plan-old","withdraw relation"⟩,
  Tsv ⟨"rel-003","2026-08-13","issue-001","planned-as","plan-new","replacement plan"⟩,
  Tsv ⟨"rel-004","2026-08-13","issue-001","funded-by","actual-transfer","funding event"⟩,
  Tsv ⟨"rel-005","2026-08-13","issue-001","realized-as","actual-payment","payment event"⟩
⟩
relations ← Admitted source
knownIssues ← ⟨"issue-001"⟩
knownPlans ← ⟨"plan-old","plan-new"⟩
durableActuals ← ⟨"actual-transfer","actual-payment"⟩

accepted ← AdmitReferences ⟨relations,knownIssues,knownPlans,durableActuals⟩
"ok" lib.AssertEq accepted.state
relations.relation_event_id lib.AssertEq accepted.relations.relation_event_id

unknownIssueRelations ← Admitted ⟨
  header,
  Tsv ⟨"rel-issue","2026-08-13","issue-missing","concerns-plan","plan-old","unknown issue"⟩
⟩
unknownIssue ← AdmitReferences ⟨unknownIssueRelations,knownIssues,knownPlans,durableActuals⟩
"error" lib.AssertEq unknownIssue.state
⟨"issue_relation_issue_unknown"⟩ lib.AssertEq {𝕩.code}¨unknownIssue.diagnostics

unknownPlanRelations ← Admitted ⟨
  header,
  Tsv ⟨"rel-plan","2026-08-13","issue-001","concerns-plan","plan-missing","unknown plan"⟩
⟩
unknownPlan ← AdmitReferences ⟨unknownPlanRelations,knownIssues,knownPlans,durableActuals⟩
"error" lib.AssertEq unknownPlan.state
⟨"issue_relation_plan_target_unknown"⟩ lib.AssertEq {𝕩.code}¨unknownPlan.diagnostics

fallbackActualRelations ← Admitted ⟨
  header,
  Tsv ⟨"rel-actual","2026-08-13","issue-001","realized-as","stage0-line-42","physical fallback is not durable"⟩
⟩
fallbackActual ← AdmitReferences ⟨fallbackActualRelations,knownIssues,knownPlans,durableActuals⟩
"error" lib.AssertEq fallbackActual.state
⟨"issue_relation_actual_target_unknown"⟩ lib.AssertEq {𝕩.code}¨fallbackActual.diagnostics

# Historical Plan identity remains valid regardless of current active/retired
# projection because this law consumes all admitted Plan IDs, not an active set.
historicalPlanRelations ← Admitted ⟨
  header,
  Tsv ⟨"rel-history","2026-08-13","issue-001","concerns-plan","plan-old","old plan remains historical evidence"⟩
⟩
historicalPlan ← AdmitReferences ⟨historicalPlanRelations,knownIssues,knownPlans,durableActuals⟩
"ok" lib.AssertEq historicalPlan.state

# planning-withdrawn only requires target existence here. A future operation that
# also retires the Plan belongs to coordinated writer law, not read admission.
withdrawnRelations ← Admitted ⟨
  header,
  Tsv ⟨"rel-withdrawn","2026-08-13","issue-001","planning-withdrawn","plan-old","no retirement state required"⟩
⟩
withdrawn ← AdmitReferences ⟨withdrawnRelations,knownIssues,knownPlans,durableActuals⟩
"ok" lib.AssertEq withdrawn.state

•Out "test_ledger_issue_relation_reference_laws: ok"
