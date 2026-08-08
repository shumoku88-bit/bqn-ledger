# journal_single_domain_admission.bqn
# Production semantic admission for one supported currency domain.
#
# Original source amounts, commodities, account-default proof, identities, and
# provenance are returned. One posting amount may be elided and is inferred from
# the exact balance of the other postings, matching the canonical Journal rule.
# A transient integer-JPY structural adapter is used only to reuse unchanged
# Stage 1 structure checks; it is never returned or persisted as source evidence.

decimal ← •Import "exact_decimal.bqn"
dates ← •Import "date_ordinal.bqn"
structure ← •Import "journal_transaction_structure.bqn"
postingText ← •Import "journal_posting_text.bqn"

lf ← @+10
cr ← @+13
space ← @+32
tab ← @+9
empty ← ⟨⟩
SplitKeepEmpty ← {𝕊 sep‿text:
  groups ← (+`sep=text)⊔text
  {(sep≠𝕩)/𝕩}¨groups
}
Split ← {𝕊 sep‿text:
  parts ← SplitKeepEmpty ⟨sep,text⟩
  (0<≠¨parts)/parts
}

IsWhitespace ← {𝕊 c: (c=space) ∨ c=tab }
TrimLeft ← {𝕊 xs:
  prefix ← ∧` IsWhitespace¨xs
  (+´prefix)↓xs
}
TrimRight ← {𝕊 xs:
  reversed ← ⌽xs
  trimmed ← TrimLeft reversed
  ⌽trimmed
}
Trim ← { TrimRight TrimLeft 𝕩 }
StartsWith ← {𝕊 prefix‿text: prefix ≡ (≠ prefix) ↑ text }
IsDateHeader ← {𝕊 text:
  enough ← 10 < ≠ text
  separator ← IsWhitespace 10 ⊑ (text ∾ 11 ⥊ space)
  enough ∧ separator ∧ dates.IsValid 10 ↑ text
}

Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {severity⇐"error", stage⇐"journal_supported_single_currency_admission", code⇐codeText, line⇐lineNumber, message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid / ⟨diagnostic⟩ }

ResolveDomain ← {𝕊 lines‿registry:
  indexes ← ({StartsWith ⟨"commodity ", Trim 𝕩⟩}¨ lines) / ↕ ≠ lines
  diagnostics ← empty
  domain ← ""
  sourceLine ← 0
  policy ← registry.Policy ""
  diagnostics ∾↩ AddIf ⟨1 ≠ ≠ indexes, Diagnostic ⟨"commodity_domain_count_invalid", 0, "Journal partition must declare exactly one commodity domain"⟩⟩
  {𝕊:
    i ← ⊑ indexes
    fields ← Split ⟨space,Trim i⊑lines⟩
    valid ← 2 = ≠ fields
    diagnostics ∾↩ AddIf ⟨¬ valid, Diagnostic ⟨"commodity_shape_invalid", i + 1, "commodity declaration must contain exactly one code"⟩⟩
    {𝕊:
      domain ↩ 1 ⊑ fields
      sourceLine ↩ i + 1
      policy ↩ registry.Policy domain
      diagnostics ∾↩ AddIf ⟨policy.state ≢ "ok", Diagnostic ⟨"commodity_unsupported", i + 1, "commodity must be admitted by registry"⟩⟩
    }⍟valid @
  }⍟(1 = ≠ indexes) @
  {domain⇐domain, source_line⇐sourceLine, policy⇐policy, diagnostics⇐diagnostics}
}

LookupAccount ← {𝕊 accountKey‿accounts:
  mask ← accountKey⊸≡¨ accounts.key
  count ← +´ mask
  result ← {state⇐"error", currency⇐""}
  {𝕊:
    i ← ⊑ mask / ↕ ≠ mask
    result ↩ {state⇐"ok", currency⇐i⊑accounts.currency}
  }⍟(1 = count) @
  result
}

Collect ← {𝕊 lines‿accounts‿domainInfo:
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

    indented ← IsWhitespace ⊑ (original ∾ " ")
    metadata ← ';' = ⊑ (trimmed ∾ ";")
    candidate ← indented ∧ (0 < ≠ trimmed) ∧ (¬ metadata)
    {𝕊:
      lineNumber ← lineIndex + 1
      parsedPosting ← postingText.Split original
      valid ← parsedPosting.valid
      explicit ← parsedPosting.explicit
      elided ← parsedPosting.elided
      diagnostics ∾↩ AddIf ⟨¬ valid, Diagnostic ⟨"posting_shape_invalid", lineNumber, "posting must contain account plus explicit amount and commodity, or one elided account only"⟩⟩
      {𝕊:
        accountKey ← parsedPosting.account
        account ← LookupAccount ⟨accountKey,accounts⟩
        commodity ← domainInfo.domain
        amountText ← ""
        amountOk ← 1
        precisionOk ← 1
        coefficient ← 0
        sourceScale ← 0
        {𝕊:
          amountText ↩ 0 ⊑ parsedPosting.words
          commodity ↩ 1 ⊑ parsedPosting.words
          negative ← '-' = ⊑ (amountText ∾ "0")
          parsedAmount ← decimal.Parse (negative ↓ amountText)
          amountOk ↩ parsedAmount.state ≡ "ok"
          {𝕊:
            coefficient ↩ (1 - 2 × negative) × parsedAmount.coefficient
            sourceScale ↩ parsedAmount.scale
          }⍟amountOk @
          finite ← 0 ≤ domainInfo.policy.max_fraction_digits
          precisionOk ↩ amountOk ∧ ((¬ finite) ∨ sourceScale ≤ domainInfo.policy.max_fraction_digits)
        }⍟explicit @
        localDiagnostics ← empty
        localDiagnostics ∾↩ AddIf ⟨transactionIndex < 0, Diagnostic ⟨"posting_outside_transaction", lineNumber, "posting must belong to a dated transaction"⟩⟩
        localDiagnostics ∾↩ AddIf ⟨explicit ∧ (¬ amountOk), Diagnostic ⟨"posting_amount_invalid", lineNumber, "posting amount must parse exactly"⟩⟩
        localDiagnostics ∾↩ AddIf ⟨explicit ∧ amountOk ∧ (¬ precisionOk), Diagnostic ⟨"posting_precision_exceeded", lineNumber, "posting precision exceeds currency policy"⟩⟩
        localDiagnostics ∾↩ AddIf ⟨explicit ∧ amountOk ∧ (coefficient = 0), Diagnostic ⟨"posting_amount_zero", lineNumber, "posting amount must be nonzero"⟩⟩
        localDiagnostics ∾↩ AddIf ⟨explicit ∧ (commodity ≢ domainInfo.domain), Diagnostic ⟨"posting_domain_mismatch", lineNumber, "posting commodity differs from transaction domain"⟩⟩
        localDiagnostics ∾↩ AddIf ⟨account.state ≢ "ok", Diagnostic ⟨"posting_account_unresolved", lineNumber, "posting account must resolve exactly once"⟩⟩
        accountConstrainsDomain ← (account.state ≡ "ok") ∧ 0 < ≠ account.currency
        localDiagnostics ∾↩ AddIf ⟨accountConstrainsDomain ∧ (account.currency ≢ domainInfo.domain), Diagnostic ⟨"posting_account_currency_mismatch", lineNumber, "Account default Commodity differs from transaction domain"⟩⟩
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
            source_scale⇐sourceScale,
            elided⇐elided
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

CompleteElided ← {𝕊 postings‿transactionStarts:
  diagnostics ← empty
  completed ← empty
  {𝕊 transactionIndex:
    selected ← ({transactionIndex = 𝕩.transaction_index}¨ postings) / postings
    missing ← ({𝕩.elided}¨ selected) / selected
    missingCount ← ≠ missing
    sourceLine ← transactionIndex ⊑ transactionStarts
    diagnostics ∾↩ AddIf ⟨1 < missingCount, Diagnostic ⟨"posting_elided_multiple", sourceLine, "transaction may elide at most one posting amount"⟩⟩
    {𝕊: completed ∾↩ selected}⍟(0 = missingCount) @
    {𝕊:
      explicit ← ({¬𝕩.elided}¨ selected) / selected
      missingPosting ← ⊑ missing
      diagnostics ∾↩ AddIf ⟨0 = ≠ explicit, Diagnostic ⟨"posting_elided_uninferable", missingPosting.source_line, "elided posting requires explicit balance evidence"⟩⟩
      {𝕊:
        normalizedExplicit ← Normalize explicit
        inferredCoefficient ← - +´ 0 ∾ {𝕩.normalized_coefficient}¨ normalizedExplicit.postings
        diagnostics ∾↩ AddIf ⟨0 = inferredCoefficient, Diagnostic ⟨"posting_elided_zero", missingPosting.source_line, "inferred posting amount must be nonzero"⟩⟩
        {𝕊:
          completed ∾↩ {𝕊 posting:
            result ← posting
            {𝕊:
              result ↩ {
                transaction_index⇐posting.transaction_index,
                posting_index⇐posting.posting_index,
                source_line⇐posting.source_line,
                account_key⇐posting.account_key,
                account_currency⇐posting.account_currency,
                commodity⇐posting.commodity,
                amount_text⇐"",
                source_coefficient⇐inferredCoefficient,
                source_scale⇐normalizedExplicit.calculation_scale,
                elided⇐1
              }
            }⍟(posting.posting_index = missingPosting.posting_index) @
            result
          }¨ selected
        }⍟(0 ≠ inferredCoefficient) @
      }⍟(0 < ≠ explicit) @
    }⍟(1 = missingCount) @
  }¨ ↕ ≠ transactionStarts
  {diagnostics⇐diagnostics,postings⇐completed}
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
  lines ← SplitKeepEmpty ⟨lf,(cr≠raw)/raw⟩
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

Admit ← {𝕊 raw‿accounts‿registry:
  lines ← SplitKeepEmpty ⟨lf,(cr≠raw)/raw⟩
  domainInfo ← ResolveDomain ⟨lines,registry⟩
  diagnostics ← domainInfo.diagnostics
  transactionStarts ← empty
  calculationScale ← 0
  normalizedPostings ← empty
  transactions ← empty
  {𝕊:
    collected ← Collect ⟨lines,accounts,domainInfo⟩
    diagnostics ∾↩ collected.diagnostics
    transactionStarts ↩ collected.transaction_starts
    diagnostics ∾↩ AddIf ⟨0 = ≠ transactionStarts, Diagnostic ⟨"transaction_missing", 0, "Journal partition must contain at least one dated transaction"⟩⟩
    {𝕊:
      completed ← CompleteElided ⟨collected.postings,transactionStarts⟩
      diagnostics ∾↩ completed.diagnostics
      {𝕊:
        normalized ← Normalize completed.postings
        calculationScale ↩ normalized.calculation_scale
        normalizedPostings ↩ normalized.postings
        diagnostics ∾↩ BalanceDiagnostics ⟨normalizedPostings, transactionStarts⟩
        {𝕊:
          structuralRaw ← BuildStructuralRaw ⟨raw, domainInfo, normalizedPostings⟩
          structural ← structure.Parse structuralRaw
          diagnostics ∾↩ structural.diagnostics
          {𝕊 transaction:
            currencyValues ← {𝕩.value}¨({𝕩.key ≡ "currency"}¨transaction.metadata)/transaction.metadata
            currencyMismatch ← 0
            {𝕊: currencyMismatch ↩ (⊑currencyValues) ≢ domainInfo.domain}⍟(1=≠currencyValues) @
            diagnostics ∾↩ AddIf ⟨currencyMismatch, Diagnostic ⟨"transaction_currency_mismatch", transaction.source_start_line, "transaction currency metadata must match posting domain"⟩⟩
          }¨ structural.transactions
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
