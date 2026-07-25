# journal_multi_currency_container_admission_for_test.bqn
# Pure test-only proof boundary. Production Journal routes do not import this module.
#
# One raw Journal may contain several declared currency domains, while every
# ordinary transaction is admitted independently through the existing
# single-currency proof seam. No Journal-wide arithmetic domain is produced.

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
Contains ← {𝕊 item‿items: ∨´ 0 ∾ item⊸≡¨ items }
Unique ← {𝕊 items:
  result ← empty
  {𝕊 item: {𝕊: result ∾↩ ⟨item⟩}⍟(¬ Contains ⟨item, result⟩) @}¨ items
  result
}
IsDateHeader ← {𝕊 text:
  enough ← 10 < ≠ text
  separator ← space = 10 ⊑ (text ∾ 11 ⥊ space)
  enough ∧ separator ∧ dates.IsValidDateText 10 ↑ text
}

Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {severity⇐"error", stage⇐"journal_multi_currency_container_admission_for_test", code⇐codeText, line⇐lineNumber, message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid / ⟨diagnostic⟩ }

Declarations ← {𝕊 lines:
  diagnostics ← empty
  domains ← empty
  domainLines ← empty
  accounts ← empty
  commodityCount ← 0
  {𝕊 lineIndex:
    text ← Trim lineIndex ⊑ lines
    {𝕊:
      fields ← space util.Split text
      valid ← 2 = ≠ fields
      diagnostics ∾↩ AddIf ⟨¬ valid, Diagnostic ⟨"commodity_shape_invalid", lineIndex + 1, "commodity declaration must contain exactly one code"⟩⟩
      {𝕊:
        domain ← 1 ⊑ fields
        policy ← setup.Policy domain
        diagnostics ∾↩ AddIf ⟨policy.state ≢ "ok", Diagnostic ⟨"commodity_unsupported", lineIndex + 1, "commodity must be admitted by registry"⟩⟩
        {𝕊:
          domains ∾↩ ⟨domain⟩
          domainLines ∾↩ ⟨lineIndex + 1⟩
        }⍟(policy.state ≡ "ok") @
      }⍟valid @
    }⍟(StartsWith ⟨"commodity ", text⟩) @
    commodityCount +↩ StartsWith ⟨"commodity ", text⟩
    {𝕊: accounts ∾↩ ⟨{text⇐text, source_line⇐lineIndex + 1}⟩}⍟(StartsWith ⟨"account ", text⟩) @
  }¨ ↕ ≠ lines
  duplicate ← (≠ domains) ≠ ≠ Unique domains
  diagnostics ∾↩ AddIf ⟨duplicate, Diagnostic ⟨"commodity_domain_duplicate", 0, "each declared commodity domain must appear once"⟩⟩
  diagnostics ∾↩ AddIf ⟨0 = commodityCount, Diagnostic ⟨"commodity_domain_missing", 0, "proof Journal must declare at least one supported commodity"⟩⟩
  {domains⇐domains, domain_lines⇐domainLines, accounts⇐accounts, diagnostics⇐diagnostics}
}

DomainSourceLine ← {𝕊 domain‿declarations:
  mask ← domain⊸≡¨ declarations.domains
  result ← 0
  {𝕊: result ↩ ⊑ mask / declarations.domain_lines}⍟(1 = +´ mask) @
  result
}

PostingDomains ← {𝕊 blockLines:
  diagnostics ← empty
  domains ← empty
  {𝕊 offset:
    original ← offset ⊑ blockLines
    trimmed ← Trim original
    indented ← space = ⊑ (original ∾ " ")
    metadata ← ';' = ⊑ (trimmed ∾ ";")
    candidate ← indented ∧ (0 < ≠ trimmed) ∧ (¬ metadata)
    {𝕊:
      fields ← space util.Split trimmed
      valid ← 3 = ≠ fields
      diagnostics ∾↩ AddIf ⟨¬ valid, Diagnostic ⟨"posting_shape_invalid", offset + 1, "posting must contain account, explicit amount, and commodity"⟩⟩
      {𝕊: domains ∾↩ ⟨2 ⊑ fields⟩}⍟valid @
    }⍟candidate @
  }¨ ↕ ≠ blockLines
  {domains⇐Unique domains, diagnostics⇐diagnostics}
}

BuildMini ← {𝕊 domain‿domainLine‿accounts‿blockLines‿blockStart:
  miniLines ← ⟨"commodity " ∾ domain, ""⟩
  lineMap ← ⟨domainLine, 0⟩
  {𝕊 account:
    miniLines ∾↩ ⟨account.text, ""⟩
    lineMap ∾↩ ⟨account.source_line, 0⟩
  }¨ accounts
  miniLines ∾↩ blockLines
  lineMap ∾↩ blockStart + 1 + ↕ ≠ blockLines
  {raw⇐∾ (miniLines ∾¨ lf), line_map⇐lineMap}
}

MapLine ← {𝕊 line‿lineMap:
  mapped ← line
  {𝕊:
    candidate ← (line - 1) ⊑ lineMap
    {𝕊: mapped ↩ candidate}⍟(candidate > 0) @
  }⍟((0 < line) ∧ (line ≤ ≠ lineMap)) @
  mapped
}

MapDiagnostic ← {𝕊 diagnostic‿lineMap:
  {
    severity⇐diagnostic.severity,
    stage⇐diagnostic.stage,
    code⇐diagnostic.code,
    line⇐MapLine ⟨diagnostic.line, lineMap⟩,
    message⇐diagnostic.message
  }
}

MapPosting ← {𝕊 posting‿lineMap:
  {
    posting_id⇐posting.posting_id,
    posting_index⇐posting.posting_index,
    side⇐posting.side,
    source_line⇐MapLine ⟨posting.source_line, lineMap⟩,
    account_key⇐posting.account_key,
    account_currency⇐posting.account_currency,
    commodity⇐posting.commodity,
    amount_text⇐posting.amount_text,
    source_coefficient⇐posting.source_coefficient,
    source_scale⇐posting.source_scale,
    normalized_coefficient⇐posting.normalized_coefficient
  }
}

MapTransaction ← {𝕊 transaction‿lineMap:
  {
    source_event_id⇐transaction.source_event_id,
    identity_kind⇐transaction.identity_kind,
    source_start_line⇐MapLine ⟨transaction.source_start_line, lineMap⟩,
    source_end_line⇐MapLine ⟨transaction.source_end_line, lineMap⟩,
    date⇐transaction.date,
    status_marker⇐transaction.status_marker,
    description⇐transaction.description,
    layer_name⇐transaction.layer_name,
    domain⇐transaction.domain,
    calculation_scale⇐transaction.calculation_scale,
    metadata⇐transaction.metadata,
    postings⇐{MapPosting ⟨𝕩, lineMap⟩}¨ transaction.postings
  }
}

Admit ← {𝕊 raw‿resolved:
  normalizedRaw ← (cr ≠ raw) / raw
  hasTerminalLf ← (0 < ≠ normalizedRaw) ∧ (lf = ⊑⌽normalizedRaw)
  {𝕊: normalizedRaw ↩ ¯1 ↓ normalizedRaw}⍟hasTerminalLf @
  lines ← lf util.SplitKeepEmpty normalizedRaw
  declarations ← Declarations lines
  diagnostics ← declarations.diagnostics
  transactions ← empty
  starts ← (IsDateHeader¨ Trim¨ lines) / ↕ ≠ lines

  {𝕊:
    {𝕊 transactionIndex:
      start ← transactionIndex ⊑ starts
      end ← ≠ lines
      {𝕊: end ↩ (transactionIndex + 1) ⊑ starts}⍟((transactionIndex + 1) < ≠ starts) @
      blockLines ← (end - start) ↑ start ↓ lines
      domainEvidence ← PostingDomains blockLines
      localDiagnostics ← {𝕊 diagnostic:
        {severity⇐diagnostic.severity, stage⇐diagnostic.stage, code⇐diagnostic.code, line⇐start + diagnostic.line, message⇐diagnostic.message}
      }¨ domainEvidence.diagnostics
      shapeOk ← 0 = ≠ localDiagnostics
      domainCountOk ← 1 = ≠ domainEvidence.domains
      localDiagnostics ∾↩ AddIf ⟨shapeOk ∧ (¬ domainCountOk), Diagnostic ⟨"transaction_domain_count_invalid", start + 1, "ordinary transaction must contain exactly one posting currency domain"⟩⟩
      {𝕊:
        domain ← ⊑ domainEvidence.domains
        declared ← Contains ⟨domain, declarations.domains⟩
        localDiagnostics ∾↩ AddIf ⟨¬ declared, Diagnostic ⟨"transaction_domain_undeclared", start + 1, "ordinary transaction currency must be declared by the Journal"⟩⟩
        {𝕊:
          domainLine ← DomainSourceLine ⟨domain, declarations⟩
          mini ← BuildMini ⟨domain, domainLine, declarations.accounts, blockLines, start⟩
          admitted ← single.Admit ⟨mini.raw, resolved⟩
          localDiagnostics ∾↩ {MapDiagnostic ⟨𝕩, mini.line_map⟩}¨ admitted.diagnostics
          {𝕊:
            transaction ← MapTransaction ⟨⊑ admitted.transactions, mini.line_map⟩
            transactions ∾↩ ⟨transaction⟩
          }⍟((admitted.state ≡ "ok") ∧ (1 = ≠ admitted.transactions)) @
        }⍟declared @
      }⍟(shapeOk ∧ domainCountOk) @
      diagnostics ∾↩ localDiagnostics
    }¨ ↕ ≠ starts
  }⍟(0 = ≠ declarations.diagnostics) @

  diagnostics ∾↩ AddIf ⟨0 = ≠ starts, Diagnostic ⟨"transaction_missing", 0, "proof Journal must contain at least one dated transaction"⟩⟩
  {
    state⇐(0 = ≠ diagnostics) ⊑ "error"‿"ok",
    declared_domains⇐declarations.domains,
    transactions⇐transactions,
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}
