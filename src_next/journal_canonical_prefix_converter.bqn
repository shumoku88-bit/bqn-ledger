# journal_canonical_prefix_converter.bqn
# Pure, public-synthetic-capable one-way legacy TSV -> canonical Journal prefix.
# Production source routing and writers do not import this module.

loader ← •Import "loader.bqn"
decimal ← •Import "exact_decimal.bqn"
dates ← •Import "date.bqn"
ak ← •Import "account_key.bqn"
context ← •Import "context.bqn"
parser ← •Import "journal_profile_stage1.bqn"
stage2a ← •Import "journal_posting_ir_stage2a.bqn"
stage2b ← •Import "journal_posting_identity_provenance_stage2b.bqn"

empty ← ⟨⟩
lf ← @+10
cr ← @+13
tab ← @+9
space ← @+32

metadataInputKeys ← ⟨
  <"tax", <"biz", <"invoice", <"note", <"due_on", <"receipt",
  <"txn_id", <"party", <"plan_id", <"cashflow", <"currency", <"income_budget"
⟩
metadataOutputKeys ← ⟨
  <"tax", <"biz", <"invoice", <"note", <"due-on", <"receipt",
  <"txn-id", <"party", <"plan-id", <"cashflow", <"currency", <"income-budget"
⟩

Diagnostic ← {𝕊 codeText‿rowNumber‿messageText:
  {severity⇐"error", stage⇐"journal_canonical_prefix_converter", code⇐codeText, source_row⇐rowNumber, message⇐messageText}
}
AddIf ← {𝕊 diagnostics‿invalid‿codeText‿rowNumber‿messageText:
  diagnostics ∾ invalid / ⟨Diagnostic ⟨codeText, rowNumber, messageText⟩⟩
}
IsOneOf ← {𝕊 text‿boxedValues: ∨´ 0 ∾ {text ≡ >𝕩}¨ boxedValues}
TrimLeft ← {𝕊 xs: (+´ ∧` (xs = space)) ↓ xs}
TrimRight ← {𝕊 xs: ((≠ xs) - +´ ∧` ((⌽ xs) = space)) ↑ xs}
Trim ← {TrimRight TrimLeft 𝕩}
UnsafeText ← {𝕊 text:
  controls ← ((@+0) + ↕32) ∾ ⟨@+127⟩
  ∨´ 0 ∾ text ∊ controls
}

DescriptionRepresentable ← {𝕊 text:
  (0 < ≠ text) ∧ (text ≡ Trim text) ∧ ¬ UnsafeText text
}
SafeValue ← {𝕊 text: (0 < ≠ text) ∧ (text ≡ Trim text) ∧ ¬ UnsafeText text}

SplitSnapshotLines ← {𝕊 raw:
  rawLines ← lf loader.SplitKeepEmpty raw
  # Match loader.ReadLines admission while retaining internal CR as rejection
  # evidence. A terminal CR is treated only as a CRLF line ending.
  cleaned ← {𝕊 line:
    result ← line
    {𝕊:
      {𝕊: result ↩ ¯1↓line}⍟(cr=¯1⊑line) @
    }⍟(0<≠line) @
    result
  }¨ rawLines
  IsData ← { (0 < ≠ 𝕩) ? ((⊑𝕩 ≠ '#') ∧ (⊑𝕩 ≠ ⊑"\\")) ; 0 }
  (IsData¨cleaned) / cleaned
}

ParseMetadata ← {𝕊 fields‿rowNumber:
  diagnostics ← empty
  items ← empty
  keys ← empty
  {𝕊 token:
    equalPositions ← ('=' = token) / ↕ ≠ token
    validShape ← 0 < ≠ equalPositions
    key ← ""
    value ← ""
    {𝕊:
      i ← ⊑ equalPositions
      key ↩ i ↑ token
      value ↩ (i+1) ↓ token
    }⍟validShape @
    known ← validShape ∧ IsOneOf ⟨key, metadataInputKeys⟩
    diagnostics ↩ AddIf ⟨diagnostics, ¬validShape, "metadata_shape_invalid", rowNumber, "metadata must use key=value"⟩
    diagnostics ↩ AddIf ⟨diagnostics, validShape ∧ ¬known, "metadata_unknown", rowNumber, "metadata key is not admitted by the canonical mapping"⟩
    diagnostics ↩ AddIf ⟨diagnostics, known ∧ ¬SafeValue value, "metadata_value_invalid", rowNumber, "metadata value must be nonempty and canonically representable"⟩
    {𝕊:
      outIndex ← ⊑ ({key ≡ >𝕩}¨metadataInputKeys) / ↕≠metadataInputKeys
      outKey ← > outIndex ⊑ metadataOutputKeys
      validControlled ← parser.LegacyMetadataValueValid ⟨outKey, value⟩
      diagnostics ↩ AddIf ⟨diagnostics, ¬validControlled, "metadata_value_invalid", rowNumber, "controlled metadata value is malformed"⟩
      keys ∾↩ ⟨<key⟩
      items ∾↩ ⟨{input_key⇐key, output_key⇐outKey, value⇐value}⟩
    }⍟(known ∧ SafeValue value) @
  }¨ fields
  diagnostics ↩ AddIf ⟨diagnostics, (≠keys) ≠ ≠⍷keys, "metadata_duplicate", rowNumber, "metadata keys must be unique within one TSV row"⟩
  {state⇐(0=≠diagnostics)⊑"error"‿"ok", diagnostics⇐diagnostics, items⇐items}
}

ParseRows ← {𝕊 raw:
  lines ← SplitSnapshotLines raw
  diagnostics ← empty
  rows ← empty
  {𝕊 rowNumber:
    line ← rowNumber ⊑ lines
    fields ← tab loader.SplitKeepEmpty line
    enough ← 5 ≤ ≠ fields
    diagnostics ↩ AddIf ⟨diagnostics, ¬enough, "tsv_required_fields_missing", rowNumber, "legacy journal row requires at least five fields"⟩
    {𝕊:
      dateText ← 0⊑fields
      description ← 1⊑fields
      fromAccount ← 2⊑fields
      toAccount ← 3⊑fields
      amountText ← 4⊑fields
      parsedAmount ← decimal.Parse amountText
      amountOk ← (parsedAmount.state≡"ok") ∧ (0=parsedAmount.scale) ∧ (0<parsedAmount.coefficient)
      diagnostics ↩ AddIf ⟨diagnostics, ¬dates.IsValidDateText dateText, "date_invalid", rowNumber, "date must be a valid YYYY-MM-DD calendar date"⟩
      diagnostics ↩ AddIf ⟨diagnostics, ¬DescriptionRepresentable description, "description_not_canonically_representable", rowNumber, "description must round-trip exactly without trimming, normalization, or controls"⟩
      diagnostics ↩ AddIf ⟨diagnostics, (¬SafeValue fromAccount) ∨ ¬SafeValue toAccount, "account_text_invalid", rowNumber, "account fields must be nonempty canonical text"⟩
      diagnostics ↩ AddIf ⟨diagnostics, ¬amountOk, "amount_not_exact_integer_jpy", rowNumber, "amount must be a positive exact integer JPY value"⟩
      metadata ← ParseMetadata ⟨5↓fields, rowNumber⟩
      diagnostics ∾↩ metadata.diagnostics
      {𝕊:
        rows ∾↩ ⟨{
          source_row⇐rowNumber, date⇐dateText, description⇐description,
          from_account⇐fromAccount, to_account⇐toAccount,
          amount⇐parsedAmount.coefficient, metadata⇐metadata.items, fields⇐fields
        }⟩
      }⍟((dates.IsValidDateText dateText) ∧ (DescriptionRepresentable description) ∧ (SafeValue fromAccount) ∧ (SafeValue toAccount) ∧ amountOk ∧ metadata.state≡"ok") @
    }⍟enough @
  }¨ ↕≠lines
  {state⇐(0=≠diagnostics)⊑"error"‿"ok", diagnostics⇐diagnostics, rows⇐rows, lines⇐lines}
}

MetadataValue ← {𝕊 inputKey‿items:
  matching ← ({𝕩.input_key≡inputKey}¨items)/items
  result ← ""
  {𝕊: result ↩ (⊑matching).value}⍟(0<≠matching) @
  result
}

SourceIdentityDiagnostics ← {𝕊 rows‿sourceFileIdentity:
  ids ← {<"legacy:"∾sourceFileIdentity∾":"∾•Fmt 𝕩.source_row}¨rows
  AddIf ⟨empty, (≠ids)≠≠⍷ids, "source_identity_duplicate", 0, "canonical legacy source identities must be unique"⟩
}

RenderAccount ← {𝕊 index‿resolved:
  account ← index⊑resolved.accounts
  metas ← index⊑resolved.raw_metadata
  role ← ak.MetaValue ⟨"role", "", metas⟩
  kind ← ak.MetaValue ⟨"kind", "", metas⟩
  defaultEnvelope ← ak.MetaValue ⟨"budget", "", metas⟩
  lines ← ⟨"account "∾account⟩
  {𝕊: lines ∾↩ ⟨"    ; role: "∾role⟩}⍟(0<≠role) @
  {𝕊: lines ∾↩ ⟨"    ; kind: "∾kind⟩}⍟(0<≠kind) @
  {𝕊: lines ∾↩ ⟨"    ; default-envelope: "∾defaultEnvelope⟩}⍟(0<≠defaultEnvelope) @
  ∾ lines ∾¨ <lf
}

RenderTransaction ← {𝕊 row‿sourceFileIdentity:
  eventId ← "legacy:"∾sourceFileIdentity∾":"∾•Fmt row.source_row
  lines ← ⟨row.date∾" * "∾row.description, "    ; event-id: "∾eventId, "    ; layer: actual"⟩
  {𝕊 outKeyBox:
    outKey ← >outKeyBox
    matching ← ({𝕩.output_key≡outKey}¨row.metadata)/row.metadata
    {𝕊: lines ∾↩ ⟨"    ; "∾outKey∾": "∾(⊑matching).value⟩}⍟(0<≠matching) @
  }¨ metadataOutputKeys
  amountText ← •Fmt row.amount
  lines ∾↩ ⟨"    "∾row.to_account∾" "∾amountText∾" JPY"⟩
  lines ∾↩ ⟨"    "∾row.from_account∾" -"∾amountText∾" JPY"⟩
  ∾ lines ∾¨ <lf
}

ValidateRegistry ← {𝕊 rows‿resolved:
  diagnostics ← empty
  accountNames ← {<𝕩}¨resolved.accounts
  diagnostics ↩ AddIf ⟨diagnostics, (≠accountNames)≠≠⍷accountNames, "account_registry_duplicate", 0, "account registry names must be unique"⟩
  relevantKeys ← ⟨<"role",<"kind",<"budget",<"currency"⟩
  {𝕊 metas:
    {𝕊 keyBox:
      key ← >keyBox
      prefix ← key∾"="
      matches ← {((≠prefix)≤≠𝕩) ∧ prefix≡(≠prefix)↑𝕩}¨metas
      diagnostics ↩ AddIf ⟨diagnostics, 1<+´matches, "account_metadata_duplicate", 0, "required account metadata keys must be unique"⟩
    }¨relevantKeys
  }¨resolved.raw_metadata
  required ← ∾ {⟨<𝕩.from_account, <𝕩.to_account⟩}¨rows
  {𝕊 accountBox:
    account ← >accountBox
    matches ← account⊸≡¨resolved.accounts
    diagnostics ↩ AddIf ⟨diagnostics, 1≠+´matches, "account_unresolved", 0, "every required account must resolve exactly once"⟩
    {𝕊:
      i ← ⊑ matches/↕≠matches
      diagnostics ↩ AddIf ⟨diagnostics, "JPY"≢i⊑resolved.currencies, "account_currency_incompatible", 0, "every required account must resolve to JPY"⟩
    }⍟(1=+´matches) @
  }¨required
  {state⇐(0=≠diagnostics)⊑"error"‿"ok", diagnostics⇐diagnostics}
}

ValidateJournalAccountCurrencies ← {𝕊 transactions‿resolved:
  diagnostics ← empty
  {𝕊 transaction:
    {𝕊 posting:
      matches ← posting.account_key⊸≡¨resolved.accounts
      diagnostics ↩ AddIf ⟨diagnostics, 1≠+´matches, "account_unresolved", 0, "every Journal posting account must resolve exactly once"⟩
      {𝕊:
        i ← ⊑matches/↕≠matches
        diagnostics ↩ AddIf ⟨diagnostics, "JPY"≢i⊑resolved.currencies, "account_currency_incompatible", 0, "every Journal posting account must resolve to JPY"⟩
      }⍟(1=+´matches) @
    }¨transaction.postings
  }¨transactions
  diagnostics
}

ErrorResult ← {𝕊 diagnostics:
  {
    state⇐"error", canonical_prefix_bytes⇐"", diagnostics⇐diagnostics,
    validation_summary⇐{source_row_count⇐0, transaction_count⇐0, posting_count⇐0, parser_pass⇐0, account_resolver_pass⇐0, stage2a_pass⇐0, stage2b_pass⇐0, accounting_parity_pass⇐0, identity_parity_pass⇐0, metadata_parity_pass⇐0},
    transactions⇐empty, posting_rows⇐empty, provenance_rows⇐empty, legacy_posting_rows⇐empty
  }
}

Convert ← {𝕊 snapshotRaw‿sourceFileIdentity‿accountLines‿cycleStart:
  sourceIdentityOk ← (SafeValue sourceFileIdentity) ∧ ¬('/'∊sourceFileIdentity) ∧ ¬(':'∊sourceFileIdentity)
  sourceDiagnostic ← AddIf ⟨empty, ¬sourceIdentityOk, "source_file_identity_invalid", 0, "source file identity must be a relative delimiter-safe token"⟩
  parsedRows ← ParseRows snapshotRaw
  diagnostics ← sourceDiagnostic ∾ parsedRows.diagnostics
  diagnostics ∾↩ SourceIdentityDiagnostics ⟨parsedRows.rows,sourceFileIdentity⟩
  result ← ErrorResult diagnostics

  {𝕊:
    resolved ← ak.Resolve accountLines
    registry ← ValidateRegistry ⟨parsedRows.rows, resolved⟩
    diagnostics ↩ registry.diagnostics
    {𝕊:
      order ← ⍋ resolved.accounts
      declarations ← "commodity JPY"∾lf
      {𝕊 i: declarations ∾↩ lf ∾ RenderAccount ⟨i,resolved⟩}¨order
      prefix ← declarations
      {𝕊 row: prefix ∾↩ lf ∾ RenderTransaction ⟨row,sourceFileIdentity⟩}¨parsedRows.rows

      parsed ← parser.ParseWithProfile ⟨prefix,"historical_external_plan"⟩
      diagnostics ∾↩ parsed.diagnostics
      stageA ← {state⇐"error", posting_rows⇐empty, diagnostics⇐empty}
      stageB ← {state⇐"error", posting_rows⇐empty, provenance_rows⇐empty, diagnostics⇐empty}
      {𝕊:
        stageA ↩ stage2a.Build ⟨parsed.transactions,resolved,cycleStart⟩
        diagnostics ∾↩ stageA.diagnostics
        {𝕊:
          stageB ↩ stage2b.Build ⟨parsed.transactions,stageA.posting_rows⟩
          diagnostics ∾↩ stageB.diagnostics
        }⍟(stageA.state≡"ok") @
      }⍟(parsed.state≡"ok") @

      snapshot ← {sources⇐⟨
        {source_file⇐"journal.tsv",required⇐1,lines⇐parsedRows.lines},
        {source_file⇐"plan.tsv",required⇐0,lines⇐empty},
        {source_file⇐"budget_alloc.tsv",required⇐0,lines⇐empty}
      ⟩}
      legacy ← context.BuildCheckedPostingProjectionFromSnapshot ⟨snapshot,resolved,cycleStart⟩
      diagnostics ∾↩ legacy.diagnostics
      legacyRows ← legacy.posting_rows
      journalRows ← stageA.posting_rows
      accountingParity ← (≠journalRows)=≠legacyRows
      {𝕊:
        accountingParity ↩ accountingParity ∧ ∧´ {𝕊 i:
          old ← i⊑legacyRows ⋄ new ← i⊑journalRows
          (old.date≡new.date) ∧ (old.account_key≡new.account_key) ∧ (old.delta=new.delta) ∧ (old.side≡new.side) ∧ (new.layer_name≡"actual") ∧ (new.status≡"ok")
        }¨↕≠journalRows
      }⍟accountingParity @
      identityParity ← (≠parsed.transactions)=≠parsedRows.rows
      {𝕊:
        identityParity ↩ identityParity ∧ ∧´ {𝕊 i:
          tx ← i⊑parsed.transactions ⋄ row ← i⊑parsedRows.rows
          expected ← "legacy:"∾sourceFileIdentity∾":"∾•Fmt row.source_row
          (tx.source_event_id≡expected) ∧ (tx.identity_kind≡"durable") ∧ (⟨0,1⟩≡{𝕩.posting_index}¨tx.postings) ∧ (⟨expected∾":0",expected∾":1"⟩≡{𝕩.posting_id}¨tx.postings)
        }¨↕≠parsedRows.rows
      }⍟identityParity @
      metadataParity ← (≠parsed.transactions)=≠parsedRows.rows
      {𝕊:
        metadataParity ↩ metadataParity ∧ ∧´ {𝕊 i:
          tx ← i⊑parsed.transactions ⋄ row ← i⊑parsedRows.rows
          expectedTxn ← MetadataValue ⟨"txn_id",row.metadata⟩
          expectedPlan ← MetadataValue ⟨"plan_id",row.metadata⟩
          (tx.description≡row.description) ∧ (tx.txn_id≡expectedTxn) ∧ (tx.plan_id≡expectedPlan) ∧ ((≠tx.metadata)=2+≠row.metadata)
        }¨↕≠parsedRows.rows
      }⍟metadataParity @
      diagnostics ↩ AddIf ⟨diagnostics, ¬accountingParity, "accounting_parity_failed", 0, "converted Journal accounting coordinates differ from the legacy adapter"⟩
      diagnostics ↩ AddIf ⟨diagnostics, ¬identityParity, "identity_parity_failed", 0, "canonical source identity or posting identity differs"⟩
      diagnostics ↩ AddIf ⟨diagnostics, ¬metadataParity, "metadata_parity_failed", 0, "description or business metadata differs"⟩

      {𝕊:
        result ↩ {
          state⇐"ok", canonical_prefix_bytes⇐prefix, diagnostics⇐empty,
          validation_summary⇐{
            source_row_count⇐≠parsedRows.rows, transaction_count⇐≠parsed.transactions,
            posting_count⇐≠stageA.posting_rows, parser_pass⇐1, account_resolver_pass⇐1,
            stage2a_pass⇐1, stage2b_pass⇐1, accounting_parity_pass⇐1,
            identity_parity_pass⇐1, metadata_parity_pass⇐1
          },
          transactions⇐parsed.transactions, posting_rows⇐stageA.posting_rows,
          provenance_rows⇐stageB.provenance_rows, legacy_posting_rows⇐legacyRows
        }
      }⍟((0=≠diagnostics) ∧ (parsed.state≡"ok") ∧ (stageA.state≡"ok") ∧ (stageB.state≡"ok") ∧ (legacy.state≡"ok")) @
      {𝕊: result ↩ ErrorResult diagnostics}⍟(0<≠diagnostics) @
    }⍟(registry.state≡"ok") @
    {𝕊: result ↩ ErrorResult diagnostics}⍟(registry.state≢"ok") @
  }⍟((0=≠diagnostics) ∧ parsedRows.state≡"ok") @
  result
}

CountOccurrences ← {𝕊 pattern‿text: +´ pattern ⍷ text}

Reconstruct ← {𝕊 verifiedPrefixResult‿suffixBytes‿resolved‿cycleStart:
  diagnostics ← empty
  verified ← (verifiedPrefixResult.state≡"ok") ∧ 0<≠verifiedPrefixResult.canonical_prefix_bytes
  diagnostics ↩ AddIf ⟨diagnostics, ¬verified, "verified_prefix_required", 0, "reconstruction requires a complete verified prefix result"⟩
  diagnostics ↩ AddIf ⟨diagnostics, 0=≠suffixBytes, "suffix_empty", 0, "synthetic suffix bytes must be nonempty"⟩
  candidate ← ""
  transactions ← empty
  postingRows ← empty
  {𝕊:
    prefix ← verifiedPrefixResult.canonical_prefix_bytes
    candidate ↩ prefix ∾ suffixBytes
    diagnostics ↩ AddIf ⟨diagnostics, 1≠CountOccurrences ⟨suffixBytes,candidate⟩, "suffix_exact_once_failed", 0, "suffix bytes must occur exactly once in reconstructed candidate"⟩
    parsedPrefix ← parser.ParseWithProfile ⟨prefix,"historical_external_plan"⟩
    parsedCandidate ← parser.ParseWithProfile ⟨candidate,"historical_external_plan"⟩
    diagnostics ∾↩ parsedPrefix.diagnostics ∾ parsedCandidate.diagnostics
    {𝕊:
      prefixCount ← ≠parsedPrefix.transactions
      diagnostics ∾↩ ValidateJournalAccountCurrencies ⟨parsedCandidate.transactions,resolved⟩
      diagnostics ↩ AddIf ⟨diagnostics, prefixCount≥≠parsedCandidate.transactions, "suffix_transaction_missing", 0, "suffix must add at least one native transaction"⟩
      {𝕊:
        suffixTransactions ← prefixCount↓parsedCandidate.transactions
        prefixIds ← {<𝕩.source_event_id}¨parsedPrefix.transactions
        suffixIds ← {<𝕩.source_event_id}¨suffixTransactions
        overlap ← ∨´0∾{IsOneOf ⟨>𝕩,prefixIds⟩}¨suffixIds
        diagnostics ↩ AddIf ⟨diagnostics, overlap, "suffix_transaction_duplicate", 0, "suffix transaction identity must not already occur in the prefix"⟩
      }⍟(prefixCount<≠parsedCandidate.transactions) @
      {𝕊:
        stageA ← stage2a.Build ⟨parsedCandidate.transactions,resolved,cycleStart⟩
        diagnostics ∾↩ stageA.diagnostics
        {𝕊:
          stageB ← stage2b.Build ⟨parsedCandidate.transactions,stageA.posting_rows⟩
          diagnostics ∾↩ stageB.diagnostics
          {𝕊: transactions↩parsedCandidate.transactions ⋄ postingRows↩stageA.posting_rows}⍟(stageB.state≡"ok") @
        }⍟(stageA.state≡"ok") @
      }⍟(0=≠diagnostics) @
    }⍟((parsedPrefix.state≡"ok") ∧ (parsedCandidate.state≡"ok")) @
  }⍟(verified ∧ 0<≠suffixBytes) @
  failed ← 0<≠diagnostics
  transactionCount ← failed⊑(≠transactions)‿0
  postingCount ← failed⊑(≠postingRows)‿0
  outputTransactions ← failed⊑transactions‿empty
  outputPostingRows ← failed⊑postingRows‿empty
  {
    state⇐failed⊑"ok"‿"error",
    reconstructed_candidate_bytes⇐failed⊑candidate‿"",
    diagnostics⇐diagnostics,
    validation_summary⇐{
      prefix_verified⇐verified, suffix_exact_once_pass⇐¬failed,
      candidate_parser_pass⇐¬failed, candidate_stage2a_pass⇐¬failed, candidate_stage2b_pass⇐¬failed,
      transaction_count⇐transactionCount, posting_count⇐postingCount
    },
    transactions⇐outputTransactions, posting_rows⇐outputPostingRows
  }
}

{
  Convert⇐Convert,
  Reconstruct⇐Reconstruct,
  DescriptionRepresentable⇐DescriptionRepresentable,
  SplitSnapshotLines⇐SplitSnapshotLines,
  SourceIdentityDiagnostics⇐SourceIdentityDiagnostics,
  metadataInputKeys⇐metadataInputKeys,
  metadataOutputKeys⇐metadataOutputKeys
}
