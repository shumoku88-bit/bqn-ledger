# journal_supported_single_currency_admission_for_test.bqn
# Pure test-only proof boundary. Production Journal routes do not import this module.

util ← •Import "util.bqn"
decimal ← •Import "exact_decimal.bqn"
dates ← •Import "date.bqn"
setup ← •Import "currency_setup.bqn"

lf ← @+10
cr ← @+13
space ← @+32
empty ← ⟨⟩

TrimLeft ← {𝕊 xs:
  prefix ← ∧` (xs = space)
  (+´ prefix) ↓ xs
}
TrimRight ← {𝕊 xs:
  suffix ← ∧` ((⌽ xs) = space)
  ((≠ xs) - +´ suffix) ↑ xs
}
Trim ← { TrimRight TrimLeft 𝕩 }
StartsWith ← {𝕊 prefix‿text: prefix ≡ (≠ prefix) ↑ text }
IsDateHeader ← {𝕊 text:
  enough ← 10 < ≠ text
  separator ← space = 10 ⊑ (text ∾ 11 ⥊ space)
  enough ∧ separator ∧ dates.IsValidDateText 10 ↑ text
}

Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {severity⇐"error", stage⇐"journal_supported_single_currency_admission_for_test", code⇐codeText, line⇐lineNumber, message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid / ⟨diagnostic⟩ }

ResolveDomain ← {𝕊 lines:
  indexes ← ({StartsWith ⟨"commodity ", Trim 𝕩⟩}¨ lines) / ↕ ≠ lines
  diagnostics ← empty
  domain ← ""
  diagnostics ∾↩ AddIf ⟨1 ≠ ≠ indexes, Diagnostic ⟨"commodity_domain_count_invalid", 0, "proof Journal must declare exactly one commodity domain"⟩⟩
  {𝕊:
    i ← ⊑ indexes
    fields ← space util.Split Trim i ⊑ lines
    valid ← 2 = ≠ fields
    diagnostics ∾↩ AddIf ⟨¬ valid, Diagnostic ⟨"commodity_shape_invalid", i + 1, "commodity declaration must contain exactly one code"⟩⟩
    {𝕊:
      domain ↩ 1 ⊑ fields
      policy ← setup.Policy domain
      diagnostics ∾↩ AddIf ⟨policy.state ≢ "ok", Diagnostic ⟨"commodity_unsupported", i + 1, "commodity must be admitted by registry"⟩⟩
    }⍟valid @
  }⍟(1 = ≠ indexes) @
  {domain⇐domain, diagnostics⇐diagnostics}
}

Collect ← {𝕊 lines:
  diagnostics ← empty
  parsedScales ← empty
  {𝕊 lineIndex:
    original ← lineIndex ⊑ lines
    trimmed ← Trim original
    indented ← space = ⊑ (original ∾ " ")
    metadata ← ';' = ⊑ (trimmed ∾ ";")
    candidate ← indented ∧ (0 < ≠ trimmed) ∧ (¬ metadata)
    {𝕊:
      fields ← space util.Split trimmed
      valid ← 3 = ≠ fields
      diagnostics ∾↩ AddIf ⟨¬ valid, Diagnostic ⟨"posting_shape_invalid", lineIndex + 1, "posting must contain three fields"⟩⟩
      {𝕊:
        amountText ← 1 ⊑ fields
        negative ← '-' = ⊑ (amountText ∾ "0")
        unsigned ← negative ↓ amountText
        parsed ← decimal.Parse unsigned
        diagnostics ∾↩ AddIf ⟨parsed.state ≢ "ok", Diagnostic ⟨"posting_amount_invalid", lineIndex + 1, "posting amount must be an explicit exact decimal"⟩⟩
        {𝕊: parsedScales ∾↩ ⟨parsed.scale⟩}⍟(parsed.state ≡ "ok") @
      }⍟valid @
    }⍟candidate @
  }¨ ↕ ≠ lines
  {diagnostics⇐diagnostics, parsed_scales⇐parsedScales}
}

Admit ← {𝕊 raw‿resolved:
  lines ← lf util.SplitKeepEmpty ((cr ≠ raw) / raw)
  domainInfo ← ResolveDomain lines
  diagnostics ← domainInfo.diagnostics
  {𝕊: Collect lines}⍟(0 = ≠ diagnostics) @
  {state⇐(0 = ≠ diagnostics) ⊑ "error"‿"ok", domain⇐domainInfo.domain, calculation_scale⇐0, normalized_postings⇐empty, transactions⇐empty, diagnostics⇐diagnostics}
}

{Admit⇐Admit}
