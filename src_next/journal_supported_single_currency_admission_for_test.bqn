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
      diagnostics ∾↩ AddIf ⟨policy.state ≢ "ok", Diagnostic ⟨"commodity_unsupported", i + 1, "commodity must be admitted by the repository currency registry"⟩⟩
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
  postings ← empty
  transactionIndex ← ¯1
  postingIndex ← 0

  {𝕊 lineIndex:
    original ← lineIndex ⊑ lines
    trimmed ← Trim original
    {𝕊:
      transactionIndex ↩ transactionIndex + 1
      postingIndex ↩ 0
    }⍟(IsDateHeader trimmed) @

    indented ← space = ⊑ (original ∾ " ")
    metadata ← ';' = ⊑ (trimmed ∾ ";")
    candidate ← indented ∧ (0 < ≠ trimmed) ∧ (¬ metadata)

    {𝕊:
      lineNumber ← lineIndex + 1
      fields ← space util.Split trimmed
      valid ← 3 = ≠ fields
      diagnostics ∾↩ AddIf ⟨¬ valid, Diagnostic ⟨"posting_shape_invalid", lineNumber, "posting must contain account, explicit amount, and commodity"⟩⟩
      {𝕊:
        accountKey ← 0 ⊑ fields
        amountText ← 1 ⊑ fields
        commodity ← 2 ⊑ fields
        negative ← '-' = ⊑ (amountText ∾ "0")
        unsigned ← negative ↓ amountText
        parsed ← decimal.Parse unsigned
        amountOk ← parsed.state ≡ "ok"
        coefficient ← 0
        {𝕊: coefficient ↩ (1 - 2 × negative) × parsed.coefficient}⍟amountOk @
        finite ← 0 ≤ domainInfo.policy.max_fraction_digits
        precisionOk ← amountOk ∧ ((¬ finite) ∨ parsed.scale ≤ domainInfo.policy.max_fraction_digits)
        account ← LookupAccount ⟨accountKey, resolved⟩

        diagnostics ∾↩ AddIf ⟨transactionIndex < 0, Diagnostic ⟨"posting_outside_transaction", lineNumber, "posting must belong to a dated transaction"⟩⟩
        diagnostics ∾↩ AddIf ⟨¬ amountOk, Diagnostic ⟨"posting_amount_invalid", lineNumber, "posting amount must be an explicit exact decimal"⟩⟩
        diagnostics ∾↩ AddIf ⟨amountOk ∧ (¬ precisionOk), Diagnostic ⟨"posting_precision_exceeded", lineNumber, "posting precision exceeds currency policy"⟩⟩
        diagnostics ∾↩ AddIf ⟨commodity ≢ domainInfo.domain, Diagnostic ⟨"posting_domain_mismatch", lineNumber, "posting commodity must equal the declared domain"⟩⟩
        diagnostics ∾↩ AddIf ⟨account.state ≢ "ok", Diagnostic ⟨"posting_account_unresolved", lineNumber, "posting account must resolve exactly once"⟩⟩
        diagnostics ∾↩ AddIf ⟨account.state ≡ "ok" ∧ account.currency ≢ domainInfo.domain, Diagnostic ⟨"posting_account_currency_mismatch", lineNumber, "posting account currency must equal the declared domain"⟩⟩

        {𝕊:
          postings ∾↩ ⟨{transaction_index⇐transactionIndex, posting_index⇐postingIndex, source_line⇐lineNumber, account_key⇐accountKey, account_currency⇐account.currency, commodity⇐commodity, amount_text⇐amountText, source_coefficient⇐coefficient, source_scale⇐parsed.scale}⟩
        }⍟(0 = ≠ diagnostics) @
        postingIndex ↩ postingIndex + 1
      }⍟valid @
    }⍟candidate @
  }¨ ↕ ≠ lines

  {diagnostics⇐diagnostics, postings⇐postings}
}

Admit ← {𝕊 raw‿resolved:
  lines ← lf util.SplitKeepEmpty ((cr ≠ raw) / raw)
  domainInfo ← ResolveDomain lines
  diagnostics ← domainInfo.diagnostics
  {𝕊: Collect ⟨lines, resolved, domainInfo⟩}⍟(0 = ≠ diagnostics) @
  {state⇐(0 = ≠ diagnostics) ⊑ "error"‿"ok", domain⇐domainInfo.domain, calculation_scale⇐0, normalized_postings⇐empty, transactions⇐empty, diagnostics⇐diagnostics}
}

{Admit⇐Admit}
