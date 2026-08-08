# Pure current-report domain selection. Report policy does not own accounting
# domains. An explicit requested domain wins after admission; omission is allowed
# only when canonical Actual Facts expose exactly one domain.

empty ← ⟨⟩
Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"application_report_domain_selection",code⇐code,message⇐message}}

Resolve ← {𝕊 facts‿requested:
  diagnostics ← empty ⋄ domain ← ""
  available ← facts.domains.code
  {𝕊:
    matches ← requested⊸≡¨available
    {𝕊:domain↩requested}⍟(1=+´matches) @
    {𝕊:diagnostics∾↩⟨Diagnostic ⟨"report_domain_unknown","Requested Report domain is not admitted by canonical Actual Facts"⟩⟩}⍟(1≠+´matches) @
  }⍟(0<≠requested) @
  {𝕊:
    {𝕊:domain↩⊑available}⍟(1=≠available) @
    {𝕊:diagnostics∾↩⟨Diagnostic ⟨"report_domain_required","Report domain must be explicit when canonical Actual Facts do not expose exactly one domain"⟩⟩}⍟(1≠≠available) @
  }⍟(0=≠requested) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",domain⇐domain,diagnostics⇐diagnostics}
}

{Resolve⇐Resolve}
