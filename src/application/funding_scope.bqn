# Pure explicit Envelope funding Account ownership admission.

empty ← ⟨⟩
Diagnostic ← {𝕊 code‿message:
  {severity⇐"error",stage⇐"application_funding_scope",code⇐code,message⇐message}
}
Build ← {𝕊 accounts‿domain‿accountKeys:
  diagnostics ← empty
  diagnostics∾↩(0=≠accountKeys)/⟨Diagnostic ⟨"funding_scope_empty","at least one funding Account key is required"⟩⟩
  diagnostics∾↩((≠accountKeys)≠≠⍷accountKeys)/⟨Diagnostic ⟨"funding_scope_duplicate","funding Account keys must be unique"⟩⟩
  indices ← empty
  {𝕊 key:
    matches ← key⊸≡¨accounts.key
    known ← 1=+´matches
    diagnostics∾↩(¬known)/⟨Diagnostic ⟨"funding_account_unknown","funding Account key must be admitted exactly once"⟩⟩
    {𝕊:
      index ← ⊑matches/accounts.index
      diagnostics∾↩((index⊑accounts.currency)≢domain)/⟨Diagnostic ⟨"funding_account_domain_mismatch","funding Account currency must match selected domain"⟩⟩
      diagnostics∾↩((index⊑accounts.role)≢"asset")/⟨Diagnostic ⟨"funding_account_role_invalid","funding Account must have asset role"⟩⟩
      indices∾↩⟨index⟩
    }⍟known @
  }¨accountKeys
  ok ← 0=≠diagnostics
  {state⇐ok⊑"error"‿"ok",account_keys⇐ok/accountKeys,account_indices⇐ok/indices,diagnostics⇐diagnostics}
}

{Build⇐Build}
