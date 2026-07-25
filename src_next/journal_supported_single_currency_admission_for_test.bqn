# journal_supported_single_currency_admission_for_test.bqn
#
# Pure test-only proof boundary for one supported single-currency native Journal.
# It does not widen the production Stage 1 profile, writer, context, Cube, TBDS,
# reports, or editor routes.
#
# Strategy:
# 1. identify exactly one registry-supported commodity domain;
# 2. validate exact-decimal postings, registry precision, and account currency;
# 3. normalize every posting to one calculation scale and prove each event balances;
# 4. rewrite only the synthetic proof input to an equivalent integer-JPY shadow;
# 5. reuse the unchanged production Stage 1 parser for structural evidence;
# 6. return original-domain normalized evidence with source traceability.

util ← •Import "util.bqn"
decimal ← •Import "exact_decimal.bqn"
dates ← •Import "date.bqn"
setup ← •Import "currency_setup.bqn"
stage1 ← •Import "journal_profile_stage1.bqn"

empty ← ⟨⟩
lf ← @+10
cr ← @+13
space ← @+32

Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {
    severity ⇐ "error",
    stage ⇐ "journal_supported_single_currency_admission_for_test",
    code ⇐ codeText,
    line ⇐ lineNumber,
    message ⇐ messageText
  }
}

AddIf ← {𝕊 invalid‿diagnostic: invalid / ⟨diagnostic⟩ }

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

Paragraphs ← {𝕊 raw:
  cleaned ← (cr ≠ raw) / raw
  lines ← <¨ (lf util.SplitKeepEmpty cleaned)
  groups ← empty
  current ← empty
  startLine ← 0

  Flush ← {𝕊 endLine:
    {𝕊:
      groups ∾↩ ⟨{lines⇐current, start_line⇐startLine, end_line⇐endLine}⟩
      current ↩ empty
    }⍟(0 < ≠ current) @
  }

  {𝕊 i:
    line ← > i ⊑ lines
    blank ← 0 = ≠ Trim line
    {𝕊: Flush i}⍟blank @
    {𝕊:
      {𝕊: startLine ↩ i + 1}⍟(0 = ≠ current) @
      current ∾↩ ⟨<line⟩
    }⍟(¬ blank) @
  }¨ ↕ ≠ lines

  Flush ≠ lines
  groups
}

FirstLine ← { Trim > ⊑ 𝕩.lines }

IsDateHeader ← {𝕊 text:
  enough ← 10 < ≠ text
  separator ← space = 10 ⊑ (text ∾ " ")
  enough ∧ separator ∧ dates.IsValidDateText 10 ↑ text
}

ResolveDomain ← {𝕊 groups:
  commodityGroups ← ({StartsWith ⟨"commodity ", FirstLine 𝕩⟩}¨ groups) / groups
  diagnostics ← empty
  domain ← ""
  sourceLine ← 0
  policy ← setup.Policy ""

  diagnostics ∾↩ AddIf ⟨1 ≠ ≠ commodityGroups, Diagnostic ⟨"commodity_domain_count_invalid", 0, "proof Journal must declare exactly one commodity domain"⟩⟩

  {𝕊:
    group ← ⊑ commodityGroups
    fields ← space util.Split FirstLine group
    validShape ← 2 = ≠ fields
    diagnostics ∾↩ AddIf ⟨¬ validShape, Diagnostic ⟨"commodity_shape_invalid", group.start_line, "commodity declaration must contain exactly one code"⟩⟩
    {𝕊:
      domain ↩ 1 ⊑ fields
      sourceLine ↩ group.start_line
      policy ↩ setup.Policy domain
      diagnostics ∾↩ AddIf ⟨policy.state ≢ "ok", Diagnostic ⟨"commodity_unsupported", group.start_line, "commodity must be admitted by the repository currency registry"⟩⟩
    }⍟validShape @
  }⍟(1 = ≠ commodityGroups) @

  {domain⇐domain, source_line⇐sourceLine, policy⇐policy, diagnostics⇐diagnostics}
}

LookupAccount ← {𝕊 accountKey‿resolved:
  mask ← accountKey⊸≡¨ resolved.accounts
  count ← +´ mask
  result ← {state⇐"error", currency⇐"", index⇐¯1}
  {𝕊:
    idx ← ⊑ mask / ↕ ≠ mask
    result ↩ {state⇐"ok", currency⇐idx ⊑ resolved.currencies, index⇐idx}
  }⍟(1 = count) @
  result
}

ParsePosting ← {𝕊 transactionIndex‿postingIndex‿transactionStartLine‿lineText‿lineNumber‿resolved‿domainInfo:
  diagnostics ← empty
  trimmed ← Trim lineText
  fields ← space util.Split trimmed
  validShape ← 3 = ≠ fields
  accountKey ← ""
  amountText ← ""
  commodityText ← ""

  {𝕊:
    accountKey ↩ 0 ⊑ fields
    amountText ↩ 1 ⊑ fields
    commodityText ↩ 2 ⊑ fields
  }⍟validShape @

  diagnostics ∾↩ AddIf ⟨¬ validShape, Diagnostic ⟨"posting_shape_invalid", lineNumber, "posting must contain account, explicit amount, and commodity"⟩⟩

  negative ← '-' = ⊑ (amountText ∾ "0")
  unsigned ← negative ↓ amountText
  parsed ← decimal.Parse unsigned
  amountOk ← parsed.state ≡ "ok"
  sourceCoefficient ← 0
  {𝕊: sourceCoefficient ↩ (1 - 2 × negative) × parsed.coefficient}⍟amountOk @

  finitePrecision ← 0 ≤ domainInfo.policy.max_fraction_digits
  precisionOk ← amountOk ∧ ((¬ finitePrecision) ∨ parsed.scale ≤ domainInfo.policy.max_fraction_digits)
  account ← LookupAccount ⟨accountKey, resolved⟩

  diagnostics ∾↩ AddIf ⟨validShape ∧ (¬ amountOk), Diagnostic ⟨"posting_amount_invalid", lineNumber, "posting amount must be an explicit exact decimal"⟩⟩
  diagnostics ∾↩ AddIf ⟨validShape ∧ amountOk ∧ (¬ precisionOk), Diagnostic ⟨"posting_precision_exceeded", lineNumber, "posting precision exceeds the selected currency policy"⟩⟩
  diagnostics ∾↩ AddIf ⟨validShape ∧ amountOk ∧ 0 = sourceCoefficient, Diagnostic ⟨"posting_amount_zero", lineNumber, "posting amount must be nonzero"⟩⟩
  diagnostics ∾↩ AddIf ⟨validShape ∧ commodityText ≢ domainInfo.domain, Diagnostic ⟨"posting_domain_mismatch", lineNumber, "every posting commodity must equal the one declared domain"⟩⟩
  diagnostics ∾↩ AddIf ⟨validShape ∧ account.state ≢ "ok", Diagnostic ⟨"posting_account_unresolved", lineNumber, "posting account must resolve exactly once"⟩⟩
  diagnostics ∾↩ AddIf ⟨validShape ∧ account.state ≡ "ok" ∧ account.currency ≢ domainInfo.domain, Diagnostic ⟨"posting_account_currency_mismatch", lineNumber, "posting account currency must equal the declared domain"⟩⟩

  evidence ← @
  {𝕊:
    evidence ↩ {
      transaction_index⇐transactionIndex,
      posting_index⇐postingIndex,
      transaction_source_line⇐transactionStartLine,
      source_line⇐lineNumber,
      account_key⇐accountKey,
      account_currency⇐account.currency,
      commodity⇐commodityText,
      amount_text⇐amountText,
      source_coefficient⇐sourceCoefficient,
      source_scale⇐parsed.scale
    }
  }⍟(0 = ≠ diagnostics) @

  {diagnostics⇐diagnostics, evidence⇐evidence}
}

CollectPostingEvidence ← {𝕊 groups‿resolved‿domainInfo:
  diagnostics ← empty
  evidence ← empty
  transactionStarts ← empty
  transactionIndex ← 0

  {𝕊 group:
    first ← FirstLine group
    {𝕊:
      transactionStarts ∾↩ ⟨group.start_line⟩
      body ← 1 ↓ group.lines
      postingIndex ← 0
      {𝕊 i:
        lineText ← > i ⊑ body
        trimmed ← Trim lineText
        isMetadata ← ';' = ⊑ (trimmed ∾ ";")
        {𝕊:
          lineNumber ← group.start_line + i + 1
          parsed ← ParsePosting ⟨transactionIndex, postingIndex, group.start_line, lineText, lineNumber, resolved, domainInfo⟩
          diagnostics ∾↩ parsed.diagnostics
          {𝕊: evidence ∾↩ ⟨parsed.evidence⟩}⍟(parsed.evidence ≢ @) @
          postingIndex ↩ postingIndex + 1
        }⍟(¬ isMetadata) @
      }¨ ↕ ≠ body
      transactionIndex ↩ transactionIndex + 1
    }⍟(IsDateHeader first) @
  }¨ groups

  {
    diagnostics⇐diagnostics,
    evidence⇐evidence,
    transaction_starts⇐transactionStarts,
    transaction_count⇐transactionIndex
  }
}

NormalizeOne ← {𝕊 evidence‿calculationScale:
  zeroCount ← calculationScale - evidence.source_scale
  normalizedText ← (•Fmt | evidence.source_coefficient) ∾ zeroCount ⥊ '0'
  normalized ← decimal.Parse normalizedText
  sign ← 1 - 2 × (evidence.source_coefficient < 0)
  {
    transaction_index⇐evidence.transaction_index,
    posting_index⇐evidence.posting_index,
    transaction_source_line⇐evidence.transaction_source_line,
    source_line⇐evidence.source_line,
    account_key⇐evidence.account_key,
    account_currency⇐evidence.account_currency,
    commodity⇐evidence.commodity,
    amount_text⇐evidence.amount_text,
    source_coefficient⇐evidence.source_coefficient,
    source_scale⇐evidence.source_scale,
    normalized_coefficient⇐sign × normalized.coefficient
  }
}

NormalizeEvidence ← {𝕊 collected:
  calculationScale ← 0
  {𝕊: calculationScale ↩ ⌈´ {𝕩.source_scale}¨ collected.evidence}⍟(0 < ≠ collected.evidence) @
  normalized ← {NormalizeOne ⟨𝕩, calculationScale⟩}¨ collected.evidence
  {calculation_scale⇐calculationScale, postings⇐normalized}
}

BalanceDiagnostics ← {𝕊 normalized‿transactionStarts:
  diagnostics ← empty
  {𝕊 transactionIndex:
    postings ← ({transactionIndex = 𝕩.transaction_index}¨ normalized) / normalized
    total ← +´ 0 ∾ {𝕩.normalized_coefficient}¨ postings
    sourceLine ← transactionIndex ⊑ transactionStarts
    diagnostics ∾↩ AddIf ⟨0 ≠ total, Diagnostic ⟨"event_unbalanced", sourceLine, "normalized posting coefficients must sum to zero within each transaction"⟩⟩
  }¨ ↕ ≠ transactionStarts
  diagnostics
}

RenderShadowPosting ← {𝕊 posting:
  coefficient ← posting.normalized_coefficient
  signText ← (coefficient < 0) ⊑ ⟨"", "-"⟩
  "  " ∾ posting.account_key ∾ "  " ∾ signText ∾ (•Fmt | coefficient) ∾ " JPY"
}

BuildShadowRaw ← {𝕊 raw‿domainInfo‿normalized:
  cleaned ← (cr ≠ raw) / raw
  lines ← <¨ (lf util.SplitKeepEmpty cleaned)
  transformed ← {𝕊 i:
    lineNumber ← i + 1
    original ← > i ⊑ lines
    output ← original
    postingMatches ← ({lineNumber = 𝕩.source_line}¨ normalized) / normalized
    {𝕊: output ↩ "commodity JPY"}⍟(lineNumber = domainInfo.source_line) @
    {𝕊: output ↩ RenderShadowPosting (⊑ postingMatches)}⍟(1 = ≠ postingMatches) @
    <output
  }¨ ↕ ≠ lines
  ∾ ((>¨ transformed) ∾¨ lf)
}

BuildTransactions ← {𝕊 parsedTransactions‿normalized‿domain‿calculationScale:
  {𝕊 transactionIndex:
    transaction ← transactionIndex ⊑ parsedTransactions
    rawPostings ← ({transactionIndex = 𝕩.transaction_index}¨ normalized) / normalized
    postings ← {𝕊 postingIndex:
      normalizedPosting ← postingIndex ⊑ rawPostings
      structuralPosting ← postingIndex ⊑ transaction.postings
      {
        posting_id⇐structuralPosting.posting_id,
        posting_index⇐postingIndex,
        side⇐structuralPosting.side,
        account_key⇐normalizedPosting.account_key,
        account_currency⇐normalizedPosting.account_currency,
        commodity⇐domain,
        amount_text⇐normalizedPosting.amount_text,
        source_coefficient⇐normalizedPosting.source_coefficient,
        source_scale⇐normalizedPosting.source_scale,
        normalized_coefficient⇐normalizedPosting.normalized_coefficient,
        source_line⇐normalizedPosting.source_line
      }
    }¨ ↕ ≠ rawPostings
    {
      source_event_id⇐transaction.source_event_id,
      identity_kind⇐transaction.identity_kind,
      source_start_line⇐transaction.source_start_line,
      source_end_line⇐transaction.source_end_line,
      date⇐transaction.date,
      status_marker⇐transaction.status_marker,
      description⇐transaction.description,
      layer_name⇐transaction.layer_name,
      domain⇐domain,
      calculation_scale⇐calculationScale,
      metadata⇐transaction.metadata,
      postings⇐postings
    }
  }¨ ↕ ≠ parsedTransactions
}

Admit ← {𝕊 raw‿resolved:
  groups ← Paragraphs raw
  domainInfo ← ResolveDomain groups
  diagnostics ← domainInfo.diagnostics
  calculationScale ← 0
  transactions ← empty
  normalizedPostings ← empty

  {𝕊:
    collected ← CollectPostingEvidence ⟨groups, resolved, domainInfo⟩
    diagnostics ∾↩ collected.diagnostics
    normalized ← NormalizeEvidence collected
    calculationScale ↩ normalized.calculation_scale
    normalizedPostings ↩ normalized.postings
    diagnostics ∾↩ BalanceDiagnostics ⟨normalizedPostings, collected.transaction_starts⟩

    {𝕊:
      shadowRaw ← BuildShadowRaw ⟨raw, domainInfo, normalizedPostings⟩
      structural ← stage1.ParseWithProfile ⟨shadowRaw, "strict_self_contained"⟩
      diagnostics ∾↩ structural.diagnostics

      {𝕊:
        diagnostics ∾↩ AddIf ⟨(≠ structural.transactions) ≠ collected.transaction_count, Diagnostic ⟨"transaction_trace_count_mismatch", 0, "structural transaction count must equal generic evidence count"⟩⟩
        structuralPostingCount ← +´ {≠𝕩.postings}¨ structural.transactions
        diagnostics ∾↩ AddIf ⟨structuralPostingCount ≠ ≠ normalizedPostings, Diagnostic ⟨"posting_trace_count_mismatch", 0, "structural posting count must equal normalized evidence count"⟩⟩
        nonActual ← ({𝕩.layer_name ≢ "actual"}¨ structural.transactions) / structural.transactions
        diagnostics ∾↩ AddIf ⟨0 < ≠ nonActual, Diagnostic ⟨"layer_not_actual", 0, "test-only supported-currency proof admits Actual transactions only"⟩⟩

        {𝕊:
          transactions ↩ BuildTransactions ⟨structural.transactions, normalizedPostings, domainInfo.domain, calculationScale⟩
        }⍟(0 = ≠ diagnostics) @
      }⍟(structural.state ≡ "ok") @
    }⍟(0 = ≠ diagnostics) @
  }⍟(0 = ≠ diagnostics) @

  {
    state⇐(0 = ≠ diagnostics) ⊑ "error"‿"ok",
    domain⇐(0 = ≠ diagnostics) ⊑ ⟨"", domainInfo.domain⟩,
    calculation_scale⇐(0 = ≠ diagnostics) ⊑ ⟨⟨⟩, calculationScale⟩,
    normalized_postings⇐(0 = ≠ diagnostics) ⊑ ⟨empty, normalizedPostings⟩,
    transactions⇐transactions,
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}
