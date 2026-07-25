# journal_supported_single_currency_admission_for_test.bqn
# Pure test-only proof boundary. Production Journal routes do not import this module.

util ← •Import "util.bqn"
decimal ← •Import "exact_decimal.bqn"
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

Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {severity⇐"error", stage⇐"journal_supported_single_currency_admission_for_test", code⇐codeText, line⇐lineNumber, message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid / ⟨diagnostic⟩ }

ResolveDomain ← {𝕊 lines:
  indexes ← ({StartsWith ⟨"commodity ", Trim 𝕩⟩}¨ lines) / ↕ ≠ lines
  diagnostics ← empty
  domain ← ""
  policy ← setup.Policy ""
  diagnostics ∾↩ AddIf ⟨1 ≠ ≠ indexes, Diagnostic ⟨"commodity_domain_count_invalid", 0, "proof Journal must declare exactly one commodity domain"⟩⟩
  {𝕊:
    i ← ⊑ indexes
    fields ← space util.Split Trim i ⊑ lines
    valid ← 2 = ≠ fields
    diagnostics ∾↩ AddIf ⟨¬ valid, Diagnostic ⟨"commodity_shape_invalid", i + 1, "commodity declaration must contain exactly one code"⟩⟩
    {𝕊:
      domain ↩ 1 ⊑ fields
      policy ↩ setup.Policy domain
      diagnostics ∾↩ AddIf ⟨policy.state ≢ "ok", Diagnostic ⟨"commodity_unsupported", i + 1, "commodity must be admitted by registry"⟩⟩
    }⍟valid @
  }⍟(1 = ≠ indexes) @
  {domain⇐domain, policy⇐policy, diagnostics⇐diagnostics}
}

LookupAccount ← {𝕊 accountKey‿resolved:
  mask ← accountKey⊸≡¨ resolved.accounts
  count ← +´ mask
  result ← {state⇐"error", currency⇐""}
  {𝕊:
    i ← ⊑ mask / ↕ ≠ mask
    result ↩ {state⇐"ok", currency⇐i ⊑ resolved.currencies}
  }⍟(1 = count) @
  result
}

Collect ← {𝕊 lines‿resolved‿domainInfo:
  diagnostics ← empty
  coefficients ← empty
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
        parsed ← decimal.Parse (negative ↓ amountText)
        amountOk ← parsed.state ≡ "ok"
        coefficient ← 0
        {𝕊: coefficient ↩ (1 - 2 × negative) × parsed.coefficient}⍟amountOk @
        finite ← 0 ≤ domainInfo.policy.max_fraction_digits
        precisionOk ← amountOk ∧ ((¬ finite) ∨ parsed.scale ≤ domainInfo.policy.max_fraction_digits)
        account ← LookupAccount ⟨0 ⊑ fields, resolved⟩
        diagnostics ∾↩ AddIf ⟨¬ amountOk, Diagnostic ⟨"posting_amount_invalid", lineIndex + 1, "posting amount must parse"⟩⟩
        diagnostics ∾↩ AddIf ⟨amountOk ∧ (¬ precisionOk), Diagnostic ⟨"posting_precision_exceeded", lineIndex + 1, "posting precision exceeds policy"⟩⟩
        diagnostics ∾↩ AddIf ⟨2 ⊑ fields ≢ domainInfo.domain, Diagnostic ⟨"posting_domain_mismatch", lineIndex + 1, "posting commodity differs from domain"⟩⟩
        diagnostics ∾↩ AddIf ⟨account.state ≢ "ok", Diagnostic ⟨"posting_account_unresolved", lineIndex + 1, "posting account must resolve"⟩⟩
        diagnostics ∾↩ AddIf ⟨account.state ≡ "ok" ∧ account.currency ≢ domainInfo.domain, Diagnostic ⟨"posting_account_currency_mismatch", lineIndex + 1, "account currency differs from domain"⟩⟩
        {𝕊: coefficients ∾↩ ⟨coefficient⟩}⍟(amountOk ∧ precisionOk) @
      }⍟valid @
    }⍟candidate @
  }¨ ↕ ≠ lines
  {diagnostics⇐diagnostics, coefficients⇐coefficients}
}

Admit ← {𝕊 raw‿resolved:
  lines ← lf util.SplitKeepEmpty ((cr ≠ raw) / raw)
  domainInfo ← ResolveDomain lines
  diagnostics ← domainInfo.diagnostics
  {𝕊: Collect ⟨lines, resolved, domainInfo⟩}⍟(0 = ≠ diagnostics) @
  {state⇐(0 = ≠ diagnostics) ⊑ "error"‿"ok", domain⇐domainInfo.domain, calculation_scale⇐0, normalized_postings⇐empty, transactions⇐empty, diagnostics⇐diagnostics}
}

{Admit⇐Admit}
