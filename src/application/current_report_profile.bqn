# Pure daily-UI policy: resolve volatile coordinates over admitted report routes.
# Explicit historical routes and source coordinates remain unchanged outside the selected roles.

dates ← •Import "../ledger/date_ordinal.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"application_current_report_profile",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
NextMonthExclusive ← {𝕊 dateText:
  y‿m‿d ← dates.Parts dateText
  nextY ← y+(m=12) ⋄ nextM ← (m=12)⊑⟨m+1,1⟩
  7↑dates.FromParts ⟨nextY,nextM,1⟩
}
ReplaceCoordinateRole ← {𝕊 coordinates‿coordinateRoles‿role‿value:
  index ← ⊑(role⊸≡¨coordinateRoles)⊐1
  (index↑coordinates)∾⟨value⟩∾(index+1)↓coordinates
}
FindAdmission ← {𝕊 key‿admittedRoutes:
  (⊑(key⊸≡¨{𝕩.key}¨admittedRoutes)⊐1)⊑admittedRoutes
}
CoordinateValue ← {𝕊 role‿admitted:
  index ← ⊑(role⊸≡¨admitted.coordinate_role)⊐1
  index⊑admitted.coordinates
}
ComparisonPolicy ← {𝕊 admittedRoutes:
  cycleComparison ← FindAdmission ⟨"cycle-comparison",admittedRoutes⟩
  CoordinateValue ⟨"policy",cycleComparison⟩
}
SourceName ← {𝕊 role‿admitted:
  index ← ⊑(role⊸≡¨admitted.sources.role)⊐1
  index⊑admitted.sources.name
}
SourceNames ← {𝕊 admittedRoutes:
  cycleAccounts ← FindAdmission ⟨"cycle-accounts",admittedRoutes⟩
  cycleComparison ← FindAdmission ⟨"cycle-comparison",admittedRoutes⟩
  planned ← FindAdmission ⟨"planned",admittedRoutes⟩
  planName ← SourceName ⟨"plan",planned⟩
  cyclePlanNames ← ("plan"⊸≡¨cycleAccounts.sources.role)/cycleAccounts.sources.name
  {𝕊:planName↩⊑cyclePlanNames}⍟(1=≠cyclePlanNames) @
  {
    current_cycle⇐SourceName ⟨"cycle",cycleAccounts⟩,
    comparison_current_cycle⇐SourceName ⟨"current_cycle",cycleComparison⟩,
    baseline_cycle⇐SourceName ⟨"baseline_cycle",cycleComparison⟩,
    plan⇐planName
  }
}

Build ← {𝕊 admittedRoutes‿observation‿currentCycle‿baselineCycle:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨¬dates.IsValid observation,Diagnostic ⟨"current_observation_invalid","latest Actual observation must be strict Gregorian text"⟩⟩
  diagnostics ∾↩ AddIf ⟨currentCycle.state≢"ok",Diagnostic ⟨"current_cycle_not_ok","current Cycle must resolve at the latest Actual observation"⟩⟩
  diagnostics ∾↩ AddIf ⟨baselineCycle.state≢"ok",Diagnostic ⟨"baseline_cycle_not_ok","baseline Cycle must resolve before the current Cycle"⟩⟩
  {𝕊:
    diagnostics ∾↩ AddIf ⟨currentCycle.mode≢baselineCycle.mode,Diagnostic ⟨"comparison_cycle_mode_mismatch","current and baseline Cycle modes must agree"⟩⟩
    diagnostics ∾↩ AddIf ⟨baselineCycle.start_ordinal≥currentCycle.start_ordinal,Diagnostic ⟨"baseline_cycle_not_previous","baseline Cycle must precede the current Cycle"⟩⟩
  }⍟((currentCycle.state≡"ok") ∧ (baselineCycle.state≡"ok")) @

  baselineObservation ← ""
  {𝕊:
    observationOrdinal ← dates.Ordinal observation
    currentStart ← currentCycle.start_ordinal
    currentEnd ← currentCycle.end_exclusive_ordinal
    observationInCurrent ← (currentStart≤observationOrdinal) ∧ observationOrdinal<currentEnd
    diagnostics ∾↩ AddIf ⟨¬observationInCurrent,Diagnostic ⟨"current_observation_outside_cycle","latest Actual observation must occur inside the resolved current Cycle"⟩⟩
    {𝕊:
      elapsed ← observationOrdinal-currentStart
      baselineOrdinal ← baselineCycle.start_ordinal+elapsed
      baselineFits ← baselineOrdinal<baselineCycle.end_exclusive_ordinal
      diagnostics ∾↩ AddIf ⟨¬baselineFits,Diagnostic ⟨"aligned_baseline_unavailable","baseline Cycle cannot represent the current elapsed observation"⟩⟩
      {𝕊:baselineObservation↩dates.FromOrdinal baselineOrdinal}⍟baselineFits @
    }⍟observationInCurrent @
  }⍟((0=≠diagnostics) ∧ dates.IsValid observation) @

  resolvedRows ← empty
  {𝕊:
    {𝕊 admitted:
      key ← admitted.key ⋄ args ← admitted.coordinates ⋄ rewritten ← args
      {𝕊:rewritten↩⟨0⊑args,currentCycle.start,currentCycle.end_exclusive,observation⟩∾4↓args}⍟(key≡"envelopes") @
      {𝕊:rewritten↩ReplaceCoordinateRole ⟨args,admitted.coordinate_role,"as_of",observation⟩}⍟((key≡"balances") ∨ key≡"balance-sheet") @
      {𝕊:rewritten↩⟨0⊑args,currentCycle.start,dates.AddDays ⟨observation,1⟩,3⊑args⟩}⍟(key≡"profit-and-loss") @
      {𝕊:rewritten↩ReplaceCoordinateRole ⟨args,admitted.coordinate_role,"observation",observation⟩}⍟(key≡"planned") @
      {𝕊:rewritten↩⟨0⊑args,observation⟩∾2↓args}⍟(key≡"cycle-accounts") @
      {𝕊:rewritten↩⟨0⊑args,observation,baselineObservation,3⊑args⟩∾4↓args}⍟(key≡"cycle-comparison") @
      {𝕊:rewritten↩⟨0⊑args,1⊑args,NextMonthExclusive observation,3⊑args⟩}⍟(key≡"monthly-accounts") @
      {𝕊:rewritten↩⟨0⊑args,currentCycle.start,currentCycle.end_exclusive,observation,4⊑args⟩}⍟(key≡"daily-flow") @
      {𝕊:rewritten↩⟨0⊑args,observation⟩∾2↓args}⍟(key≡"daily-target") @
      resolvedRows∾↩⟨{key⇐key,surface⇐admitted.surface,arguments⇐rewritten}⟩
    }¨admittedRoutes
  }⍟(0=≠diagnostics) @

  {state⇐(0=≠diagnostics)⊑"error"‿"ok",observation⇐observation,rows⇐resolvedRows,diagnostics⇐diagnostics}
}

{Build⇐Build,ComparisonPolicy⇐ComparisonPolicy,SourceNames⇐SourceNames}
