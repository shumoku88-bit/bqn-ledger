# journal_complete_admission.bqn
# Production complete-source admission for a multi-currency Journal container.
#
# One raw Journal may declare several registry-supported currency domains, or
# omit top-level commodity declarations when Account identity is owned outside
# the Journal. Legacy inline-Account Journals retain their explicit commodity
# declaration contract. Every ordinary transaction remains single-domain and
# balances within its own exact calculation scale. A transaction-free Journal
# is valid. No Journal-wide money domain, scale, or total exists.

dates ← •Import "date_ordinal.bqn"
single ← •Import "journal_single_domain_admission.bqn"
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
StartsWith ← {𝕊 prefix‿text:
  result ← 0
  {𝕊: result↩prefix≡(≠prefix)↑text}⍟((≠prefix)≤≠text) @
  result
}
Contains ← {𝕊 item‿items: ∨´ 0 ∾ item⊸≡¨ items }
IsDateHeader ← {𝕊 text:
  enough ← 10 < ≠ text
  separator ← IsWhitespace 10 ⊑ (text ∾ 11 ⥊ space)
  enough ∧ separator ∧ dates.IsValid 10 ↑ text
}

Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {severity⇐"error", stage⇐"journal_complete_source_admission", code⇐codeText, line⇐lineNumber, message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid / ⟨diagnostic⟩ }

Declarations ← {𝕊 lines‿registry:
  texts ← Trim¨lines
  ParseDeclaration ← {𝕊 lineIndex:
    text ← lineIndex ⊑ texts
    diagnostics ← empty
    domainItem ← @
    accountItem ← @
    {𝕊:
      fields ← Split ⟨space,text⟩
      valid ← 2 = ≠ fields
      diagnostics ∾↩ AddIf ⟨¬ valid, Diagnostic ⟨"commodity_shape_invalid", lineIndex + 1, "commodity declaration must contain exactly one code"⟩⟩
      {𝕊:
        domain ← 1 ⊑ fields
        policy ← registry.Policy domain
        diagnostics ∾↩ AddIf ⟨policy.state ≢ "ok", Diagnostic ⟨"commodity_unsupported", lineIndex + 1, "commodity must be admitted by registry"⟩⟩
        {𝕊: domainItem ↩ {value⇐domain,line⇐lineIndex+1}}⍟(policy.state ≡ "ok") @
      }⍟valid @
    }⍟(StartsWith ⟨"commodity ", text⟩) @
    {𝕊: accountItem ↩ {text⇐text,account_key⇐8↓text,source_line⇐lineIndex+1}}⍟(StartsWith ⟨"account ",text⟩) @
    {diagnostics⇐diagnostics,domain⇐domainItem,account⇐accountItem}
  }

  parsed ← ParseDeclaration¨↕≠lines
  rowDiagnostics ← ∾{𝕩.diagnostics}¨parsed
  domainItems ← {𝕩.domain}¨parsed
  admittedDomains ← ({𝕩≢@}¨domainItems)/domainItems
  domains ← {𝕩.value}¨admittedDomains
  domainLines ← {𝕩.line}¨admittedDomains
  accountItems ← {𝕩.account}¨parsed
  accounts ← ({𝕩≢@}¨accountItems)/accountItems
  duplicate ← (≠ domains) ≠ ≠ ⍷ domains
  duplicateDiagnostics ← AddIf ⟨duplicate, Diagnostic ⟨"commodity_domain_duplicate", 0, "each declared commodity domain must appear once"⟩⟩
  diagnostics ← rowDiagnostics∾duplicateDiagnostics
  {domains⇐domains, domain_lines⇐domainLines, accounts⇐accounts, diagnostics⇐diagnostics}
}

DomainSourceLine ← {𝕊 domain‿declarations:
  mask ← domain⊸≡¨ declarations.domains
  result ← 0
  {𝕊: result ↩ ⊑ mask / declarations.domain_lines}⍟(1 = +´ mask) @
  result
}

PostingDomains ← {𝕊 blockLines:
  PostingCandidate ← {𝕊 original:
    trimmed ← Trim original
    indented ← IsWhitespace ⊑(original∾" ")
    metadata ← ';' = ⊑(trimmed∾";")
    indented ∧ (0 < ≠ trimmed) ∧ (¬ metadata)
  }
  offsets ← ↕≠blockLines
  candidate ← PostingCandidate¨blockLines
  candidateOffsets ← candidate/offsets
  ParsePostingDomain ← {𝕊 offset:
    parsed ← postingText.Split offset⊑blockLines
    diagnostics ← AddIf ⟨¬parsed.valid, Diagnostic ⟨"posting_shape_invalid", offset + 1, "posting must contain account plus explicit amount and commodity, or one elided account only"⟩⟩
    domain ← @
    {𝕊: domain↩1⊑parsed.words}⍟(parsed.valid ∧ parsed.explicit) @
    {diagnostics⇐diagnostics,domain⇐domain}
  }
  parsed ← ParsePostingDomain¨candidateOffsets
  diagnostics ← ∾{𝕩.diagnostics}¨parsed
  domainItems ← {𝕩.domain}¨parsed
  domains ← ⍷({𝕩≢@}¨domainItems)/domainItems
  {domains⇐domains, diagnostics⇐diagnostics}
}

BuildPartition ← {𝕊 domain‿domainLine‿structuralAccountKeys‿blockLines‿blockStart:
  accountLines ← ∾⟨empty⟩∾{𝕊 accountKey: ⟨"account "∾accountKey,""⟩}¨structuralAccountKeys
  partitionLines ← ⟨"commodity "∾domain,""⟩∾accountLines∾blockLines
  accountLineMap ← (≠accountLines)⥊0
  lineMap ← ⟨domainLine,0⟩∾accountLineMap∾(blockStart + 1 + ↕≠blockLines)
  {raw⇐∾(partitionLines∾¨lf), line_map⇐lineMap}
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
  fallback ← transaction.identity_kind ≡ "physical_fallback"
  mappedSourceEventId ← fallback⊑⟨transaction.source_event_id,"stage0-line-"∾•Fmt mappedStart⟩
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
  durableTransactions ← ({𝕩.identity_kind ≡ "durable"}¨ transactions) / transactions
  durableIds ← {<𝕩.source_event_id}¨ durableTransactions
  AddIf ⟨(≠ durableIds) ≠ ≠ ⍷ durableIds, Diagnostic ⟨"event_id_duplicate", 0, "durable event-id values must be unique across the complete Journal source"⟩⟩
}

Admit ← {𝕊 raw‿accounts‿registry:
  normalizedRaw ← (cr ≠ raw) / raw
  hasTerminalLf ← 0
  {𝕊: hasTerminalLf ↩ lf = ⊑⌽normalizedRaw}⍟(0 < ≠ normalizedRaw) @
  {𝕊: normalizedRaw ↩ ¯1 ↓ normalizedRaw}⍟hasTerminalLf @
  lines ← SplitKeepEmpty ⟨lf,normalizedRaw⟩
  declarations ← Declarations ⟨lines,registry⟩
  diagnostics ← declarations.diagnostics
  inlineAccounts ← 0<≠declarations.accounts
  diagnostics ∾↩ AddIf ⟨inlineAccounts ∧ 0=≠declarations.domains, Diagnostic ⟨"commodity_domain_missing",0,"Journal with inline Account declarations must declare at least one commodity domain"⟩⟩

  starts ← (IsDateHeader¨ Trim¨ lines) / ↕≠lines
  ends ← 1↓(starts∾⟨≠lines⟩)
  ParseTransaction ← {𝕊 transactionIndex:
    start ← transactionIndex⊑starts
    end ← transactionIndex⊑ends
    blockLines ← (end-start)↑start↓lines
    domainEvidence ← PostingDomains blockLines
    localDiagnostics ← {𝕊 diagnostic:
      {severity⇐diagnostic.severity,stage⇐diagnostic.stage,code⇐diagnostic.code,line⇐start+diagnostic.line,message⇐diagnostic.message}
    }¨domainEvidence.diagnostics
    transaction ← @
    shapeOk ← 0=≠localDiagnostics
    domainCountOk ← 1=≠domainEvidence.domains
    localDiagnostics ∾↩ AddIf ⟨shapeOk ∧ (¬domainCountOk), Diagnostic ⟨"transaction_domain_count_invalid",start+1,"ordinary transaction must contain exactly one explicit posting currency domain"⟩⟩
    {𝕊:
      domain ← ⊑domainEvidence.domains
      declarationRequired ← 0<≠declarations.domains
      declared ← Contains ⟨domain,declarations.domains⟩
      localDiagnostics ∾↩ AddIf ⟨declarationRequired ∧ (¬declared), Diagnostic ⟨"transaction_domain_undeclared",start+1,"ordinary transaction currency must be declared by the Journal when commodity declarations are present"⟩⟩
      {𝕊:
        declaredAccountKeys ← {𝕩.account_key}¨declarations.accounts
        structuralAccountKeys ← (0=≠declaredAccountKeys)⊑⟨declaredAccountKeys,accounts.key⟩
        declaredDomainLine ← DomainSourceLine ⟨domain,declarations⟩
        domainLine ← (0=declaredDomainLine)⊑⟨declaredDomainLine,start+1⟩
        partition ← BuildPartition ⟨domain,domainLine,structuralAccountKeys,blockLines,start⟩
        admitted ← single.Admit ⟨partition.raw,accounts,registry⟩
        localDiagnostics ∾↩ {MapDiagnostic ⟨𝕩,partition.line_map⟩}¨admitted.diagnostics
        {𝕊: transaction↩MapTransaction ⟨⊑admitted.transactions,partition.line_map⟩}⍟((admitted.state≡"ok") ∧ (1=≠admitted.transactions)) @
      }⍟((¬declarationRequired) ∨ declared) @
    }⍟(shapeOk ∧ domainCountOk) @
    {diagnostics⇐localDiagnostics,transaction⇐transaction}
  }

  parsedTransactions ← empty
  {𝕊: parsedTransactions↩ParseTransaction¨↕≠starts}⍟(0=≠diagnostics) @
  transactionDiagnostics ← ∾{𝕩.diagnostics}¨parsedTransactions
  transactionItems ← {𝕩.transaction}¨parsedTransactions
  transactions ← ({𝕩≢@}¨transactionItems)/transactionItems
  diagnostics ∾↩ transactionDiagnostics
  diagnostics ∾↩ CrossTransactionDiagnostics transactions
  {𝕊: transactions↩empty}⍟(0<≠diagnostics) @
  admittedDomains ← ⍷declarations.domains∾{𝕩.domain}¨transactions
  {
    state⇐(0=≠diagnostics)⊑"error"‿"ok",source_name⇐"actual.journal",
    declared_domains⇐admittedDomains,
    declared_layers⇐⍷⟨"actual"⟩∾{𝕩.layer_name}¨transactions,
    declared_accounts⇐{𝕩.account_key}¨declarations.accounts,
    transactions⇐transactions,
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}