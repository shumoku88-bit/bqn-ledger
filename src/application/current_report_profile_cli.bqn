# Effectful current-request adapter over the canonical Household root.
# Normal operation reads report.toml and canonical facts. Optional LATEST makes
# cache/tests deterministic without embedding a clock in pure policy resolution.

sources ← •Import "report_source_adapter.bqn"
cycleResolution ← •Import "cycle_resolution.bqn"
policyResolution ← •Import "report_policy_resolution.bqn"
requests ← •Import "current_report_requests.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
today ← •Import "date_today.bqn"
tab ← @+9

Fail ← {𝕊 code‿message:•Out "ERROR"∾tab∾code∾tab∾message ⋄ •Exit 1}
PrintDiagnostics ← {𝕊 diagnostics:{𝕊 diagnostic:•Out "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message}¨diagnostics ⋄ •Exit 1}
CycleFailure ← {𝕊 resolved‿fallback:
  {𝕊:PrintDiagnostics resolved.diagnostics}⍟(0<≠resolved.diagnostics) @
  code ← fallback ⋄ message ← "Cycle resolution failed"
  {𝕊:code↩resolved.reason ⋄ message↩resolved.reason}⍟((resolved.state≡"unavailable") ∧ 0<≠resolved.reason) @
  Fail ⟨code,message⟩
}

args ← •args
{𝕊:Fail ⟨"usage","expected BASE DOMAIN SURFACE [LATEST]"⟩}⍟((3>≠args) ∨ 4<≠args) @
base‿domain‿surface ← 3↑args
latest ← today.Today @
{𝕊:latest↩3⊑args}⍟(4=≠args) @
{𝕊:Fail ⟨"report_latest_invalid","LATEST must be strict YYYY-MM-DD"⟩}⍟(¬dates.IsValid latest) @

registryResult ← sources.Registry "config/currencies.tsv"
{𝕊:Fail ⟨registryResult.code,registryResult.message⟩}⍟(registryResult.state≢"ok") @
registry ← registryResult.registry
actual ← sources.CanonicalActual ⟨base,registry⟩
{𝕊:PrintDiagnostics actual.diagnostics}⍟(actual.state≢"ok") @
{𝕊:Fail ⟨"current_observation_missing","current profile requires at least one admitted Actual transaction"⟩}⍟(0=actual.facts.transactions.count) @
latestActualOrdinal ← ⌈´actual.facts.transactions.date_ordinal
latestActualIndex ← ⊑(latestActualOrdinal=actual.facts.transactions.date_ordinal)⊐1
observation ← latestActualIndex⊑actual.facts.transactions.date_text

policy ← sources.CanonicalReportPolicy base
{𝕊:PrintDiagnostics policy.diagnostics}⍟(policy.state≢"ok") @
resolvedPolicy ← policyResolution.Resolve ⟨policy,latest,actual.facts.transactions.date_text⟩
{𝕊:PrintDiagnostics resolvedPolicy.diagnostics}⍟(resolvedPolicy.state≢"ok") @

context ← sources.HouseholdContext ⟨base,actual.facts.accounts,registry⟩
{𝕊:PrintDiagnostics context.diagnostics}⍟(context.state≢"ok") @
currentCycle ← cycleResolution.WithPlan ⟨context.household.cycle,observation,actual.facts,context.plan⟩
{𝕊:CycleFailure ⟨currentCycle,"current_cycle_resolution_failed"⟩}⍟(currentCycle.state≢"ok") @
previousObservation ← dates.FromOrdinal currentCycle.start_ordinal-1
baselineCycle ← cycleResolution.WithPlan ⟨context.household.cycle,previousObservation,actual.facts,context.plan⟩
{𝕊:CycleFailure ⟨baselineCycle,"baseline_cycle_resolution_failed"⟩}⍟(baselineCycle.state≢"ok") @

built ← requests.Build ⟨domain,surface,resolvedPolicy,actual.facts,observation,currentCycle,baselineCycle⟩
{𝕊:PrintDiagnostics built.diagnostics}⍟(built.state≢"ok") @
•Out "key"∾tab∾"surface"∾tab∾"arguments"
{𝕊 row:•Out row.key∾tab∾row.surface∾(∾{tab∾𝕩}¨row.arguments)}¨built.rows
