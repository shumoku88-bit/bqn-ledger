# journal_supported_single_currency_admission.bqn
# Production semantic admission for one supported currency domain.
#
# Original source amounts, commodities, account-currency proof, identities, and
# provenance are returned. A transient integer-JPY structural adapter is used
# only to reuse the unchanged Stage 1 structure checks; it is never returned or
# persisted as production evidence.

util ← •Import "util.bqn"
decimal ← •Import "exact_decimal.bqn"
dates ← •Import "date.bqn"
setup ← •Import "currency_setup.bqn"
stage1 ← •Import "journal_profile_stage1.bqn"

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
  {severity⇐"error", stage⇐"journal_supported_single_currency_admission", code⇐codeText, line⇐lineNumber, message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid / ⟨diagnostic⟩ }

ResolveDomain ← {𝕊 lines:
  indexes ← ({StartsWith ⟨"commodity ", Trim 𝕩⟩}¨ lines) / ↕ ≠ lines
  diagnostics ← empty
  domain ← ""
  sourceLine ← 0
  policy ← setup.Policy ""
  diagnostics ∾↩ AddIf ⟨1 ≠ ≠ indexes, Diagnostic ⟨"commodity_domain_count_invalid", 0, "Journal partition must declare exactly one commodity domain"⟩⟩
  {𝕊:
    i ← ⊑ indexes
    fields ← space util.Split Trim i ⊑ lines
    valid ← 2 = ≠ fields
    diagnostics ∾↩ AddIf ⟨¬ valid, Diagnostic ⟨"commodity_shape_invalid", i + 1, "commodity declaration must contain exactly one code"⟩⟩
    {𝕊:
      domain ↩ 1 ⊑ fields
      sourceLine ↩ i + 1
      policy ↩ setup.Policy domain
      diagnostics ∾↩ AddIf ⟨policy.state ≢ "ok", Diagnostic ⟨"commodity_unsupported", i + 1, "commodity must be admitted by registry"⟩⟩
    }⍟valid @
  }⍟(1 = ≠ indexes) @
  {domain⇐domain, source_line⇐sourceLine, policy⇐policy, diagnostics⇐diagnostics}
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
  transactionStarts ← empty
  transactionIndex ← ¯1
  postingIndex ← 0

  {𝕊 lineIndex:
    original ← lineIndex ⊑ lines
    trimmed ← Trim original
    {𝕊:
      transactionIndex ↩ transactionIndex + 1
      transactionStarts ∾↩ ⟨lineIndex + 1⟩
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
        parsed ← decimal.Parse (negative ↓ amountText)
        amountOk ← parsed.state ≡ "ok"
        coefficient ← 0
        {𝕊: coefficient ↩ (1 - 2 × negative) × parsed.coefficient}⍟amountOk @
        finite ← 0 ≤ domainInfo.policy.max_fraction_digits
        precisionOk ← amountOk ∧ ((¬ finite) ∨ parsed.scale ≤ domainInfo.policy.max_fraction_digits)
        account ← LookupAccount ⟨accountKey, resolved⟩
        localDiagnostics ← empty
        localDiagnostics ∾↩ AddIf ⟨transactionIndex < 0, Diagnostic ⟨"posting_outside_transaction", lineNumber, "posting must belong to a dated transaction"⟩⟩
        localDiagnostics ∾↩ AddIf ⟨¬ amountOk, Diagnostic ⟨"posting_amount_invalid", lineNumber, "posting amount must parse exactly"⟩⟩
        localDiagnostics ∾↩ AddIf ⟨amountOk ∧ (¬ precisionOk), Diagnostic ⟨"posting_precision_exceeded", lineNumber, "posting precision exceeds currency policy"⟩⟩
        localDiagnostics ∾↩ AddIf ⟨amountOk ∧ (coefficient = 0), Diagnostic ⟨"posting_amount_zero", lineNumber, "posting amount must be nonzero"⟩⟩
        localDiagnostics ∾↩ AddIf ⟨commodity ≢ domainInfo.domain, Diagnostic ⟨"posting_domain_mismatch", lineNumber, "posting commodity differs from transaction domain"⟩⟩
        localDiagnostics ∾↩ AddIf ⟨account.state ≢ "ok", Diagnostic ⟨"posting_account_unresolved", lineNumber, "posting account must resolve exactly once"⟩⟩
        localDiagnostics ∾↩ AddIf ⟨(account.state ≡ "ok") ∧ (account.currency ≢ domainInfo.domain), Diagnostic ⟨"posting_account_currency_mismatch", lineNumber, "account currency differs from transaction domain"⟩⟩
        diagnostics ∾↩ localDiagnostics
        {𝕊:
          postings ∾↩ ⟨{
            transaction_index⇐transactionIndex,
            posting_index⇐postingIndex,
            source_line⇐lineNumber,
            account_key⇐accountKey,
            account_currency⇐account.currency,
            commodity⇐commodity,
            amount_text⇐amountText,
            source_coefficient⇐coefficient,
            source_scale⇐parsed.scale
          }⟩
        }⍟(0 = ≠ localDiagnostics) @
        postingIndex ↩ postingIndex + 1
      }⍟valid @
    }⍟candidate @
  }¨ ↕ ≠ lines

  {diagnostics⇐diagnostics, postings⇐postings, transaction_starts⇐transactionStarts}
}

Normalize ← {𝕊 postings:
  calculationScale ← 0
  {𝕊: calculationScale ↩ ⌈´ {𝕩.source_scale}¨ postings}⍟(0 < ≠ postings) @
  normalized ← {𝕊 posting:
    zeroCount ← calculationScale - posting.source_scale
    magnitudeText ← (•Fmt | posting.source_coefficient) ∾ zeroCount ⥊ '0'
    magnitude ← decimal.Parse magnitudeText
    sign ← 1 - 2 × (posting.source_coefficient < 0)
    {
      transaction_index⇐posting.transaction_index,
      posting_index⇐posting.posting_index,
      source_line⇐posting.source_line,
      account_key⇐posting.account_key,
      account_currency⇐posting.account_currency,
      commodity⇐posting.commodity,
      amount_text⇐posting.amount_text,
      source_coefficient⇐posting.source_coefficient,
      source_scale⇐posting.source_scale,
      normalized_coefficient⇐sign × magnitude.coefficient
    }
  }¨ postings
  {calculation_scale⇐calculationScale, postings⇐normalized}
}

BalanceDiagnostics ← {𝕊 postings‿transactionStarts:
  diagnostics ← empty
  {𝕊 transactionIndex:
    selected ← ({transactionIndex = 𝕩.transaction_index}¨ postings) / postings
    sourceLine ← transactionIndex ⊑ transactionStarts
    total ← +´ 0 ∾ {𝕩.normalized_coefficient}¨ selected
    diagnostics ∾↩ AddIf ⟨0 = ≠ selected, Diagnostic ⟨"posting_missing", sourceLine, "transaction must contain postings"⟩⟩
    diagnostics ∾↩ AddIf ⟨0 ≠ total, Diagnostic ⟨"event_unbalanced", sourceLine, "normalized posting coefficients must sum to zero"⟩⟩
  }¨ ↕ ≠ transactionStarts
  diagnostics
}

RenderStructuralPosting ← {𝕊 posting:
  coefficient ← posting.normalized_coefficient
  signText ← (coefficient < 0) ⊑ ⟨"", "-"⟩
  "  " ∾ posting.account_key ∾ "  " ∾ signText ∾ (•Fmt | coefficient) ∾ " JPY"
}

BuildStructuralRaw ← {𝕊 raw‿domainInfo‿postings:
  lines ← lf util.SplitKeepEmpty ((cr ≠ raw) / raw)
  transformed ← {𝕊 lineIndex:
    lineNumber ← lineIndex + 1
    output ← lineIndex ⊑ lines
    matches ← ({lineNumber = 𝕩.source_line}¨ postings) / postings
    {𝕊: output ↩ "commodity JPY"}⍟(lineNumber = domainInfo.source_line) @
    {𝕊: output ↩ RenderStructuralPosting (⊑ matches)}⍟(1 = ≠ matches) @
    output
  }¨ ↕ ≠ lines
  ∾ (transformed ∾¨ lf)
}

BuildTransactions ← {𝕊 parsedTransactions‿postings‿domain‿calculationScale:
  {𝕊 transactionIndex:
    parsed ← transactionIndex ⊑ parsedTransactions
    evidence ← ({transactionIndex = 𝕩.transaction_index}¨ postings) / postings
    combined ← {𝕊 postingIndex:
      semantic ← postingIndex ⊑ evidence
      structural ← postingIndex ⊑ parsed.postings
      {
        posting_id⇐structural.posting_id,
        posting_index⇐postingIndex,
        side⇐structural.side,
        source_line⇐semantic.source_line,
        account_key⇐semantic.account_key,
        account_currency⇐semantic.account_currency,
        commodity⇐domain,
        amount_text⇐semantic.amount_text,
        source_coefficient⇐semantic.source_coefficient,
        source_scale⇐semantic.source_scale,
        normalized_coefficient⇐semantic.normalized_coefficient
      }
    }¨ ↕ ≠ evidence
    {
      source_event_id⇐parsed.source_event_id,
      identity_kind⇐parsed.identity_kind,
      source_start_line⇐parsed.source_start_line,
      source_end_line⇐parsed.source_end_line,
      date⇐parsed.date,
      status_marker⇐parsed.status_marker,
      description⇐parsed.description,
      layer_name⇐parsed.layer_name,
      txn_id⇐parsed.txn_id,
      plan_id⇐parsed.plan_id,
      allocation_id⇐parsed.allocation_id,
      execution_envelope⇐parsed.execution_envelope,
      actual_event_id⇐parsed.actual_event_id,
      domain⇐domain,
      calculation_scale⇐calculationScale,
      metadata⇐parsed.metadata,
      postings⇐combined
    }
  }¨ ↕ ≠ parsedTransactions
}

Admit ← {𝕊 raw‿resolved:
  lines ← lf util.SplitKeepEmpty ((cr ≠ raw) / raw)
  domainInfo ← ResolveDomain lines
  diagnostics ← domainInfo.diagnostics
  transactionStarts ← empty
  calculationScale ← 0
  normalizedPostings ← empty
  transactions ← empty
  {𝕊:
    collected ← Collect ⟨lines, resolved, domainInfo⟩
    diagnostics ∾↩ collected.diagnostics
    transactionStarts ↩ collected.transaction_starts
    diagnostics ∾↩ AddIf ⟨0 = ≠ transactionStarts, Diagnostic ⟨"transaction_missing", 0, "Journal partition must contain at least one dated transaction"⟩⟩
    {𝕊:
      normalized ← Normalize collected.postings
      calculationScale ↩ normalized.calculation_scale
      normalizedPostings ↩ normalized.postings
      diagnostics ∾↩ BalanceDiagnostics ⟨normalizedPostings, transactionStarts⟩
      {𝕊:
        structuralRaw ← BuildStructuralRaw ⟨raw, domainInfo, normalizedPostings⟩
        structural ← stage1.ParseWithProfile ⟨structuralRaw, "historical_external_plan"⟩
        diagnostics ∾↩ structural.diagnostics
        {𝕊:
          transactionCountOk ← (≠ structural.transactions) = ≠ transactionStarts
          postingCount ← +´ {≠ 𝕩.postings}¨ structural.transactions
          postingCountOk ← postingCount = ≠ normalizedPostings
          diagnostics ∾↩ AddIf ⟨¬ transactionCountOk, Diagnostic ⟨"transaction_trace_count_mismatch", 0, "structural and semantic transaction counts differ"⟩⟩
          diagnostics ∾↩ AddIf ⟨¬ postingCountOk, Diagnostic ⟨"posting_trace_count_mismatch", 0, "structural and semantic posting counts differ"⟩⟩
          {𝕊:
            transactions ↩ BuildTransactions ⟨structural.transactions, normalizedPostings, domainInfo.domain, calculationScale⟩
          }⍟(0 = ≠ diagnostics) @
        }⍟(structural.state ≡ "ok") @
      }⍟(0 = ≠ diagnostics) @
    }⍟(0 = ≠ diagnostics) @
  }⍟(0 = ≠ diagnostics) @
  {
    state⇐(0 = ≠ diagnostics) ⊑ "error"‿"ok",
    domain⇐domainInfo.domain,
    calculation_scale⇐calculationScale,
    normalized_postings⇐normalizedPostings,
    transaction_starts⇐transactionStarts,
    transactions⇐transactions,
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}
