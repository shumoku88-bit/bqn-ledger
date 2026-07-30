# Pure individual report-route admission before source I/O or composition.
# Operational filesystem checks remain in Shell; semantic source admission remains downstream.

request ← •Import "../report/request.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 code‿message:
  {severity⇐"error",stage⇐"application_report_route",code⇐code,message⇐message}
}
EmptySources ← {𝕊:
  {count⇐0,index⇐empty,argument_index⇐empty,kind⇐empty,role⇐empty,name⇐empty}
}
Sources ← {𝕊 coordinates‿argumentIndices‿kinds‿roles:
  {
    count⇐≠argumentIndices,index⇐↕≠argumentIndices,argument_index⇐argumentIndices,
    kind⇐kinds,role⇐roles,name⇐argumentIndices⊏coordinates
  }
}
AllowedCount ← {𝕊 count‿allowed: ∨´0∾count⊸=¨allowed}
IsDigits ← {𝕊 text: (0<≠text) ∧ ∧´text∊"0123456789"}

Admit ← {𝕊 key‿surface‿coordinates:
  diagnostics ← empty
  admittedRequest ← request.Validate ⟨key,surface⟩
  diagnostics ∾↩ admittedRequest.diagnostics
  sources ← EmptySources @

  {𝕊:
    diagnostics ∾↩ ⟨Diagnostic ⟨"report_route_all_unsupported","all is a manifest-level selection, not one individual route"⟩⟩
  }⍟((admittedRequest.state≡"ok") ∧ key≡"all") @

  {𝕊:
    count ← ≠coordinates
    {𝕊:
      valid ← 8≤count
      diagnostics ∾↩ (¬valid)/⟨Diagnostic ⟨"usage_envelopes","envelopes requires DOMAIN START END_EXCLUSIVE OBSERVATION JOURNAL PLAN BUDGET and one or more FUNDING_ACCOUNT_KEY"⟩⟩
      {𝕊:sources↩Sources ⟨coordinates,⟨4,5,6⟩,⟨"journal","tsv","tsv"⟩,⟨"actual","plan","budget"⟩⟩}⍟valid @
    }⍟(key≡"envelopes") @
    {𝕊:
      valid ← 3=count
      diagnostics ∾↩ (¬valid)/⟨Diagnostic ⟨"usage_balances","balances requires DOMAIN AS_OF JOURNAL_BASENAME"⟩⟩
      {𝕊:sources↩Sources ⟨coordinates,⟨2⟩,⟨"journal"⟩,⟨"actual"⟩⟩}⍟valid @
    }⍟(key≡"balances") @
    {𝕊:
      valid ← 2=count
      diagnostics ∾↩ (¬valid)/⟨Diagnostic ⟨"usage_recent","recent requires LIMIT JOURNAL_BASENAME"⟩⟩
      {𝕊:
        diagnostics ∾↩ (¬IsDigits ⊑coordinates)/⟨Diagnostic ⟨"limit_invalid","LIMIT must be decimal digits"⟩⟩
        {𝕊:sources↩Sources ⟨coordinates,⟨1⟩,⟨"journal"⟩,⟨"actual"⟩⟩}⍟(IsDigits ⊑coordinates) @
      }⍟valid @
    }⍟(key≡"recent") @
    {𝕊:
      valid ← 4=count
      diagnostics ∾↩ (¬valid)/⟨Diagnostic ⟨"usage_planned","planned requires OBSERVATION JOURNAL_BASENAME PLAN_BASENAME CYCLE_BASENAME"⟩⟩
      {𝕊:sources↩Sources ⟨coordinates,⟨1,2,3⟩,⟨"journal","tsv","tsv"⟩,⟨"actual","plan","cycle"⟩⟩}⍟valid @
    }⍟(key≡"planned") @
    {𝕊:
      valid ← AllowedCount ⟨count,⟨4,5⟩⟩
      diagnostics ∾↩ (¬valid)/⟨Diagnostic ⟨"usage_cycle_accounts","cycle-accounts requires DOMAIN OBSERVATION JOURNAL CYCLE and PLAN only for incomeAnchor"⟩⟩
      {𝕊:
        argumentIndices ← ⟨2,3⟩ ⋄ kinds ← ⟨"journal","tsv"⟩ ⋄ roles ← ⟨"actual","cycle"⟩
        {𝕊:argumentIndices∾↩⟨4⟩ ⋄ kinds∾↩⟨"tsv"⟩ ⋄ roles∾↩⟨"plan"⟩}⍟(5=count) @
        sources↩Sources ⟨coordinates,argumentIndices,kinds,roles⟩
      }⍟valid @
    }⍟(key≡"cycle-accounts") @
    {𝕊:
      valid ← AllowedCount ⟨count,⟨7,8⟩⟩
      diagnostics ∾↩ (¬valid)/⟨Diagnostic ⟨"usage_cycle_comparison","cycle-comparison requires DOMAIN CURRENT_OBS BASELINE_OBS POLICY JOURNAL two CYCLE files and optional incomeAnchor PLAN"⟩⟩
      {𝕊:
        argumentIndices ← ⟨4,5,6⟩ ⋄ kinds ← ⟨"journal","tsv","tsv"⟩ ⋄ roles ← ⟨"actual","current_cycle","baseline_cycle"⟩
        {𝕊:argumentIndices∾↩⟨7⟩ ⋄ kinds∾↩⟨"tsv"⟩ ⋄ roles∾↩⟨"plan"⟩}⍟(8=count) @
        sources↩Sources ⟨coordinates,argumentIndices,kinds,roles⟩
      }⍟valid @
    }⍟(key≡"cycle-comparison") @
    {𝕊:
      valid ← 4=count
      diagnostics ∾↩ (¬valid)/⟨Diagnostic ⟨"usage_monthly_accounts","monthly-accounts requires DOMAIN FIRST_MONTH LAST_MONTH_EXCLUSIVE JOURNAL_BASENAME"⟩⟩
      {𝕊:sources↩Sources ⟨coordinates,⟨3⟩,⟨"journal"⟩,⟨"actual"⟩⟩}⍟valid @
    }⍟(key≡"monthly-accounts") @
    {𝕊:
      valid ← 6=count
      diagnostics ∾↩ (¬valid)/⟨Diagnostic ⟨"usage_daily_target","daily-target requires DOMAIN OBSERVATION TARGET JOURNAL PLAN DAILY_SCOPE"⟩⟩
      {𝕊:sources↩Sources ⟨coordinates,⟨3,4,5⟩,⟨"journal","tsv","tsv"⟩,⟨"actual","plan","daily_scope"⟩⟩}⍟valid @
    }⍟(key≡"daily-target") @
    {𝕊:
      valid ← 1=count
      diagnostics ∾↩ (¬valid)/⟨Diagnostic ⟨"usage_issues","issues requires ISSUE_BASENAME"⟩⟩
      {𝕊:sources↩Sources ⟨coordinates,⟨0⟩,⟨"tsv"⟩,⟨"issues"⟩⟩}⍟valid @
    }⍟(key≡"issues") @
  }⍟((admittedRequest.state≡"ok") ∧ key≢"all") @

  ok ← 0=≠diagnostics
  {
    state⇐ok⊑"error"‿"ok",key⇐ok⊑""‿key,surface⇐ok⊑""‿surface,
    coordinates⇐ok⊑⟨empty,coordinates⟩,sources⇐ok⊑⟨EmptySources @,sources⟩,
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}
