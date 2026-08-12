# Pure current-report domain selection. Report policy does not own accounting
# domains. An explicit requested domain wins after admission; omission is allowed
# only when canonical Actual Facts expose exactly one domain.

empty ← ⟨⟩
Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"application_report_domain_selection",code⇐code,message⇐message}}
Success ← {𝕊 domainValue:{state⇐"ok",domain⇐domainValue,diagnostics⇐empty}}
Failure ← {𝕊 code‿message:{state⇐"error",domain⇐"",diagnostics⇐⟨Diagnostic ⟨code,message⟩⟩}}

Explicit ← {𝕊 available‿requested:
  matches ← requested⊸≡¨available
  (1=+´matches)◶⟨
    {𝕊:Failure ⟨"report_domain_unknown","Requested Report domain is not admitted by canonical Actual Facts"⟩},
    {𝕊:Success requested}
  ⟩ @
}
Inferred ← {𝕊 available:
  (1=≠available)◶⟨
    {𝕊:Failure ⟨"report_domain_required","Report domain must be explicit when canonical Actual Facts do not expose exactly one domain"⟩},
    {𝕊:Success ⊑available}
  ⟩ @
}
Resolve ← {𝕊 facts‿requested:
  available ← facts.domains.code
  (0<≠requested)◶⟨
    {𝕊:Inferred available},
    {𝕊:Explicit ⟨available,requested⟩}
  ⟩ @
}

{Resolve⇐Resolve}
