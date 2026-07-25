# journal_supported_single_currency_admission_for_test.bqn
# Pure test-only proof boundary. Production Journal routes do not import this module.

util ← •Import "util.bqn"
setup ← •Import "currency_setup.bqn"

lf ← @+10
cr ← @+13
space ← @+32

TrimLeft ← {𝕊 xs:
  prefix ← ∧` (xs = space)
  (+´ prefix) ↓ xs
}

TrimRight ← {𝕊 xs:
  suffix ← ∧` ((⌽ xs) = space)
  ((≠ xs) - +´ suffix) ↑ xs
}

Trim ← { TrimRight TrimLeft 𝕩 }

StartsWith ← {𝕊 prefix‿text:
  prefix ≡ (≠ prefix) ↑ text
}

Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {
    severity ⇐ "error",
    stage ⇐ "journal_supported_single_currency_admission_for_test",
    code ⇐ codeText,
    line ⇐ lineNumber,
    message ⇐ messageText
  }
}

Admit ← {𝕊 raw‿resolved:
  cleaned ← (cr ≠ raw) / raw
  lines ← lf util.SplitKeepEmpty cleaned
  commodityIndexes ← ({StartsWith ⟨"commodity ", Trim 𝕩⟩}¨ lines) / ↕ ≠ lines
  diagnostics ← ⟨⟩
  domain ← ""

  {𝕊:
    diagnostics ↩ ⟨Diagnostic ⟨"commodity_domain_count_invalid", 0, "proof Journal must declare exactly one commodity domain"⟩⟩
  }⍟(1 ≠ ≠ commodityIndexes) @

  {𝕊:
    lineIndex ← ⊑ commodityIndexes
    fields ← space util.Split Trim lineIndex ⊑ lines
    validShape ← 2 = ≠ fields
    {𝕊:
      diagnostics ↩ ⟨Diagnostic ⟨"commodity_shape_invalid", lineIndex + 1, "commodity declaration must contain exactly one code"⟩⟩
    }⍟(¬ validShape) @
    {𝕊:
      domain ↩ 1 ⊑ fields
      policy ← setup.Policy domain
      {𝕊:
        diagnostics ↩ ⟨Diagnostic ⟨"commodity_unsupported", lineIndex + 1, "commodity must be admitted by the repository currency registry"⟩⟩
      }⍟(policy.state ≢ "ok") @
    }⍟validShape @
  }⍟(1 = ≠ commodityIndexes) @

  {
    state ⇐ (0 = ≠ diagnostics) ⊑ "error"‿"ok",
    domain ⇐ (0 = ≠ diagnostics) ⊑ ⟨"", domain⟩,
    calculation_scale ⇐ ⟨⟩,
    normalized_postings ⇐ ⟨⟩,
    transactions ⇐ ⟨⟩,
    diagnostics ⇐ diagnostics
  }
}

{Admit⇐Admit}
