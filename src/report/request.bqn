# Pure destination report request validation over the static catalog.

catalog ← •Import "catalog.bqn"
empty ← ⟨⟩
surfaces ← ⟨"human","compact","json"⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 code‿message:
  {severity⇐"error",stage⇐"report_request",code⇐code,message⇐message}
}
EmptyResult ← {𝕊 diagnosticsValue:
  {state⇐"error",key⇐"",surface⇐"",section_indices⇐empty,section_keys⇐empty,diagnostics⇐diagnosticsValue}
}

Supports ← {𝕊 entry‿surface:
  supported ← 0
  {𝕊:supported↩entry.human}⍟(surface≡"human") @
  {𝕊:supported↩entry.compact}⍟(surface≡"compact") @
  {𝕊:supported↩entry.json}⍟(surface≡"json") @
  supported
}

Validate ← {𝕊 keyValue‿surface:
  diagnostics ← empty
  surfaceKnown ← Contains ⟨surface,surfaces⟩
  diagnostics∾↩(¬surfaceKnown)/⟨Diagnostic ⟨"report_surface_unknown","surface must be human, compact, or json"⟩⟩
  table ← catalog.Table @
  indices ← empty
  {𝕊:
    {𝕊:
      diagnostics∾↩(surface≡"json")/⟨Diagnostic ⟨"report_surface_unsupported","all has no aggregate JSON schema"⟩⟩
      {𝕊:
        support ← (surface≡"human")⊑table.compact‿table.human
        indices↩support/table.index
      }⍟(surface≢"json") @
    }⍟(keyValue≡"all") @
    {𝕊:
      found ← catalog.Find keyValue
      diagnostics∾↩(found.state≢"ok")/⟨Diagnostic ⟨"report_key_unknown","report key is not in the retained catalog"⟩⟩
      {𝕊:
        supported ← Supports ⟨found.entry,surface⟩
        diagnostics∾↩(¬supported)/⟨Diagnostic ⟨"report_surface_unsupported","requested report does not support this surface"⟩⟩
        {𝕊:indices↩⟨⊑(keyValue⊸≡¨table.key)/table.index⟩}⍟supported @
      }⍟(found.state≡"ok") @
    }⍟(keyValue≢"all") @
  }⍟surfaceKnown @
  result ← EmptyResult diagnostics
  {𝕊:
    result↩{
      state⇐"ok",key⇐keyValue,surface⇐surface,
      section_indices⇐indices,section_keys⇐indices⊏table.key,diagnostics⇐empty
    }
  }⍟(0=≠diagnostics) @
  result
}

{Validate⇐Validate}
