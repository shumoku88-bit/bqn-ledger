# journal_multi_currency_container_admission_for_test.bqn
# Pure test-only proof boundary. Production Journal routes do not import this module.
#
# One raw Journal may contain multiple declared currency domains, while every
# ordinary transaction is projected through the existing single-currency proof.
# No Journal-wide arithmetic domain, scale, or money total is produced.

util ← •Import "util.bqn"
dates ← •Import "date.bqn"
setup ← •Import "currency_setup.bqn"
single ← •Import "journal_supported_single_currency_admission_for_test.bqn"

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
IsCommodityLine ← {𝕊 line: StartsWith ⟨"commodity ", Trim line⟩ }

IsDateHeader ← {𝕊 text:
  enough ← 10 < ≠ text
  separator ← space = 10 ⊑ (text ∾ 11 ⥊ space)
  enough ∧ separator ∧ dates.IsValidDateText 10 ↑ text
}

Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {
    severity⇐"error",
    stage⇐"journal_multi_currency_container_admission_for_test",
    code⇐codeText,
    line⇐lineNumber,
    message⇐messageText
  }
}

AddIf ← {𝕊 invalid‿diagnostic: invalid / ⟨diagnostic⟩ }
ContainsBoxed ← {𝕊 value‿boxedValues: ∨´ 0 ∾ {(<value) ≡ 𝕩}¨ boxedValues }

FindTransactionRanges ← {𝕊 lines:
  starts ← ({IsDateHeader Trim 𝕩}¨ lines) / ↕ ≠ lines
  ranges ← empty
  {𝕊 i:
    startIndex ← i ⊑ starts
    endExclusive ← ≠ lines
    {𝕊: endExclusive ↩ (i + 1) ⊑ starts}⍟(i + 1 < ≠ starts) @
    ranges ∾↩ ⟨{start_index⇐startIndex, end_exclusive⇐endExclusive}⟩
  }¨ ↕ ≠ starts
  ranges
}

ResolveDeclarations ← {𝕊 lines:
  indexes ← (IsCommodityLine¨ lines) / ↕ ≠ lines
  diagnostics ← empty
  domainBoxes ← empty

  diagnostics ∾↩ AddIf ⟨0 = ≠ indexes, Diagnostic ⟨"commodity_declaration_missing", 0, "container Journal must declare at least one commodity domain"⟩⟩

  {𝕊 lineIndex:
    lineNumber ← lineIndex + 1
    fields ← space util.Split Trim lineIndex ⊑ lines
    valid ← 2 = ≠ fields
    localDiagnostics ← empty
    localDiagnostics ∾↩ AddIf ⟨¬ valid, Diagnostic ⟨"commodity_shape_invalid", lineNumber, "commodity declaration must contain exactly one code"⟩⟩
    {𝕊:
      domain ← 1 ⊑ fields
      policy ← setup.Policy domain
      duplicate ← ContainsBoxed ⟨domain, domainBoxes⟩
      localDiagnostics ∾↩ AddIf ⟨policy.state ≢ "ok", Diagnostic ⟨"commodity_unsupported", lineNumber, "commodity must be admitted by the repository currency registry"⟩⟩
      localDiagnostics ∾↩ AddIf ⟨duplicate, Diagnostic ⟨"commodity_declaration_duplicate", lineNumber, "commodity domain must be declared once"⟩⟩
      {𝕊: domainBoxes ∾↩ ⟨<domain⟩}⍟((policy.state ≡ "ok") ∧ (¬ duplicate)) @
    }⍟valid @
    diagnostics ∾↩ localDiagnostics
  }¨ indexes

  {
    declared_domains⇐>¨domainBoxes,
    declared_domain_boxes⇐domainBoxes,
    diagnostics⇐diagnostics
  }
}

ResolveTransactionDomain ← {𝕊 lines‿range‿declaredDomainBoxes:
  blockLength ← range.end_exclusive - range.start_index
  blockLines ← blockLength ↑ range.start_index ↓ lines
  blockLineNumbers ← 1 + range.start_index + ↕ blockLength
  trimmedLines ← Trim¨ blockLines
  indented ← {space = ⊑ (𝕩 ∾ " ")}¨ blockLines
  metadata ← {';' = ⊑ (𝕩 ∾ ";")}¨ trimmedLines
  candidateMask ← indented ∧ (0 < ≠¨ trimmedLines) ∧ (¬ metadata)
  candidateLines ← candidateMask / trimmedLines
  candidateLineNumbers ← candidateMask / blockLineNumbers
  fields ← {space util.Split 𝕩}¨ candidateLines
  validMask ← 3 = ≠¨ fields
  badLineNumbers ← (¬ validMask) / candidateLineNumbers
  validFields ← validMask / fields
  postingDomainBoxes ← {< 2 ⊑ 𝕩}¨ validFields

  diagnostics ← {Diagnostic ⟨"posting_shape_invalid", 𝕩, "posting must contain account, explicit amount, and commodity"⟩}¨ badLineNumbers
  domain ← ""
  diagnostics ∾↩ AddIf ⟨0 = ≠ candidateLines, Diagnostic ⟨"posting_missing", range.start_index + 1, "ordinary transaction must contain postings"⟩⟩

  {𝕊:
    domain ↩ >⊑postingDomainBoxes
    mixed ← ∨´ 0 ∾ {𝕩 ≢ (<domain)}¨ postingDomainBoxes
    declared ← ContainsBoxed ⟨domain, declaredDomainBoxes⟩
    diagnostics ∾↩ AddIf ⟨mixed, Diagnostic ⟨"mixed_domain_ordinary_transaction", range.start_index + 1, "ordinary transaction postings must share exactly one currency domain"⟩⟩
    diagnostics ∾↩ AddIf ⟨(¬ mixed) ∧ (¬ declared), Diagnostic ⟨"transaction_domain_undeclared", range.start_index + 1, "ordinary transaction domain must be declared by the Journal"⟩⟩
  }⍟(0 < ≠ postingDomainBoxes) @

  {domain⇐domain, diagnostics⇐diagnostics}
}

BuildProjection ← {𝕊 lines‿range‿domain:
  prefix ← range.start_index ↑ lines
  keep ← ¬ IsCommodityLine¨ prefix
  prefixLines ← keep / prefix
  prefixMap ← keep / (1 + ↕ range.start_index)

  blockLength ← range.end_exclusive - range.start_index
  blockLines ← blockLength ↑ range.start_index ↓ lines
  blockMap ← 1 + range.start_index + ↕ blockLength

  projectedLines ← ⟨"commodity " ∾ domain⟩ ∾ prefixLines ∾ blockLines
  lineMap ← ⟨0⟩ ∾ prefixMap ∾ blockMap
  projectedRaw ← ∾ (projectedLines ∾¨ lf)
  {raw⇐projectedRaw, line_map⇐lineMap}
}

RemapDiagnostic ← {𝕊 diagnostic‿lineMap:
  mappedLine ← diagnostic.line
  inRange ← (0 < mappedLine) ∧ (mappedLine ≤ ≠ lineMap)
  {𝕊: mappedLine ↩ (mappedLine - 1) ⊑ lineMap}⍟inRange @
  {
    severity⇐diagnostic.severity,
    stage⇐diagnostic.stage,
    code⇐diagnostic.code,
    line⇐mappedLine,
    message⇐diagnostic.message
  }
}

RemapPosting ← {𝕊 posting‿lineMap:
  originalLine ← (posting.source_line - 1) ⊑ lineMap
  {
    posting_id⇐posting.posting_id,
    posting_index⇐posting.posting_index,
    side⇐posting.side,
    source_line⇐originalLine,
    account_key⇐posting.account_key,
    account_currency⇐posting.account_currency,
    commodity⇐posting.commodity,
    amount_text⇐posting.amount_text,
    source_coefficient⇐posting.source_coefficient,
    source_scale⇐posting.source_scale,
    normalized_coefficient⇐posting.normalized_coefficient
  }
}

RemapTransaction ← {𝕊 transaction‿lineMap‿range‿containerIndex:
  postings ← {RemapPosting ⟨𝕩, lineMap⟩}¨ transaction.postings
  {
    transaction_index⇐containerIndex,
    source_event_id⇐transaction.source_event_id,
    identity_kind⇐transaction.identity_kind,
    source_start_line⇐range.start_index + 1,
    source_end_line⇐range.end_exclusive,
    date⇐transaction.date,
    status_marker⇐transaction.status_marker,
    description⇐transaction.description,
    layer_name⇐transaction.layer_name,
    domain⇐transaction.domain,
    calculation_scale⇐transaction.calculation_scale,
    metadata⇐transaction.metadata,
    postings⇐postings
  }
}

Admit ← {𝕊 raw‿resolved:
  normalizedRaw ← (cr ≠ raw) / raw
  hasTerminalLf ← (0 < ≠ normalizedRaw) ∧ (lf = ⊑⌽normalizedRaw)
  {𝕊: normalizedRaw ↩ ¯1 ↓ normalizedRaw}⍟hasTerminalLf @
  lines ← lf util.SplitKeepEmpty normalizedRaw
  ranges ← FindTransactionRanges lines
  declarations ← ResolveDeclarations lines
  diagnostics ← declarations.diagnostics
  transactions ← empty

  diagnostics ∾↩ AddIf ⟨0 = ≠ ranges, Diagnostic ⟨"transaction_missing", 0, "container Journal must contain at least one ordinary transaction"⟩⟩

  {𝕊 transactionIndex:
    range ← transactionIndex ⊑ ranges
    domainInfo ← ResolveTransactionDomain ⟨lines, range, declarations.declared_domain_boxes⟩
    localDiagnostics ← domainInfo.diagnostics
    {𝕊:
      projection ← BuildProjection ⟨lines, range, domainInfo.domain⟩
      proof ← single.Admit ⟨projection.raw, resolved⟩
      remapped ← {RemapDiagnostic ⟨𝕩, projection.line_map⟩}¨ proof.diagnostics
      localDiagnostics ∾↩ remapped
      {𝕊:
        oneTransaction ← 1 = ≠ proof.transactions
        localDiagnostics ∾↩ AddIf ⟨¬ oneTransaction, Diagnostic ⟨"transaction_trace_count_mismatch", range.start_index + 1, "projected single-domain proof must return exactly one transaction"⟩⟩
        {𝕊:
          transaction ← RemapTransaction ⟨⊑ proof.transactions, projection.line_map, range, transactionIndex⟩
          transactions ∾↩ ⟨transaction⟩
        }⍟oneTransaction @
      }⍟(proof.state ≡ "ok") @
    }⍟(0 = ≠ localDiagnostics) @
    diagnostics ∾↩ localDiagnostics
  }¨ ↕ ≠ ranges

  {
    state⇐(0 = ≠ diagnostics) ⊑ "error"‿"ok",
    declared_domains⇐declarations.declared_domains,
    transactions⇐transactions,
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}
