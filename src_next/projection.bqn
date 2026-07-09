# projection.bqn
# Projection row skeleton for the cycle-ledger prototype.
#
# Contract (PROJECTION_CONTRACT.md):
#   source record
#     -> account resolution
#     -> currency resolution
#     -> AccountKey resolution
#     -> day/cycle resolution
#     -> layer assignment
#     -> delta output
#
# Non-goals for this skeleton:
#   - does not materialize a cube
#   - does not produce report sections
#   - does not perform currency conversion

dt ← •Import "date.bqn"

# ── Layer constants (AXIS_CONTRACT.md) ───────────────────────

layer_actual   ← 0
layer_plan     ← 1
layer_budget   ← 2
layer_forecast ← 3

# ── Layer mapping by source file ─────────────────────────────

source_layer_files ← ⟨"journal.tsv", "plan.tsv", "budget_alloc.tsv"⟩
source_layer_vals  ← ⟨layer_actual, layer_plan, layer_budget⟩

SourceLayer ← {𝕊 src:
  i ← source_layer_files ⊐ ⟨src⟩
  i ⊑ source_layer_vals
}

# ── ProjectionRow conceptual shape (PROJECTION_CONTRACT.md §3)
#   source_file       source TSV file name               (String)
#   source_row        line number in source file          (Number)
#   source_id         identifier from source record       (String)
#   tx_id             transaction group id                (String)
#   posting_id        stable posting row id               (String)
#   date              source date YYYY-MM-DD              (String)
#   side              "debit" / "credit"                 (String)
#   day_index         day offset within loaded range      (Number)
#   account_key       canonical AccountKey string          (String)
#   account_key_index index into AccountKey table         (Number)
#   layer_name        layer name                          (String)
#   layer_index       layer (0=actual, 1=plan, 2=budget, 3=forecast)
#   delta             signed integer amount; debit positive, credit negative (Number)
#   kind              "income" / "expense" / "transfer" / "budget"
#   status            "ok" / "warning" / "unknown_account" / ...
#   message           human-readable note                 (String)

# ── Column header (ordered) ──────────────────────────────────

proj_cols ← ⟨
  "source_file",
  "source_row",
  "source_id",
  "tx_id",
  "posting_id",
  "date",
  "side",
  "day_index",
  "account_key",
  "account_key_index",
  "layer_name",
  "layer_index",
  "delta",
  "kind",
  "status",
  "message"
⟩

# ── Kind inference ───────────────────────────────────────────
# Infer kind from source from/to account metadata.
# - explicit role=income on from account → income
# - explicit role=expense on to account  → expense
# - otherwise                           → transfer

InferKind ← {𝕊 ⟨fromRole, toRole, fromAcc, toAcc⟩:
  isInc ← fromRole ≡ "income"
  isExp ← toRole ≡ "expense"
  isExp ⊑ (isInc ⊑ "transfer"‿"income")‿"expense"
}

# ── Scalar validation helpers ───────────────────────────────

digits ← "0123456789"
IsDigits ← { (0 < ≠ 𝕩) ∧ ∧´ (𝕩 ∊ digits) }
IsIntegerText ← {𝕊 s:
  (0 < ≠ s) ∧ IsDigits(s)
}
FieldOrEmpty ← {𝕊 flds‿i:
  (i < ≠ flds) ? (i ⊑ flds) ; ""
}

# Date validation is owned by src_next/date.bqn so edit and report paths share
# one Gregorian YYYY-MM-DD contract.
IsValidDateText ← dt.IsValidDateText

# ── Pure BQN date-to-absolute-days (proleptic Gregorian) ────
# Returns days since year 0-01-01.
# No external date command; no external library.

DaysFromEpoch ← dt.DaysFromEpoch

# ── Day index resolution (cycle-start-based) ────────────────
# Returns day offset from cycle start (0 = cycle start date).
# Negative for dates before cycle start.
ResolveDayFromCycle ← {𝕊 date‿cycleStart:
  (DaysFromEpoch date) - DaysFromEpoch cycleStart
}

# ── Legacy ResolveDay (hardcoded base, kept for backward compat) ──
# TODO: remove after all callers migrate to ResolveDayFromCycle.
ResolveDay ← {𝕊 date:
  ResolveDayFromCycle ⟨date, "2026-01-01"⟩
}

# ── Source metadata helpers ─────────────────────────────────

MetaValue ← {𝕊 key‿def‿toks:
  pref ← key ∾ "="
  plen ← ≠ pref
  ok_len ← { plen ≤ ≠ 𝕩 } ¨ toks
  is_match ← ok_len × { pref ≡ plen ↑ 𝕩 } ¨ toks
  hits ← is_match / toks
  vals ← (plen ↓¨ hits) ∾ ⟨def⟩
  (0 < ≠ hits) ⊑ ⟨def, ⊑ vals⟩
}

TxIdFromMeta ← {𝕊 sourceId‿flds:
  metas ← 5 ↓ flds
  MetaValue ⟨"txn_id", sourceId, metas⟩
}

LayerName ← {𝕊 layerIdx: layerIdx ⊑ ⟨"actual", "plan", "budget", "forecast"⟩ }

PostingId ← {𝕊 srcFile‿rowIdx‿side:
  srcFile ∾ ":" ∾ (•Fmt rowIdx) ∾ ":" ∾ side
}

# ── Arithmetic currency proof authorization ─────────────────

allowed_proof_basis ← ⟨"legacy_compatibility", "empty_source_compatibility"⟩
IsAllowedProofBasis ← {𝕊 basis: ∨´ 0 ∾ (basis⊸≡¨ allowed_proof_basis) }
ProofState ← ({𝕩.state}⎊{""})
ProofDomain ← ({𝕩.domain}⎊{""})
ProofBasis ← ({𝕩.basis}⎊{""})
ProofMessage ← ({𝕩.message}⎊{""})

AuthorizeArithmeticCurrencyProof ← {𝕊 proof:
  state ← ProofState proof
  domain ← ProofDomain proof
  basis ← ProofBasis proof
  (state ≡ "proven") ∧ (domain ≡ "JPY") ∧ IsAllowedProofBasis basis
}

ArithmeticCurrencyAuthorizationMessage ← {𝕊 proof:
  state ← ProofState proof
  domain ← ProofDomain proof
  basis ← ProofBasis proof
  message ← ProofMessage proof
  msg ← ""
  msg ↩ (¬ IsAllowedProofBasis basis) ⊑ msg‿("unsupported arithmetic currency proof basis: " ∾ basis)
  msg ↩ (domain ≢ "JPY") ⊑ msg‿("unsupported arithmetic currency domain: " ∾ domain)
  msg ↩ (state ≢ "proven") ⊑ msg‿((0 < ≠ message) ⊑ ("arithmetic currency proof is not proven: " ∾ state)‿message)
  msg
}

RequireArithmeticCurrencyProof ← {𝕊 proof:
  ok ← AuthorizeArithmeticCurrencyProof proof
  {𝕊:
    •Out "ERROR: " ∾ ArithmeticCurrencyAuthorizationMessage proof
    •Exit 1
  }⍟(¬ok) @
  ok
}

# ── Row builder ──────────────────────────────────────────────
# Builds ledger-like projection rows from a parsed source record.
# Args: ⟨proof, srcFile, rowIdx, flds, accounts, accountKeys, cycleStart⟩
#   srcFile     - source TSV file name
#   rowIdx      - zero-based line number in source file
#   flds        - parsed TSV fields (1D array)
#   accounts     - 1D array of account names (from AccountKey table)
#   accountRoles - 1D array of explicit role= metadata values, empty if absent
#   accountKeys  - 1D array of AccountKey strings
#   cycleStart   - YYYY-MM-DD cycle start date (String)
#
# Handles:
#   - account key resolution with unknown_account detection (checks both from and to)
#   - one source record expands to a debit-side row (to account, +amount)
#     and a credit-side row (from account, -amount)
#   - day index resolution via ResolveDayFromCycle (cycle-start-based)
#   - layer assignment via SourceLayer
#   - kind inference via InferKind
#
# Note: unknown_account rows receive sentinel index = n (≠accounts).
# This sentinel must NOT be used as a cube index later —
# cube materialize should filter or reject invalid rows before indexing.

MakeRowRaw ← {𝕊 ⟨srcFile, rowIdx, flds, accounts, accountRoles, accountKeys, cycleStart⟩:
  date   ← FieldOrEmpty ⟨flds, 0⟩
  srcId  ← FieldOrEmpty ⟨flds, 1⟩
  txId   ← TxIdFromMeta ⟨srcId, flds⟩
  fromAcc ← FieldOrEmpty ⟨flds, 2⟩
  toAcc   ← FieldOrEmpty ⟨flds, 3⟩
  amountText ← FieldOrEmpty ⟨flds, 4⟩

  dateOk ← IsValidDateText date
  amountOk ← IsIntegerText amountText
  amount ← 0
  {𝕊: amount ↩ •BQN amountText }⍟amountOk @


  # Account resolution: look up both source accounts in accounts table
  fromIdx ← ⊑ accounts ⊐ ⟨fromAcc⟩
  toIdx   ← ⊑ accounts ⊐ ⟨toAcc⟩
  n         ← ≠ accounts

  fromKnown ← fromIdx < n
  toKnown   ← toIdx < n
  known     ← fromKnown ∧ toKnown

  # Determine status before cube materialization. Invalid scalar fields win
  # over account errors because they would otherwise crash date/amount parsing.
  # sentinel: n (≠accounts) — marks unknown_account rows
  # WARNING: do NOT use sentinel as a real cube index.
  # Cube materialize must filter rows where account_key_index = n or status ≠ ok.
  status ← "ok"
  status ↩ (¬known) ⊑ status‿"unknown_account"
  status ↩ (¬amountOk) ⊑ status‿"invalid_amount"
  status ↩ (¬dateOk) ⊑ status‿"invalid_date"
  fromAkOut ← fromKnown ⊑ n‿fromIdx
  toAkOut   ← toKnown ⊑ n‿toIdx

  # Build diagnostic message for non-ok statuses.
  unknownMsg ← ""
  unknownMsg ↩ ((¬fromKnown) ∧ (¬toKnown)) ⊑ unknownMsg‿("unknown from account: "∾fromAcc∾"; unknown to account: "∾toAcc)
  unknownMsg ↩ ((¬fromKnown) ∧ toKnown) ⊑ unknownMsg‿("unknown from account: "∾fromAcc)
  unknownMsg ↩ (fromKnown ∧ (¬toKnown)) ⊑ unknownMsg‿("unknown to account: "∾toAcc)
  msg ← ""
  msg ↩ (status ≡ "unknown_account") ⊑ msg‿unknownMsg
  msg ↩ (status ≡ "invalid_amount") ⊑ msg‿("invalid amount: "∾amountText)
  msg ↩ (status ≡ "invalid_date") ⊑ msg‿("invalid date: "∾date)

  roleWithSentinel ← accountRoles ∾ ⟨""⟩
  keyWithSentinel ← accountKeys ∾ ⟨""⟩
  fromRole ← fromAkOut ⊑ roleWithSentinel
  toRole ← toAkOut ⊑ roleWithSentinel

  day ← 0
  cycleStartOk ← IsValidDateText cycleStart
  {𝕊: day ↩ ResolveDayFromCycle ⟨date, cycleStart⟩ }⍟(dateOk ∧ cycleStartOk) @

  layer ← SourceLayer srcFile
  layerName ← LayerName layer
  kind  ← InferKind ⟨fromRole, toRole, fromAcc, toAcc⟩

  MakeSideRow ← {𝕊 side‿akIdx‿sideDelta:
    {
      source_file       ⇐ srcFile,
      source_row        ⇐ rowIdx,
      source_id         ⇐ srcId,
      tx_id             ⇐ txId,
      posting_id        ⇐ PostingId ⟨srcFile, rowIdx, side⟩,
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

MakeRow ← {𝕊 ⟨proof, srcFile, rowIdx, flds, accounts, accountRoles, accountKeys, cycleStart⟩:
  RequireArithmeticCurrencyProof proof
  MakeRowRaw ⟨srcFile, rowIdx, flds, accounts, accountRoles, accountKeys, cycleStart⟩
}

MakeRowsAuthorized ← {𝕊 proof‿args:
  RequireArithmeticCurrencyProof proof
  ∾ (MakeRowRaw ¨ args)
}

# ── Balance validation by source_id ──────────────────────────

Sum0 ← { 0 < ≠𝕩 ? +´𝕩 ; 0 }

BalanceBySourceOk ← {𝕊 rows:
  ok ← 1
  {𝕊:
    ids ← {𝕩.source_id}¨ rows
    deltas ← {𝕩.delta}¨ rows
    SumForId ← {𝕊 id: Sum0 ((id⊸≡¨ ids) / deltas)}
    sums ← SumForId¨ ids
    ok ↩ ∧´ sums = 0
  }⍟(0 < ≠ rows) @
  ok
}

FormatBalanceCheck ← {𝕊 rows:
  ok ← BalanceBySourceOk rows
  "projection_balance_by_source: " ∾ (ok ⊑ "FAIL"‿"ok")
}

# ── Format table ─────────────────────────────────────────────

FormatProjTable ← {𝕊 rows:
  FmtOne ← {𝕊 xs: ∾ (•Fmt¨xs) ∾¨ (@+9)}
  hdr ← FmtOne proj_cols

  ToRow ← {𝕊 r:
    ⟨ r.source_file, •Fmt r.source_row, r.source_id, r.tx_id, r.posting_id, r.date, r.side,
      •Fmt r.day_index, r.account_key, •Fmt r.account_key_index, r.layer_name, •Fmt r.layer_index,
      •Fmt r.delta, r.kind, r.status, r.message ⟩
  }

  data ← FmtOne¨ (ToRow¨ rows)
  hdr ∾ (@+10) ∾ ∾ (data ∾¨ (@+10))
}

# ── Export ───────────────────────────────────────────────────
{
  layer_actual    ⇐ layer_actual,
  layer_plan      ⇐ layer_plan,
  layer_budget    ⇐ layer_budget,
  layer_forecast  ⇐ layer_forecast,
  SourceLayer     ⇐ SourceLayer,
  proj_cols       ⇐ proj_cols,
  InferKind       ⇐ InferKind,
  MetaValue             ⇐ MetaValue,
  TxIdFromMeta          ⇐ TxIdFromMeta,
  LayerName             ⇐ LayerName,
  PostingId             ⇐ PostingId,
  IsDigits             ⇐ IsDigits,
  IsIntegerText        ⇐ IsIntegerText,
  IsValidDateText      ⇐ IsValidDateText,
  FieldOrEmpty         ⇐ FieldOrEmpty,
  DaysFromEpoch         ⇐ DaysFromEpoch,
  ResolveDay            ⇐ ResolveDay,
  ResolveDayFromCycle   ⇐ ResolveDayFromCycle,
  AuthorizeArithmeticCurrencyProof ⇐ AuthorizeArithmeticCurrencyProof,
  ArithmeticCurrencyAuthorizationMessage ⇐ ArithmeticCurrencyAuthorizationMessage,
  RequireArithmeticCurrencyProof ⇐ RequireArithmeticCurrencyProof,
  BalanceBySourceOk     ⇐ BalanceBySourceOk,
  FormatBalanceCheck    ⇐ FormatBalanceCheck,
  FormatProjTable       ⇐ FormatProjTable
}
