# Effectful canonical Household adapter for the read-only Home calendar.
#
# This CLI owns only one observation lifetime and delegates admission, Plan/Issue
# semantics, Cycle resolution, transaction-row projection, and presentation to
# their existing owners.

sources ← •Import "report_source_adapter.bqn"
cycleResolution ← •Import "cycle_resolution.bqn"
compose ← •Import "../report/compose.bqn"
plannedSection ← •Import "../sections/planned_payments.bqn"
home ← •Import "../sections/home_calendar.bqn"
transactionRows ← •Import "../ledger/transaction_rows.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
today ← •Import "date_today.bqn"
tab ← @+9

Fail ← {𝕊 code‿message:•Out "ERROR"∾tab∾code∾tab∾message ⋄ •Exit 1}
PrintDiagnostics ← {𝕊 diagnostics:
  {𝕊 diagnostic:•Out "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message}¨diagnostics
  •Exit 1
}
CycleFailure ← {𝕊 resolved:
  {𝕊:PrintDiagnostics resolved.diagnostics}⍟(0<≠resolved.diagnostics) @
  message ← "Home calendar Cycle resolution failed"
  {𝕊:message↩resolved.reason}⍟((resolved.state≡"unavailable") ∧ 0<≠resolved.reason) @
  Fail ⟨"home_cycle_resolution_failed",message⟩
}
PublicationFailure ← {𝕊 publication‿fallback:
  {𝕊:PrintDiagnostics publication.diagnostics}⍟(0<≠publication.diagnostics) @
  Fail ⟨fallback,"Home calendar dependency publication failed"⟩
}

args ← •args
{𝕊:Fail ⟨"usage","expected BASE [FOCUS_DATE] [calendar|detail|choices]"⟩}⍟((1>≠args) ∨ 3<≠args) @
base ← 0⊑args
focus ← today.Today @
{𝕊:focus↩1⊑args}⍟(2≤≠args) @
mode ← "calendar"
{𝕊:mode↩2⊑args}⍟(3=≠args) @
modeValid ← (mode≡"calendar") ∨ (mode≡"detail") ∨ mode≡"choices"
{𝕊:Fail ⟨"home_mode_invalid","third argument must be calendar, detail, or choices"⟩}⍟(¬modeValid) @
{𝕊:Fail ⟨"home_focus_date_invalid","FOCUS_DATE must be strict YYYY-MM-DD"⟩}⍟(¬dates.IsValid focus) @

registryResult ← sources.Registry "config/currencies.tsv"
{𝕊:Fail ⟨registryResult.code,registryResult.message⟩}⍟(registryResult.state≢"ok") @
registry ← registryResult.registry

actual ← sources.CanonicalActual ⟨base,registry⟩
{𝕊:PrintDiagnostics actual.diagnostics}⍟(actual.state≢"ok") @

policy ← sources.CanonicalReportPolicy base
{𝕊:PrintDiagnostics policy.diagnostics}⍟(policy.state≢"ok") @

context ← sources.HouseholdContext ⟨base,actual.facts.accounts,registry⟩
{𝕊:PrintDiagnostics context.diagnostics}⍟(context.state≢"ok") @

cycle ← cycleResolution.WithPlan ⟨context.household.cycle,focus,actual.facts,context.plan⟩
{𝕊:CycleFailure cycle}⍟(cycle.state≢"ok") @

# The displayed calendar focus is not the Planned Payments evidence clock.
# Ask the Planned semantic owner for its evidence observation inside this Cycle.
evidenceObservation ← plannedSection.EvidenceObservation ⟨actual.facts,cycle⟩
planned ← compose.Planned ⟨context.plan,actual.facts,cycle,evidenceObservation⟩
{𝕊:PublicationFailure ⟨planned,"home_planned_payments_failed"⟩}⍟(planned.state≢"ok") @

issues ← compose.Issues ⟨sources.IssueLines base,registry⟩
{𝕊:PublicationFailure ⟨issues,"home_issues_failed"⟩}⍟(issues.state≢"ok") @

calendar ← home.Build ⟨actual.facts,planned.result,issues.result,cycle,focus⟩
{𝕊:PrintDiagnostics calendar.diagnostics}⍟(calendar.state≢"ok") @

output ← home.FormatHuman ⟨calendar,policy.presentation.calendar⟩
{𝕊:output↩home.FormatChoices ⟨calendar,policy.presentation.calendar⟩}⍟(mode≡"choices") @
{𝕊:
  typedRows ← transactionRows.Build actual.facts
  {𝕊:PrintDiagnostics typedRows.diagnostics}⍟(typedRows.state≢"ok") @
  selected ← home.BuildDetail ⟨calendar,typedRows,planned.result,issues.result,cycle,focus⟩
  {𝕊:PrintDiagnostics selected.diagnostics}⍟(selected.state≢"ok") @
  output↩home.FormatDetailHuman selected
}⍟(mode≡"detail") @

# Home formatters own their final LF; remove it before •Out adds the process newline.
•Out ¯1↓output