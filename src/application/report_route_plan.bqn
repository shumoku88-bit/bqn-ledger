# Pure machine-readable route-plan application result.

route ← •Import "report_route.bqn"
empty ← ⟨⟩
tab ← @+9

Result ← {𝕊 exitCode‿linesValue: {exit_code⇐exitCode,lines⇐linesValue}}
ErrorLine ← {𝕊 diagnostic:
  "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message
}
SourceLine ← {𝕊 sourceIndex‿sources:
  ("SOURCE"∾tab∾(•Fmt sourceIndex⊑sources.argument_index)∾tab∾(sourceIndex⊑sources.kind)∾tab∾(sourceIndex⊑sources.role))
}
Success ← {𝕊 admitted:
  header ← ("ROUTE"∾tab∾admitted.key∾tab∾admitted.surface∾tab∾(•Fmt ≠admitted.coordinates)∾tab∾(•Fmt admitted.sources.count))
  sourceLines ← {𝕊 sourceIndex: SourceLine ⟨sourceIndex,admitted.sources⟩}¨admitted.sources.index
  Result ⟨0,⟨header⟩∾sourceLines⟩
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
