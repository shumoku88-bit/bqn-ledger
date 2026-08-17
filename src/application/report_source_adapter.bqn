# Key-specific application I/O adapters over the canonical eight-file Household root.

io ← •Import "source_io.bqn"
registryBuilder ← •Import "../ledger/currency_registry.bqn"
actualSource ← •Import "actual_source_adapter.bqn"
planSource ← •Import "plan_source_adapter.bqn"
entitlementSource ← •Import "entitlement_source_adapter.bqn"
envelopeSource ← •Import "envelope_source_adapter.bqn"
householdSource ← •Import "household_source_adapter.bqn"
reportPolicySource ← •Import "report_policy_source_adapter.bqn"
canonical ← •Import "canonical_household_sources.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 code‿message: {severity⇐"error",stage⇐"application_report_source_adapter",code⇐code,message⇐message}}
EnvelopeIdentityDiagnostics ← {𝕊 policy‿history:
  missing ← {¬Contains ⟨𝕩,history.registry.id⟩}¨policy.envelopes.id
  (∨´0∾missing)/⟨Diagnostic ⟨"current_envelope_identity_missing","Every current envelope.toml Envelope must occur in the stable household.toml identity universe"⟩⟩
}

Registry ← {𝕊 path: registryBuilder.Build io.ReadLines path}
CanonicalActual ← {𝕊 base‿registry: actualSource.Load ⟨base,registry⟩}
CanonicalPlan ← {𝕊 base‿registry: planSource.Load ⟨base,registry⟩}
CanonicalEntitlement ← {𝕊 base‿envelopeHistory‿registry: entitlementSource.Load ⟨base,envelopeHistory,registry⟩}
CanonicalEnvelopePolicy ← {𝕊 base‿accounts: envelopeSource.LoadPolicy ⟨base,accounts⟩}
CanonicalHousehold ← {𝕊 base‿accounts: householdSource.Load ⟨base,accounts⟩}
CanonicalHouseholdShared ← {𝕊 base‿accounts: householdSource.LoadShared ⟨base,accounts⟩}
CanonicalReportPolicy ← {𝕊 base: reportPolicySource.Load base}

Unavailable ← {𝕊: {state⇐"error",diagnostics⇐empty}}
ContextFailure ← {𝕊 diagnosticsValue: {state⇐"error",plan⇐@,plan_retirements⇐@,envelope_policy⇐@,household⇐@,envelope_history⇐@,diagnostics⇐diagnosticsValue}}
ContextSuccess ← {𝕊 planResult‿policyResult‿householdResult‿diagnosticsValue:
  {
    state⇐"ok",plan⇐planResult.facts,plan_retirements⇐planResult.retirements,
    envelope_policy⇐policyResult,household⇐householdResult.current,
    envelope_history⇐householdResult.history,diagnostics⇐diagnosticsValue
  }
}
CompanionFailure ← {𝕊 diagnosticsValue: {state⇐"error",plan⇐@,plan_retirements⇐@,entitlement⇐@,envelope_policy⇐@,household⇐@,envelope_history⇐@,diagnostics⇐diagnosticsValue}}
CompanionSuccess ← {𝕊 context‿entitlementResult‿diagnosticsValue:
  {
    state⇐"ok",plan⇐context.plan,plan_retirements⇐context.plan_retirements,
    entitlement⇐entitlementResult,envelope_policy⇐context.envelope_policy,
    household⇐context.household,envelope_history⇐context.envelope_history,
    diagnostics⇐diagnosticsValue
  }
}

HouseholdContext ← {𝕊 base‿accounts‿registry:
  planResult ← planSource.LoadFromAccounts ⟨base,accounts,registry⟩
  policyResult ← CanonicalEnvelopePolicy ⟨base,accounts⟩
  householdResult ← CanonicalHouseholdShared ⟨base,accounts⟩
  identityDiagnostics ← ((policyResult.state≡"ok") ∧ householdResult.state≡"ok")◶⟨
    {𝕊: empty},
    {𝕊: EnvelopeIdentityDiagnostics ⟨policyResult,householdResult.history⟩}
  ⟩ @
  diagnostics ← planResult.diagnostics ∾ policyResult.diagnostics ∾ householdResult.diagnostics ∾ identityDiagnostics
  ok ← (planResult.state≡"ok") ∧ (policyResult.state≡"ok") ∧ (householdResult.state≡"ok") ∧ 0=≠identityDiagnostics
  ok◶⟨
    {𝕊: ContextFailure diagnostics},
    {𝕊: ContextSuccess ⟨planResult,policyResult,householdResult,diagnostics⟩}
  ⟩ @
}

Companions ← {𝕊 base‿accounts‿registry:
  context ← HouseholdContext ⟨base,accounts,registry⟩
  entitlementResult ← (context.state≡"ok")◶⟨
    {𝕊: Unavailable @},
    {𝕊: CanonicalEntitlement ⟨base,context.envelope_history,registry⟩}
  ⟩ @
  diagnostics ← context.diagnostics ∾ entitlementResult.diagnostics
  ok ← (context.state≡"ok") ∧ entitlementResult.state≡"ok"
  ok◶⟨
    {𝕊: CompanionFailure diagnostics},
    {𝕊: CompanionSuccess ⟨context,entitlementResult,diagnostics⟩}
  ⟩ @
}
IssueLines ← {𝕊 base: io.ReadLines (io.JoinPath ⟨base,canonical.issues⟩)}

{
  Registry⇐Registry,CanonicalActual⇐CanonicalActual,CanonicalPlan⇐CanonicalPlan,
  CanonicalEntitlement⇐CanonicalEntitlement,CanonicalEnvelopePolicy⇐CanonicalEnvelopePolicy,
  CanonicalHousehold⇐CanonicalHousehold,CanonicalHouseholdShared⇐CanonicalHouseholdShared,
  CanonicalReportPolicy⇐CanonicalReportPolicy,
  HouseholdContext⇐HouseholdContext,Companions⇐Companions,IssueLines⇐IssueLines
}
