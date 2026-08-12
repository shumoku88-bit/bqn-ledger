# Pure machine-readable route-plan application result.
# Retained Report routes contain semantic argv coordinates only. Canonical
# Household physical sources are resolved internally after route admission.

route ← •Import "report_route.bqn"
tab ← @+9

Result ← {𝕊 exitCode‿linesValue:{exit_code⇐exitCode,lines⇐linesValue}}
ErrorLine ← {𝕊 diagnostic:
  "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message
}
Success ← {𝕊 admitted:
  header ← "ROUTE"∾tab∾admitted.key∾tab∾admitted.surface∾tab∾•Fmt ≠admitted.coordinates
  Result ⟨0,⟨header⟩⟩
}
Failure ← {𝕊 admitted:
  Result ⟨1,ErrorLine¨admitted.diagnostics⟩
}

Run ← {𝕊 args:
  (2≤≠args)◶⟨
    {𝕊:Result ⟨2,⟨"ERROR"∾tab∾"usage"∾tab∾"expected KEY SURFACE [COORDINATE...]"⟩⟩},
    {𝕊:
      admitted ← route.Admit ⟨0⊑args,1⊑args,2↓args⟩
      (admitted.state≡"ok")◶⟨Failure,Success⟩ admitted
    }
  ⟩ @
}

{Run⇐Run}
