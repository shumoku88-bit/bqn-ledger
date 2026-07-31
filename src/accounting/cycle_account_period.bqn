# Pure Current-cycle Account state from resolved cycle, explicit observation, and Actual Facts.

period ← •Import "account_period.bqn"
reference ← •Import "fact_reference.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_cycle_account_period",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyAccounts ← {𝕊:
  {
    count⇐0,index⇐empty,account_index⇐empty,account_key⇐empty,
    opening⇐empty,debit_movement⇐empty,credit_movement⇐empty,movement⇐empty,closing⇐empty,
    opening_contributors⇐empty,debit_contributors⇐empty,credit_contributors⇐empty,
    movement_contributors⇐empty,closing_contributors⇐empty
  }
}
EmptyTotals ← {𝕊:
  {opening⇐empty,debit_movement⇐empty,credit_movement⇐empty,movement⇐empty,closing⇐empty,balanced⇐0}
}
EmptyResult ← {𝕊 stateValue‿domainCode‿observationText‿reasonText‿diagnosticsValue:
  {
    state⇐stateValue,reason⇐reasonText,domain⇐domainCode,observation⇐observationText,
    cycle_mode⇐"",cycle_start⇐"",cycle_end_exclusive⇐"",observed_end_exclusive_ordinal⇐empty,
    scale⇐0,accounts⇐EmptyAccounts @,totals⇐EmptyTotals @,
    cycle_start_contributors⇐empty,cycle_end_contributors⇐empty,diagnostics⇐diagnosticsValue
  }
}

# Input: canonical Actual Facts, selected domain, resolved cycle, explicit observation text.
Build ← {𝕊 facts‿domainCode‿cycle‿observationText:
  cycleDiagnostics ← cycle.diagnostics
  {𝕊: cycleDiagnostics∾↩⟨Diagnostic ⟨"cycle_not_ok","resolved cycle must be ok"⟩⟩}⍟(0=≠cycleDiagnostics) @
  result ← EmptyResult ⟨"error",domainCode,observationText,"",cycleDiagnostics⟩
  {𝕊:
    result↩EmptyResult ⟨"unavailable",domainCode,observationText,cycle.reason,empty⟩
  }⍟(cycle.state≡"unavailable") @
  {𝕊:
    diagnostics ← empty
    diagnostics ∾↩ AddIf ⟨¬reference.SourceIs ⟨facts,"actual.journal"⟩,Diagnostic ⟨"actual_facts_invalid","Actual facts must be admitted from actual.journal"⟩⟩
    observationValid ← dates.IsValid observationText
    diagnostics ∾↩ AddIf ⟨¬observationValid,Diagnostic ⟨"observation_invalid","observation must be strict Gregorian text"⟩⟩
    {𝕊:
      observationOrdinal ← dates.Ordinal observationText
      inCycle ← (cycle.start_ordinal≤observationOrdinal) ∧ observationOrdinal<cycle.end_exclusive_ordinal
      diagnostics ∾↩ AddIf ⟨¬inCycle,Diagnostic ⟨"observation_outside_cycle","observation must occur inside resolved cycle"⟩⟩
      cycleObservationMatches ← (0=≠cycle.observation) ∨ cycle.observation≡observationText
      diagnostics ∾↩ AddIf ⟨¬cycleObservationMatches,Diagnostic ⟨"cycle_observation_mismatch","observation must match observation-bound cycle resolution"⟩⟩
      {𝕊:
        observedEnd ← cycle.end_exclusive_ordinal⌊observationOrdinal+1
        accountPeriod ← period.Build ⟨facts,domainCode,"actual",cycle.start_ordinal,observedEnd⟩
        diagnostics ∾↩ accountPeriod.diagnostics
        {𝕊:
          source ← accountPeriod.accounts
          PostingReferences ← {𝕊 indices: {reference.Posting ⟨facts,𝕩⟩}¨indices}

          # a: canonical Account rows; k: opening / debit / credit / period contributor lanes.
          # Each [k,a] Posting-index cell becomes durable source-qualified references in source order.
          contributorIndexLanes ← ⟨
            source.opening_contributors,source.debit_contributors,
            source.credit_contributors,source.period_contributors
          ⟩
          contributorLanes ← {PostingReferences¨𝕩}¨contributorIndexLanes
          openingContributors‿debitContributors‿creditContributors‿movementContributors ← contributorLanes
          closingContributors ← openingContributors ∾¨ movementContributors
          result↩{
            state⇐"ok",reason⇐"",domain⇐domainCode,observation⇐observationText,
            cycle_mode⇐cycle.mode,cycle_start⇐cycle.start,cycle_end_exclusive⇐cycle.end_exclusive,
            observed_end_exclusive_ordinal⇐observedEnd,scale⇐accountPeriod.scale,
            accounts⇐{
              count⇐source.count,index⇐source.index,account_index⇐source.account_index,account_key⇐source.account_key,
              opening⇐source.opening,debit_movement⇐source.debit_movement,
              credit_movement⇐source.credit_movement,movement⇐source.movement,closing⇐source.closing,
              opening_contributors⇐openingContributors,debit_contributors⇐debitContributors,
              credit_contributors⇐creditContributors,movement_contributors⇐movementContributors,
              closing_contributors⇐closingContributors
            },
            totals⇐accountPeriod.totals,
            cycle_start_contributors⇐cycle.start_contributors,cycle_end_contributors⇐cycle.end_contributors,
            diagnostics⇐empty
          }
        }⍟(accountPeriod.state≡"ok") @
      }⍟(inCycle ∧ cycleObservationMatches) @
    }⍟observationValid @
    {𝕊: result↩EmptyResult ⟨"error",domainCode,observationText,"",diagnostics⟩}⍟(0<≠diagnostics) @
  }⍟(cycle.state≡"ok") @
  result
}

{Build⇐Build}
