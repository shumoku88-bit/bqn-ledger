# Pure calendarMonth resolution from one admitted definition and explicit as-of.

result ← •Import "cycle_result.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"

MonthParts ← {𝕊 monthIndex: ⟨⌊monthIndex÷12,1+12|monthIndex⟩}

Resolve ← {𝕊 admittedCycle‿asOfText:
  resolved ← result.Error ⟨"calendarMonth",asOfText,"cycle_admission_not_ok","cycle definition must be admitted"⟩
  {𝕊:
    definition ← admittedCycle.definition
    resolved↩result.Error ⟨definition.mode,asOfText,"cycle_mode_mismatch","calendarMonth resolver requires calendarMonth mode"⟩
    {𝕊:
      resolved↩result.Error ⟨definition.mode,asOfText,"observation_invalid","calendarMonth requires strict explicit as-of text"⟩
      {𝕊:
        year‿month‿day ← dates.Parts asOfText

        # b: start / end-exclusive boundary axis. The as-of month shifts back iff day precedes start_day.
        # Adding ↕2 derives both adjacent month coordinates; MonthParts handles year rollover.
        baseMonth ← ((year×12)+(month-1))-(day<definition.start_day)
        boundaryMonths ← baseMonth+↕2
        boundaryParts ← {𝕩∾definition.start_day}¨MonthParts¨boundaryMonths
        start‿finish ← dates.FromParts¨boundaryParts
        resolved↩result.Success ⟨definition.mode,asOfText,start,finish,⟨⟩,⟨⟩⟩
      }⍟(dates.IsValid asOfText) @
    }⍟(definition.mode≡"calendarMonth") @
  }⍟(admittedCycle.state≡"ok") @
  resolved
}

{Resolve⇐Resolve}
