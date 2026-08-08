# journal_complete_admission.bqn
# Production complete-source admission for a multi-currency Journal container.
#
# One raw Journal may declare several registry-supported currency domains, or
# omit top-level commodity declarations and let transaction postings establish
# their domains. Every ordinary transaction remains single-domain and balances
# within its own exact calculation scale. A transaction-free Journal is valid.
# No Journal-wide money domain, scale, or total exists.

dates ← •Import "date_ordinal.bqn"
single ← •Import "journal_single_domain_admission.bqn"

lf ← @+10
cr ← @+13
space ← @+32
empty ← ⟨⟩
SplitKeepEmpty ← {𝕊 sep‿text:
  groups ← (+`sep=text)⊔text
  {(sep≠𝕩)/𝕩}¨groups
}
Split ← {𝕊 sep‿text:
  parts ← SplitKeepEmpty ⟨sep,text⟩
  (0<≠¨parts)/parts
}

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
IsDateHeader ← {𝕊 text:
  enough ← 10 < ≠ text
  separator ← space = 10 ⊑ (text ∾ 11 ⥊ space)
  enough ∧ separator ∧ dates.IsValid 10 ↑ text
}

Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {severity⇐"error", stage⇐"journal_complete_source_admission", code⇐codeText, line⇐lineNumber, message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid / ⟨diagnostic⟩ }

Declarations ← {𝕊 lines‿registry:
  diagnostics ← empty
  domains ← empty
  domainLines ← empty
  accounts ← empty
  {𝕊 lineIndex:
    text ← Trim lineIndex ⊑ lines
    {𝕊:
      fields ← Split ⟨space,text⟩
      valid ← 2 = ≠ fields
      diagnostics ∾↩ AddIf ⟨¬ valid, Diagnostic ⟨"commodity_shape_invalid", lineIndex + 1, "commodity declaration must contain exactly one code"⟩⟩
      {𝕊:
        domain ← 1 ⊑ fields
        policy ← registry.Policy domain
        diagnostics ∾↩ AddIf ⟨policy.state ≢ "ok", Diagnostic ⟨"commodity_unsupported", lineIndex + 1, "commodity must be admitted by registry"⟩⟩
        {𝕊:
          domains ∾↩ ⟨domain⟩
          domainLines ∾↩ ⟨lineIndex + 1⟩
        }⍟(policy.state ≡ "ok") @
      }⍟valid @
    }⍟(StartsWith ⟨"commodity ", text⟩) @
    {𝕊: accounts ∾↩ ⟨{text⇐text,account_key⇐8↓text,source_line⇐lineIndex+1}⟩}⍟(StartsWith ⟨"account ",text⟩) @
  }¨ ↕ ≠ lines
  duplicate ← (≠ domains) ≠ ≠ ⍷ domains
  diagnostics ∾↩ AddIf ⟨duplicate, Diagnostic ⟨"commodity_domain_duplicate", 0, "each declared commodity domain must appear once"⟩⟩
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
      fields ← Split ⟨space,trimmed⟩
      explicit ← 3 = ≠ fields
      elided ← 1 = ≠ fields
      valid ← explicit ∨ elided
      diagnostics ∾↩ AddIf ⟨¬ valid, Diagnostic ⟨"posting_shape_invalid", offset + 1, "posting must contain account plus explicit amount and commodity, or one elided account only"⟩⟩
      {𝕊: domains ∾↩ ⟨2 ⊑ fields⟩}⍟explicit @
    }⍟candidate @
  }¨ ↕ ≠ blockLines
  {domains⇐⍷ domains, diagnostics⇐diagnostics}
}

BuildPartition ← {𝕊 domain‿domainLine‿accounts‿blockLines‿blockStart:
  partitionLines ← ⟨"commodity " ∾ domain, ""⟩
  lineMap ← ⟨domainLine, 0⟩
  {𝕊 account:
    partitionLines ∾↩ ⟨account.text, ""⟩
    lineMap ∾↩ ⟨account.source_line, 0⟩
  }¨ accounts
  partitionLines ∾↩ blockLines
  lineMap ∾↩ blockStart + 1 + ↕ ≠ blockLines
  {raw⇐∾ (partitionLines ∾¨ lf), line_map⇐lineMap}
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

MapPosting ← {𝕊 posting‿lineMap‿sourceEventId:
  {
    posting_id⇐sourceEventId ∾ ":" ∾ •Fmt posting.posting_index,
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
  mappedStart ← MapLine ⟨transaction.source_start_line, lineMap⟩
  mappedSourceEventId ← transaction.source_event_id
  {𝕊: mappedSourceEventId ↩ "stage0-line-" ∾ •Fmt mappedStart}⍟(transaction.identity_kind ≡ "physical_fallback") @
  {
    source_event_id⇐mappedSourceEventId,
    identity_kind⇐transaction.identity_kind,
    source_start_line⇐mappedStart,
    source_end_line⇐MapLine ⟨transaction.source_end_line, lineMap⟩,
    date⇐transaction.date,
    status_marker⇐transaction.status_marker,
    description⇐transaction.description,
    layer_name⇐transaction.layer_name,
    txn_id⇐transaction.txn_id,
    plan_id⇐transaction.plan_id,
    allocation_id⇐transaction.allocation_id,
    execution_envelope⇐transaction.execution_envelope,
    actual_event_id⇐transaction.actual_event_id,
    domain⇐transaction.domain,
    calculation_scale⇐transaction.calculation_scale,
    metadata⇐transaction.metadata,
    postings⇐{MapPosting ⟨𝕩, lineMap, mappedSourceEventId⟩}¨ transaction.postings
  }
}

CrossTransactionDiagnostics ← {𝕊 transactions:
  diagnostics ← empty
  durableTransactions ← ({𝕩.identity_kind ≡ "durable"}¨ transactions) / transactions
  durableIds ← {<𝕩.source_event_id}¨ durableTransactions
  diagnostics ∾↩ AddIf ⟨(≠ durableIds) ≠ ≠ ⍷ durableIds, Diagnostic ⟨"event_id_duplicate", 0, "durable event-id values must be unique across the complete Journal source"⟩⟩
  diagnostics
}

Admit ← {𝕊 raw‿accounts‿registry:
  normalizedRaw ← (cr ≠ raw) / raw
  hasTerminalLf ← (0 < ≠ normalizedRaw) ∧ (lf = ⊑⌽normalizedRaw)
  {𝕊: normalizedRaw ↩ ¯1 ↓ normalizedRaw}⍟hasTerminalLf @
  lines ← SplitKeepEmpty ⟨lf,normalizedRaw⟩
  declarations ← Declarations ⟨lines,registry⟩
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
      localDiagnostics ∾↩ AddIf ⟨shapeOk ∧ (¬ domainCountOk), Diagnostic ⟨"transaction_domain_count_invalid", start + 1, "ordinary transaction must contain exactly one explicit posting currency domain"⟩⟩
      {𝕊:
        domain ← ⊑ domainEvidence.domains
        declarationRequired ← 0 < ≠ declarations.domains
        declared ← Contains ⟨domain, declarations.domains⟩
        localDiagnostics ∾↩ AddIf ⟨declarationRequired ∧ (¬ declared), Diagnostic ⟨"transaction_domain_undeclared", start + 1, "ordinary transaction currency must be declared by the Journal when commodity declarations are present"⟩⟩
        {𝕊:
          domainLine ← DomainSourceLine ⟨domain, declarations⟩
          {𝕊: domainLine ↩ start + 1}⍟(0=domainLine) @
          partition ← BuildPartition ⟨domain, domainLine, declarations.accounts, blockLines, start⟩
          admitted ← single.Admit ⟨partition.raw,accounts,registry⟩
          localDiagnostics ∾↩ {MapDiagnostic ⟨𝕩, partition.line_map⟩}¨ admitted.diagnostics
          {𝕊:
            transaction ← MapTransaction ⟨⊑ admitted.transactions, partition.line_map⟩
            transactions ∾↩ ⟨transaction⟩
          }⍟((admitted.state ≡ "ok") ∧ (1 = ≠ admitted.transactions)) @
        }⍟((¬declarationRequired) ∨ declared) @
      }⍟(shapeOk ∧ domainCountOk) @
      diagnostics ∾↩ localDiagnostics
    }¨ ↕ ≠ starts
  }⍟(0 = ≠ declarations.diagnostics) @

  diagnostics ∾↩ CrossTransactionDiagnostics transactions
  {𝕊: transactions ↩ empty}⍟(0 < ≠ diagnostics) @
  admittedDomains ← ⍷ declarations.domains ∾ {𝕩.domain}¨transactions
  {
    state⇐(0 = ≠ diagnostics) ⊑ "error"‿"ok",source_name⇐"actual.journal",
    declared_domains⇐admittedDomains,
    declared_layers⇐⍷ ⟨"actual"⟩∾{𝕩.layer_name}¨transactions,
    declared_accounts⇐{𝕩.account_key}¨declarations.accounts,
    transactions⇐transactions,
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}
