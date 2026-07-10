# context.bqn
# Ledger context and period view construction for src_next.
#
# Architecture:
#   BuildAllRows      — load all posting rows from source TSV (depends on cycleStart
#                       for day_index resolution, but does not filter by period)
#   BuildPeriodView   — build cycle-bounded cube + ledger-wide TBDS from posting rows
#   BuildContext      — convenience: read cycle.tsv, build everything at once
#
# Contract:
#   cycle / period is a report query parameter, not a ledger loading boundary.
#   Posting rows are built for the full source history (cycleStart is for
#   day_index computation, not for row filtering).
#   TBDS uses all posting rows for opening balances, period-bounded for movement.
#   Context is read-only within sections. Sections must not mutate ctx.

loader ← •Import "loader.bqn"
dec ← •Import "exact_decimal.bqn"
ak ← •Import "account_key.bqn"
proj ← •Import "projection.bqn"
cycle ← •Import "cycle.bqn"
cube ← •Import "cube.bqn"
tbds ← •Import "tbds.bqn"

MakePostingSource ← {𝕊 srcFile‿required‿lines:
  { source_file ⇐ srcFile, required ⇐ required, lines ⇐ lines }
}

# LoadPostingSourceSnapshot: load all posting source lines once.
# journal.tsv remains required; plan.tsv and budget_alloc.tsv remain optional.
LoadPostingSourceSnapshot ← {𝕊 base:
  journalLines ← loader.ReadLines (base ∾ "/journal.tsv")
  planLines ← loader.ReadLinesOptional (base ∾ "/plan.tsv")
  budgetLines ← loader.ReadLinesOptional (base ∾ "/budget_alloc.tsv")
  {
    sources ⇐ ⟨
      MakePostingSource ⟨"journal.tsv", 1, journalLines⟩,
      MakePostingSource ⟨"plan.tsv", 0, planLines⟩,
      MakePostingSource ⟨"budget_alloc.tsv", 0, budgetLines⟩
    ⟩
  }
}

ProofProven ← {𝕊 basis: { state ⇐ "proven", domain ⇐ "JPY", basis ⇐ basis, message ⇐ "" } }
ProofUnsupportedCurrency ← {𝕊 srcFile‿rowIdx:
  { state ⇐ "unsupported", domain ⇐ "", basis ⇐ "explicit_source_currency", message ⇐ "explicit source currency unsupported in Stage 2 minimal runtime slice: " ∾ srcFile ∾ " row " ∾ (•Fmt rowIdx) }
}

BuildRowEvidenceForLine ← {𝕊 ⟨srcFile, rowIdx, flds⟩:
  amountText ← proj.FieldOrEmpty ⟨flds, 4⟩
  parsed ← dec.Parse amountText

  metas ← 5 ↓ flds
  pref ← "currency="
  plen ← 9 # length of "currency="
  ok_len ← { plen ≤ ≠ 𝕩 } ¨ metas
  is_match ← ok_len × { pref ≡ plen ↑ 𝕩 } ¨ metas
  hits ← is_match / metas

  # Default currency resolution values
  currency_state ← "ok"
  resolved_currency ← "JPY"
  provenance ← "legacy_compatibility"
  err_msg ← ""

  # 1. Duplicate currency tags
  {𝕊:
    currency_state ↩ "error"
    provenance ↩ "explicit"
    err_msg ↩ "duplicate currency metadata"
  } ⍟ (1 < ≠ hits) @

  # 2. Exactly one currency tag
  {𝕊:
    val ← plen ↓ ⊑ hits
    provenance ↩ "explicit"
    {𝕊:
      resolved_currency ↩ "JPY"
    } ⍟ (val ≡ "JPY") @
    {𝕊:
      resolved_currency ↩ "ILS"
    } ⍟ (val ≡ "ILS") @
    {𝕊:
      currency_state ↩ "error"
      err_msg ↩ "unsupported currency: " ∾ val
    } ⍟ (¬ (∨´ ⟨"JPY", "ILS"⟩ ≡¨ <val)) @
  } ⍟ (1 = ≠ hits) @

  row_state ← ((currency_state ≡ "ok") ∧ (parsed.state ≡ "ok")) ⊑ "error"‿"ok"
  message   ← (currency_state ≢ "ok") ⊑ parsed.message‿err_msg

  {
    source_file ⇐ srcFile,
    source_row ⇐ rowIdx,
    flds ⇐ flds,
    currency ⇐ resolved_currency,
    provenance ⇐ provenance,
    parsed ⇐ parsed,
    state ⇐ row_state,
    message ⇐ message
  }
}

BuildRowEvidenceFromSnapshot ← {𝕊 snapshot:
  ∾ {𝕊 src:
    {𝕊 i:
      flds ← loader.SplitTsvKeepEmpty (i ⊑ src.lines)
      BuildRowEvidenceForLine ⟨src.source_file, i, flds⟩
    } ¨ ↕ ≠ src.lines
  } ¨ snapshot.sources
}

ResolveArithmeticCurrencyProof ← {𝕊 arg:
  evidence ← (6 = •Type arg) ◶ ⟨{𝕊: arg}, {𝕊: BuildRowEvidenceFromSnapshot arg}⟩ @


  proof ← ProofProven "empty_source_compatibility"

  {𝕊:
    has_explicit ← ∨´ { 𝕩.provenance ≢ "legacy_compatibility" } ¨ evidence
    has_scale    ← ∨´ { (0 < ≠ 𝕩.parsed.scale) ⊑ 0‿(𝕩.parsed.scale > 0) } ¨ evidence

    (has_explicit ∨ has_scale) ◶ ⟨
      {𝕊: proof ↩ ProofProven "legacy_compatibility" },
      {𝕊:
        bad_mask ← { (𝕩.provenance ≢ "legacy_compatibility") ∨ ((0 < ≠ 𝕩.parsed.scale) ⊑ 0‿(𝕩.parsed.scale > 0)) } ¨ evidence
        bad_row ← ⊑ (bad_mask / evidence)
        basis ← "explicit_source_currency"
        msg ← "explicit source currency unsupported in Stage 2 minimal runtime slice: " ∾ bad_row.source_file ∾ " row " ∾ (•Fmt bad_row.source_row)
        {𝕊:
          msg ↩ msg ∾ ": " ∾ bad_row.message
        } ⍟ (bad_row.state ≢ "ok") @

        proof ↩ {
          state ⇐ "unsupported",
          domain ⇐ "",
          basis ⇐ basis,
          message ⇐ msg
        }
      }
    ⟩ @
  } ⍟ (0 < ≠ evidence) @

  proof
}

BuildProjectionRowsForEvidence ← {𝕊 ⟨row, resolved, cycleStart⟩:
  srcFile      ← row.source_file
  rowIdx       ← row.source_row
  flds         ← row.flds
  accounts     ← resolved.accounts
  accountRoles ← resolved.roles
  accountKeys  ← resolved.account_keys

  date       ← proj.FieldOrEmpty ⟨flds, 0⟩
  srcId      ← proj.FieldOrEmpty ⟨flds, 1⟩
  txId       ← proj.TxIdFromMeta ⟨srcId, flds⟩
  fromAcc    ← proj.FieldOrEmpty ⟨flds, 2⟩
  toAcc      ← proj.FieldOrEmpty ⟨flds, 3⟩
  amountText ← proj.FieldOrEmpty ⟨flds, 4⟩

  dateOk   ← proj.IsValidDateText date
  amountOk ← proj.IsIntegerText amountText
  amount   ← 0
  {𝕊: amount ↩ row.parsed.coefficient }⍟amountOk @

  fromIdx ← ⊑ accounts ⊐ ⟨fromAcc⟩
  toIdx   ← ⊑ accounts ⊐ ⟨toAcc⟩
  n       ← ≠ accounts

  fromKnown ← fromIdx < n
  toKnown   ← toIdx < n
  known     ← fromKnown ∧ toKnown

  status ← "ok"
  status ↩ (¬known) ⊑ status‿"unknown_account"
  status ↩ (¬amountOk) ⊑ status‿"invalid_amount"
  status ↩ (¬dateOk) ⊑ status‿"invalid_date"
  fromAkOut ← fromKnown ⊑ n‿fromIdx
  toAkOut   ← toKnown ⊑ n‿toIdx

  unknownMsg ← ""
  unknownMsg ↩ ((¬fromKnown) ∧ (¬toKnown)) ⊑ unknownMsg‿("unknown from account: "∾fromAcc∾"; unknown to account: "∾toAcc)
  unknownMsg ↩ ((¬fromKnown) ∧ toKnown) ⊑ unknownMsg‿("unknown from account: "∾fromAcc)
  unknownMsg ↩ (fromKnown ∧ (¬toKnown)) ⊑ unknownMsg‿("unknown to account: "∾toAcc)
  msg ← ""
  msg ↩ (status ≡ "unknown_account") ⊑ msg‿unknownMsg
  msg ↩ (status ≡ "invalid_amount") ⊑ msg‿("invalid amount: "∾amountText)
  msg ↩ (status ≡ "invalid_date") ⊑ msg‿("invalid date: "∾date)

  roleWithSentinel ← accountRoles ∾ ⟨""⟩
  keyWithSentinel  ← accountKeys ∾ ⟨""⟩
  fromRole ← fromAkOut ⊑ roleWithSentinel
  toRole   ← toAkOut ⊑ roleWithSentinel

  day ← 0
  cycleStartOk ← proj.IsValidDateText cycleStart
  {𝕊: day ↩ proj.ResolveDayFromCycle ⟨date, cycleStart⟩ }⍟(dateOk ∧ cycleStartOk) @

  layer ← proj.SourceLayer srcFile
  layerName ← proj.LayerName layer
  kind  ← proj.InferKind ⟨fromRole, toRole, fromAcc, toAcc⟩

  MakeSideRow ← {𝕊 side‿akIdx‿sideDelta:
    {
      source_file       ⇐ srcFile,
      source_row        ⇐ rowIdx,
      source_id         ⇐ srcId,
      tx_id             ⇐ txId,
      posting_id        ⇐ proj.PostingId ⟨srcFile, rowIdx, side⟩,
      date              ⇐ date,
      side              ⇐ side,
      day_index         ⇐ day,
      account_key       ⇐ akIdx ⊑ keyWithSentinel,
      account_key_index ⇐ akIdx,
      layer_name        ⇐ layerName,
      layer_index       ⇐ layer,
      delta             ⇐ sideDelta,
      kind              ⇐ kind,
      status            ⇐ status,
      message           ⇐ msg
    }
  }

  ⟨ MakeSideRow ⟨"debit", toAkOut, amount⟩,
    MakeSideRow ⟨"credit", fromAkOut, - amount⟩ ⟩
}

SourceFromSnapshot ← {𝕊 snapshot‿srcFile:
  isJournal ← srcFile ≡ "journal.tsv"
  isPlan ← srcFile ≡ "plan.tsv"
  isBudget ← srcFile ≡ "budget_alloc.tsv"
  known ← isJournal ∨ isPlan ∨ isBudget
  {𝕊:
    •Out "ERROR: unsupported posting source file: " ∾ srcFile
    •Exit 1
  }⍟(¬known) @
  matches ← (({𝕩.source_file}¨ snapshot.sources) ≡¨ <srcFile) / snapshot.sources
  {𝕊:
    •Out "ERROR: posting source missing from snapshot: " ∾ srcFile
    •Exit 1
  }⍟(0 = ≠ matches) @
  ⊑ matches
}

# BuildRowsForFile: compatibility exported path; still loads one full posting-source
# snapshot, derives proof from that snapshot, and projects only after authorization.
BuildRowsForFile ← {𝕊 base‿resolved‿cycleStart‿srcFile:
  snapshot ← LoadPostingSourceSnapshot base
  built ← BuildAuthorizedRowsFromSnapshot ⟨snapshot, resolved, cycleStart⟩
  sourceRows ← (({𝕩.source_file}¨ built.rows) ≡¨ <srcFile) / built.rows
  SourceFromSnapshot ⟨snapshot, srcFile⟩ # fail closed for unsupported srcFile
  sourceRows
}

# BuildRowsForFileOptional: compatibility wrapper; same authorization behavior as BuildRowsForFile.
BuildRowsForFileOptional ← BuildRowsForFile

# BuildAuthorizedRowsFromSnapshot: derive proof from the exact snapshot being projected.
BuildAuthorizedRowsFromSnapshot ← {𝕊 snapshot‿resolved‿cycleStart:
  evidence ← BuildRowEvidenceFromSnapshot snapshot
  proof ← ResolveArithmeticCurrencyProof evidence
  proj.RequireArithmeticCurrencyProof proof
  rows ← ∾ ({𝕊 row: BuildProjectionRowsForEvidence ⟨row, resolved, cycleStart⟩} ¨ evidence)
  { rows ⇐ rows, arithmetic_currency_proof ⇐ proof }
}

# BuildAllRowsFromSnapshot: compatibility wrapper with no independently supplied proof.
BuildAllRowsFromSnapshot ← {𝕊 snapshot‿resolved‿cycleStart:
  (BuildAuthorizedRowsFromSnapshot ⟨snapshot, resolved, cycleStart⟩).rows
}

# BuildAllRows: compatibility wrapper preserving one-snapshot proof/projection invariant.
BuildAllRows ← {𝕊 base‿resolved‿cycleStart:
  snapshot ← LoadPostingSourceSnapshot base
  BuildAllRowsFromSnapshot ⟨snapshot, resolved, cycleStart⟩
}

# BuildPeriodView: materialize cycle-bounded cube and ledger-wide TBDS from posting rows.
# Args: ⟨rows, resolved, cy⟩
#   rows     — all posting rows (ledger-wide, not period-filtered)
#   resolved — account_key.Resolve result
#   cy       — selected period (start, end_exclusive, day_count, mode)
# Returns: { cube, tbds }
BuildPeriodView ← {𝕊 rows‿resolved‿cy:
  # Cube is cycle-bounded: only rows with day_index in [0, day_count) are used.
  result ← cube.Materialize ⟨rows, cy.day_count, resolved.count⟩
  # TBDS uses all posting rows for opening balances, cycle-bounded for movement.
  tbdsRows ← tbds.Build ⟨rows, result, resolved, cy⟩
  { cube ⇐ result, tbds ⇐ tbdsRows }
}

# BuildContext: convenience — read cycle.tsv, build everything at once.
# Args: base (string, e.g. "data" or "fixtures/src-next-golden")
# Returns: context namespace.
BuildContext ← {𝕊 arg:
  is_string ← (0 = ≠ arg) ∨ (2 = •Type 0 ⊑ arg ∾ ⟨' '⟩)
  base ← is_string ⊑ ⟨ 0 ⊑ arg, arg ⟩
  base2 ← (0 < ≠ base) ⊑ ⟨ ".", base ⟩
  
  # Resolve default as_of: read cycle to find its start date
  cy_default ← cycle.ReadCycle base2
  as_of ← is_string ◶ ⟨ { 1 ⊑ arg }, { cy_default.start } ⟩ @
  
  cy           ← cycle.ReadCycle ⟨base2, as_of⟩
  accLines     ← loader.ReadLines (base2 ∾ "/accounts.tsv")
  resolved     ← ak.Resolve accLines
  posting_snapshot ← LoadPostingSourceSnapshot base2
  built_rows   ← BuildAuthorizedRowsFromSnapshot ⟨posting_snapshot, resolved, cy.start⟩
  arithmetic_currency_proof ← built_rows.arithmetic_currency_proof
  rows         ← built_rows.rows
  view         ← BuildPeriodView ⟨rows, resolved, cy⟩
  
  # Load and parse issues.tsv
  issueLines   ← loader.ReadLinesOptional (base2 ∾ "/issues.tsv")
  MakeIssueRow ← {𝕊 flds:
    # Ensure at least 5 fields are present
    flds2 ← flds ∾ (5-≠flds) ⥊ ⟨""⟩
    {
      date   ⇐ 0 ⊑ flds2,
      status ⇐ 1 ⊑ flds2,
      title  ⇐ 2 ⊑ flds2,
      amount ⇐ 3 ⊑ flds2,
      memo   ⇐ 4 ⊑ flds2
    }
  }
  issueRawRows ← (0 < ≠ issueLines) ◶ ⟨ { ⟨⟩ }, { loader.SplitTsvKeepEmpty ¨ 1 ↓ issueLines } ⟩ @
  issues       ← MakeIssueRow ¨ issueRawRows

  {
    base         ⇐ base2,
    as_of        ⇐ as_of,
    cy           ⇐ cy,
    resolved     ⇐ resolved,
    posting_rows ⇐ rows,
    arithmetic_currency_proof ⇐ arithmetic_currency_proof,
    cube         ⇐ view.cube,
    tbds         ⇐ view.tbds,
    issues       ⇐ issues
  }
}

{ BuildContext ⇐ BuildContext, LoadPostingSourceSnapshot ⇐ LoadPostingSourceSnapshot, BuildRowEvidenceFromSnapshot ⇐ BuildRowEvidenceFromSnapshot, ResolveArithmeticCurrencyProof ⇐ ResolveArithmeticCurrencyProof, BuildAuthorizedRowsFromSnapshot ⇐ BuildAuthorizedRowsFromSnapshot, BuildAllRowsFromSnapshot ⇐ BuildAllRowsFromSnapshot, BuildAllRows ⇐ BuildAllRows, BuildPeriodView ⇐ BuildPeriodView, BuildRowsForFile ⇐ BuildRowsForFile, BuildRowsForFileOptional ⇐ BuildRowsForFileOptional }
