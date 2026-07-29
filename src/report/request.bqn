# Pure destination report request validation over the static catalog.

catalog ← •Import "catalog.bqn"
empty ← ⟨⟩
surfaces ← ⟨"human","compact","json"⟩

# Index-of returns ≠surfaces for an unknown surface; only known coordinates are selected.
SurfaceIndex ← {𝕊 surface: ⊑ surfaces ⊐ ⟨surface⟩}
Diagnostic ← {𝕊 code‿message:
  {severity⇐"error",stage⇐"report_request",code⇐code,message⇐message}
}
EmptyResult ← {𝕊 diagnosticsValue:
  {state⇐"error",key⇐"",surface⇐"",section_indices⇐empty,section_keys⇐empty,diagnostics⇐diagnosticsValue}
}
# Support fields are aligned with surfaces: human, compact, json.
Supports ← {𝕊 entry‿surfaceIndex: surfaceIndex⊑⟨entry.human,entry.compact,entry.json⟩}

Validate ← {𝕊 keyValue‿surface:
  diagnostics ← empty
  surfaceIndex ← SurfaceIndex surface
  surfaceKnown ← surfaceIndex<≠surfaces
  diagnostics∾↩(¬surfaceKnown)/⟨Diagnostic ⟨"report_surface_unknown","surface must be human, compact, or json"⟩⟩
  table ← catalog.Table @
  indices ← empty
  {𝕊:
    {𝕊:
      diagnostics∾↩(surfaceIndex=2)/⟨Diagnostic ⟨"report_surface_unsupported","all has no aggregate JSON schema"⟩⟩
      {𝕊:
        support ← surfaceIndex⊑⟨table.human,table.compact⟩
        indices↩support/table.index
      }⍟(surfaceIndex<2) @
    }⍟(keyValue≡"all") @
    {𝕊:
      found ← catalog.Find keyValue
      diagnostics∾↩(found.state≢"ok")/⟨Diagnostic ⟨"report_key_unknown","report key is not in the retained catalog"⟩⟩
      {𝕊:
        supported ← Supports ⟨found.entry,surfaceIndex⟩
        diagnostics∾↩(¬supported)/⟨Diagnostic ⟨"report_surface_unsupported","requested report does not support this surface"⟩⟩
        {𝕊:indices↩⟨found.index⟩}⍟supported @
      }⍟(found.state≡"ok") @
    }⍟(keyValue≢"all") @
  }⍟surfaceKnown @
  {𝕊:
    {
      state⇐"ok",key⇐keyValue,surface⇐surface,
      section_indices⇐indices,section_keys⇐indices⊏table.key,diagnostics⇐empty
    }
  }⍟(0=≠diagnostics) EmptyResult diagnostics
}

{Validate⇐Validate}
