# One resolved-cycle result shape shared by all pure mode-specific resolvers.

empty ← ⟨⟩
dates ← •Import "../ledger/date_ordinal.bqn"

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_cycle_resolution",code⇐codeText,message⇐messageText}
}
Error ← {𝕊 mode‿observation‿code‿message:
  {
    state⇐"error",mode⇐mode,observation⇐observation,reason⇐"",
    start⇐"",end_exclusive⇐"",start_ordinal⇐empty,end_exclusive_ordinal⇐empty,day_count⇐empty,
    start_contributors⇐empty,end_contributors⇐empty,
    diagnostics⇐⟨Diagnostic ⟨code,message⟩⟩
  }
}
Unavailable ← {𝕊 mode‿observation‿reason:
  {
    state⇐"unavailable",mode⇐mode,observation⇐observation,reason⇐reason,
    start⇐"",end_exclusive⇐"",start_ordinal⇐empty,end_exclusive_ordinal⇐empty,day_count⇐empty,
    start_contributors⇐empty,end_contributors⇐empty,diagnostics⇐empty
  }
}
Success ← {𝕊 mode‿observation‿start‿finish‿startContributors‿endContributors:
  startOrdinal ← dates.Ordinal start
  endOrdinal ← dates.Ordinal finish
  {
    state⇐"ok",mode⇐mode,observation⇐observation,reason⇐"",
    start⇐start,end_exclusive⇐finish,start_ordinal⇐startOrdinal,end_exclusive_ordinal⇐endOrdinal,
    day_count⇐endOrdinal-startOrdinal,
    start_contributors⇐startContributors,end_contributors⇐endContributors,diagnostics⇐empty
  }
}

{Error⇐Error,Unavailable⇐Unavailable,Success⇐Success}
