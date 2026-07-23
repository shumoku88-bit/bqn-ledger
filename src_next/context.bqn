# context.bqn
# Ledger context and period view construction for src_next.
#
# Architecture:
#   BuildAllRows      — load posting rows from the explicitly selected sources (depends on cycleStart
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
arith ← •Import "currency_arithmetic.bqn"
ak ← •Import "account_key.bqn"
proj ← •Import "projection.bqn"
cycle ← •Import "cycle.bqn"
cube ← •Import "cube.bqn"
tbds ← •Import "tbds.bqn"
currency_setup ← •Import "currency_setup.bqn"
config ← •Import "config.bqn"
journal_parser ← •Import "journal_profile_stage1.bqn"
journal_adapter ← •Import "journal_posting_ir_stage2a.bqn"

MakePostingSource ← {𝕊 srcFile‿required‿lines:
  { source_file ⇐ srcFile, required ⇐ required, lines ⇐ lines }
}

# LoadPostingSourceSnapshot: explicit TSV compatibility-mode snapshot.
# journal.tsv is required only on this selected route; plan/budget remain optional.
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

# Native Journal mode keeps plan and budget TSV as independent non-actual sources.
# It never reads journal.tsv and never falls back to it.
LoadNonActualPostingSourceSnapshot ← {𝕊 base:
  {
    sources ⇐ ⟨
      MakePostingSource ⟨"plan.tsv", 0, loader.ReadLinesOptional (base ∾ "/plan.tsv")⟩,
      MakePostingSource ⟨"budget_alloc.tsv", 0, loader.ReadLinesOptional (base ∾ "/budget_alloc.tsv")⟩
    ⟩
  }
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
      resolved_currency ↩ val
    } ⍟ (currency_setup.IsSupportedCurrency val) @
    {𝕊:
      currency_state ↩ "error"
      err_msg ↩ "unsupported currency: " ∾ val
    } ⍟ (¬ currency_setup.IsSupportedCurrency val) @
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

ResolveArithmeticCurrencyProof ← {𝕊 evidence‿arithmeticEvidence:
  has_error ← ∨´ { 𝕩.state ≢ "ok" } ¨ evidence
  
  proof ← {
    state ⇐ "unsupported",
    domain ⇐ "",
    basis ⇐ "",
    amount_scale ⇐ ⟨⟩,
    message ⇐ ""
  }

  {𝕊:
    bad_row ← ⊑ ({ 𝕩.state ≢ "ok" } ¨ evidence) / evidence
    basis ← (bad_row.provenance ≡ "legacy_compatibility") ⊑ ⟨"explicit_source_currency", "unsupported_row_evidence"⟩
    msg ← (bad_row.provenance ≡ "legacy_compatibility") ⊑ ⟨
      "explicit source currency unsupported in Stage 2 minimal runtime slice: " ∾ bad_row.source_file ∾ " row " ∾ (•Fmt bad_row.source_row) ∾ ": " ∾ bad_row.message,
      "row error in Stage 2 minimal runtime slice: " ∾ bad_row.source_file ∾ " row " ∾ (•Fmt bad_row.source_row) ∾ ": " ∾ bad_row.message
    ⟩
    proof ↩ {
      state ⇐ "unsupported",
      domain ⇐ "",
      basis ⇐ basis,
      amount_scale ⇐ ⟨⟩,
      message ⇐ msg
    }
  } ⍟ has_error @

  {𝕊:
    {𝕊:
      proof ↩ {
        state ⇐ "proven",
        domain ⇐ "JPY",
        basis ⇐ "empty_source_compatibility",
        amount_scale ⇐ 0,
        message ⇐ ""
      }
    } ⍟ (0 = ≠ evidence) @

    {𝕊:
      {𝕊:
        proof ↩ {
          state ⇐ "unsupported",
          domain ⇐ "",
          basis ⇐ "",
          amount_scale ⇐ ⟨⟩,
          message ⇐ arithmeticEvidence.message
        }
      } ⍟ (arithmeticEvidence.state ≢ "ok") @

      {𝕊:
        domain ← arithmeticEvidence.domain
        amount_scale ← arithmeticEvidence.amount_scale
        
        has_explicit ← ∨´ { 𝕩.provenance ≢ "legacy_compatibility" } ¨ evidence
        basis ← has_explicit ⊑ "legacy_compatibility"‿"resolved_single_currency"
        
        proof ↩ {
          state ⇐ "proven",
          domain ⇐ domain,
          basis ⇐ basis,
          amount_scale ⇐ amount_scale,
          message ⇐ ""
        }
      } ⍟ (arithmeticEvidence.state ≡ "ok") @
    } ⍟ (0 < ≠ evidence) @
  } ⍟ (¬ has_error) @

  proof
}

BuildProjectionRowsForEvidence ← {𝕊 ⟨row, coef, resolved, cycleStart⟩:
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
  amountOk   ← row.parsed.state ≡ "ok"
  amount   ← 0
  {𝕊: amount ↩ coef }⍟amountOk @

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

MakeCheckedDiagnostic ← {𝕊 stage‿code‿message:
  {
    severity ⇐ "error",
    stage ⇐ stage,
    code ⇐ code,
    message ⇐ message
  }
}

# BuildCheckedPostingProjectionFromPrepared: pure checked-result owner over
# already-derived evidence and arithmetic evidence. The exported ForTest alias is
# a narrow structural-mismatch seam; normal callers use the snapshot boundary.
BuildCheckedPostingProjectionFromPrepared ← {𝕊 evidence‿arithmeticEvidence‿resolved‿cycleStart:
  proof ← ResolveArithmeticCurrencyProof ⟨evidence, arithmeticEvidence⟩
  authorizationMessage ← proj.ArithmeticCurrencyAuthorizationMessage proof
  result ← {
    state ⇐ "error",
    row_evidence ⇐ evidence,
    arithmetic_evidence ⇐ arithmeticEvidence,
    arithmetic_currency_proof ⇐ proof,
    posting_rows ⇐ ⟨⟩,
    diagnostics ⇐ ⟨MakeCheckedDiagnostic ⟨"authorization", "arithmetic_currency_proof_rejected", authorizationMessage⟩⟩
  }

  authorized ← proj.AuthorizeArithmeticCurrencyProof proof
  {𝕊:
    lengthMismatch ← (≠evidence) ≢ (≠arithmeticEvidence.normalized_coefficients)
    {𝕊:
      result ↩ {
        state ⇐ "error",
        row_evidence ⇐ evidence,
        arithmetic_evidence ⇐ arithmeticEvidence,
        arithmetic_currency_proof ⇐ proof,
        posting_rows ⇐ ⟨⟩,
        diagnostics ⇐ ⟨MakeCheckedDiagnostic ⟨"structure", "normalized_coefficient_length_mismatch", "evidence and normalized coefficients length mismatch"⟩⟩
      }
    }⍟lengthMismatch @

    {𝕊:
      rows ← ∾ ({𝕊 i:
        row ← i ⊑ evidence
        coef ← i ⊑ arithmeticEvidence.normalized_coefficients
        BuildProjectionRowsForEvidence ⟨row, coef, resolved, cycleStart⟩
      } ¨ ↕ ≠ evidence)
      result ↩ {
        state ⇐ "ok",
        row_evidence ⇐ evidence,
        arithmetic_evidence ⇐ arithmeticEvidence,
        arithmetic_currency_proof ⇐ proof,
        posting_rows ⇐ rows,
        diagnostics ⇐ ⟨⟩
      }
    }⍟(¬lengthMismatch) @
  }⍟authorized @

  result
}

# BuildCheckedPostingProjectionFromSnapshot: selected Phase C public pure boundary.
# It reads no files, prints nothing, exits nowhere, and derives all checked data
# from the exact supplied snapshot.
BuildCheckedPostingProjectionFromSnapshot ← {𝕊 snapshot‿resolved‿cycleStart:
  evidence ← BuildRowEvidenceFromSnapshot snapshot
  arithmeticEvidence ← arith.Build evidence
  BuildCheckedPostingProjectionFromPrepared ⟨evidence, arithmeticEvidence, resolved, cycleStart⟩
}

AuthorizedRowsFromCheckedResult ← {𝕊 result:
  {𝕊:
    diagnostic ← ⊑ result.diagnostics
    •Out "ERROR: " ∾ diagnostic.message
    •Exit 1
  }⍟(result.state ≢ "ok") @
  { rows ⇐ result.posting_rows, arithmetic_currency_proof ⇐ result.arithmetic_currency_proof }
}

# BuildAuthorizedRowsFromPreparedForTest: narrow compatibility-wrapper test seam
# for the otherwise defensive structural-mismatch branch.
BuildAuthorizedRowsFromPreparedForTest ← {𝕊 evidence‿arithmeticEvidence‿resolved‿cycleStart:
  result ← BuildCheckedPostingProjectionFromPrepared ⟨evidence, arithmeticEvidence, resolved, cycleStart⟩
  AuthorizedRowsFromCheckedResult result
}

# BuildAuthorizedRowsFromSnapshot: compatibility wrapper preserving the existing
# success shape, fatal stdout prefix, and exit code while delegating calculation
# to the pure checked-result boundary.
BuildAuthorizedRowsFromSnapshot ← {𝕊 snapshot‿resolved‿cycleStart:
  result ← BuildCheckedPostingProjectionFromSnapshot ⟨snapshot, resolved, cycleStart⟩
  AuthorizedRowsFromCheckedResult result
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
  cfg ← config.LoadConfig base2
  actual_source_mode ← cfg.ActualSource @
  actual_source_file ← "journal.tsv"
  actual_transactions ← ⟨⟩
  arithmetic_currency_proof ← @
  rows ← ⟨⟩

  {𝕊:
    posting_snapshot ← LoadPostingSourceSnapshot base2
    built_rows ← BuildAuthorizedRowsFromSnapshot ⟨posting_snapshot, resolved, cy.start⟩
    arithmetic_currency_proof ↩ built_rows.arithmetic_currency_proof
    rows ↩ built_rows.rows
  }⍟(actual_source_mode ≡ "tsv") @

  {𝕊:
    journal_rel ← cfg.ActualJournalFile @
    {𝕊: •Out "CONFIG ERROR: ACTUAL_JOURNAL_FILE is required in journal mode" ⋄ •Exit 1}⍟(0=≠journal_rel) @
    actual_source_file ↩ journal_rel
    raw ← loader.ReadRaw (base2 ∾ "/" ∾ journal_rel)
    parsed ← journal_parser.ParseWithProfile ⟨raw,"historical_external_plan"⟩
    {𝕊: •Out "ERROR: native Journal source rejected" ⋄ •Exit 1}⍟(parsed.state≢"ok") @
    declared ← ⍋ {𝕩.account_key}¨ parsed.accounts
    registry ← ⍋ resolved.accounts
    {𝕊: •Out "ERROR: native Journal account declarations differ from accounts.tsv" ⋄ •Exit 1}⍟(declared≢registry) @
    journal_checked ← journal_adapter.BuildForSource ⟨parsed.transactions,resolved,cy.start,journal_rel⟩
    {𝕊: •Out "ERROR: native Journal Posting IR rejected" ⋄ •Exit 1}⍟(journal_checked.state≢"ok") @
    nonactual_snapshot ← LoadNonActualPostingSourceSnapshot base2
    nonactual ← BuildAuthorizedRowsFromSnapshot ⟨nonactual_snapshot,resolved,cy.start⟩
    {𝕊: •Out "ERROR: native Journal mode requires one JPY arithmetic domain" ⋄ •Exit 1}⍟(nonactual.arithmetic_currency_proof.domain≢"JPY") @
    actual_transactions ↩ parsed.transactions
    arithmetic_currency_proof ↩ nonactual.arithmetic_currency_proof
    rows ↩ journal_checked.posting_rows ∾ nonactual.rows
  }⍟(actual_source_mode ≡ "journal") @

  valid_actual_source ← ∨´ actual_source_mode⊸≡¨ ⟨"tsv","journal"⟩
  {𝕊: •Out "CONFIG ERROR: ACTUAL_SOURCE must be tsv or journal" ⋄ •Exit 1}⍟(¬valid_actual_source) @
  view ← BuildPeriodView ⟨rows, resolved, cy⟩
  
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
    actual_source_mode ⇐ actual_source_mode,
    actual_source_file ⇐ actual_source_file,
    actual_transactions ⇐ actual_transactions,
    arithmetic_currency_proof ⇐ arithmetic_currency_proof,
    cube         ⇐ view.cube,
    tbds         ⇐ view.tbds,
    issues       ⇐ issues
  }
}

{
  BuildContext ⇐ BuildContext,
  LoadPostingSourceSnapshot ⇐ LoadPostingSourceSnapshot,
  LoadNonActualPostingSourceSnapshot ⇐ LoadNonActualPostingSourceSnapshot,
  BuildRowEvidenceFromSnapshot ⇐ BuildRowEvidenceFromSnapshot,
  ResolveArithmeticCurrencyProof ⇐ ResolveArithmeticCurrencyProof,
  BuildCheckedPostingProjectionFromSnapshot ⇐ BuildCheckedPostingProjectionFromSnapshot,
  BuildCheckedPostingProjectionFromPreparedForTest ⇐ BuildCheckedPostingProjectionFromPrepared,
  BuildAuthorizedRowsFromPreparedForTest ⇐ BuildAuthorizedRowsFromPreparedForTest,
  BuildAuthorizedRowsFromSnapshot ⇐ BuildAuthorizedRowsFromSnapshot,
  BuildAllRowsFromSnapshot ⇐ BuildAllRowsFromSnapshot,
  BuildAllRows ⇐ BuildAllRows,
  BuildPeriodView ⇐ BuildPeriodView,
  BuildRowsForFile ⇐ BuildRowsForFile,
  BuildRowsForFileOptional ⇐ BuildRowsForFileOptional
}
