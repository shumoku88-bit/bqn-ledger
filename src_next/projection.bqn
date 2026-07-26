# projection.bqn
# Shared Posting IR construction vocabulary for the non-Actual TSV route,
# plus current Layer, day-coordinate, and arithmetic-proof compatibility seams.
#
# Current contracts:
#   - docs/POSTING_IR_CONTRACT.md
#   - docs/CANONICAL_DAILY_CUBE.md
#   - docs/PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md
#
# This module does not materialize Cube/TBDS, render diagnostic tables, or
# produce report sections. Developer inspection presentation lives in main.bqn.

dt ← •Import "date.bqn"
setup ← •Import "currency_setup.bqn"


# ── Layer constants (docs/CANONICAL_DAILY_CUBE.md) ────────────

layer_actual   ← 0
layer_plan     ← 1
layer_budget   ← 2
layer_forecast ← 3

# ── Layer mapping by source file ─────────────────────────────

source_layer_files ← ⟨"actual.journal", "plan.tsv", "budget_alloc.tsv"⟩
source_layer_vals  ← ⟨layer_actual, layer_plan, layer_budget⟩

SourceLayer ← {𝕊 src:
  i ← source_layer_files ⊐ ⟨src⟩
  i ⊑ source_layer_vals
}

# ── Current Posting IR conceptual shape ──────────────────────
# See docs/POSTING_IR_CONTRACT.md for the canonical field contract.
#   source_file       source file identity                    (String)
#   source_row        row / transaction ordinal               (Number)
#   source_id         source event identity                    (String)
#   tx_id             transaction group id                     (String)
#   posting_id        stable posting row id                    (String)
#   date              source date YYYY-MM-DD                   (String)
#   side              "debit" / "credit"                     (String)
#   day_index         day offset from supplied cycle start     (Number)
#   account_key       canonical AccountKey string              (String)
#   account_key_index index into AccountKey table              (Number)
#   layer_name        layer name                               (String)
#   layer_index       layer (actual / plan / budget / forecast)
#   delta             signed exact amount                      (Number)
#   kind              transaction-level classification         (String)
#   status            row status                               (String)
#   message           diagnostic note                          (String)

# ── Kind inference ───────────────────────────────────────────
# Infer transaction kind from source from/to account metadata.
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
# one Gregorian YYYY-MM-DD contract. This alias remains for compatibility and
# will be reassessed separately from the diagnostic presentation cleanup.
IsValidDateText ← dt.IsValidDateText

# Legacy absolute day coordinate forwarded from date.bqn. Differences are used
# by the current Posting IR day-index seam.
DaysFromEpoch ← dt.DaysFromEpoch

# ── Day index resolution (cycle-start-based) ────────────────
# Returns day offset from cycle start (0 = cycle start date).
# Negative for dates before cycle start.
ResolveDayFromCycle ← {𝕊 date‿cycleStart:
  (DaysFromEpoch date) - DaysFromEpoch cycleStart
}

# ── Legacy ResolveDay (hardcoded base, kept for compatibility) ──
# No current repository caller was observed in the 2026-07-26 ownership audit.
# Removal requires its own external-compatibility characterization slice.
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

allowed_proof_basis ← ⟨"legacy_compatibility", "empty_source_compatibility", "resolved_single_currency"⟩
IsAllowedProofBasis ← {𝕊 basis: ∨´ 0 ∾ (basis⊸≡¨ allowed_proof_basis) }
IsAllowedProofDomainBasis ← {𝕊 domain‿basis:
  (domain ≡ "JPY") ∨ ((setup.IsSupportedCurrency domain) ∧ basis ≡ "resolved_single_currency")
}
ProofState ← ({𝕩.state}⎊{""})
ProofDomain ← ({𝕩.domain}⎊{""})
ProofBasis ← ({𝕩.basis}⎊{""})
ProofScale ← ({𝕩.amount_scale}⎊{⟨⟩})
ProofMessage ← ({𝕩.message}⎊{""})

IsNonNegativeInteger ← { (•Type 𝕩 ≡ 1) ∧ (0 = =𝕩) ? (𝕩 ≥ 0) ∧ (𝕩 ≡ ⌊𝕩) ; 0 }

AuthorizeArithmeticCurrencyProof ← {𝕊 proof:
  state ← ProofState proof
  domain ← ProofDomain proof
  basis ← ProofBasis proof
  scale ← ProofScale proof

  ok ← (state ≡ "proven") ∧ (IsAllowedProofDomainBasis ⟨domain, basis⟩) ∧ (IsAllowedProofBasis basis) ∧ (IsNonNegativeInteger scale)
  ok ↩ ok ∧ (basis ≢ "empty_source_compatibility") ∨ scale ≡ 0
  ok
}

ArithmeticCurrencyAuthorizationMessage ← {𝕊 proof:
  state ← ProofState proof
  domain ← ProofDomain proof
  basis ← ProofBasis proof
  scale ← ProofScale proof
  message ← ProofMessage proof
  msg ← ""

  is_valid_scale ← IsNonNegativeInteger scale

  msg ↩ (¬ is_valid_scale) ⊑ msg‿"invalid amount_scale in proof"
  {𝕊:
    msg ↩ (scale ≢ 0) ⊑ msg‿"empty_source_compatibility requires amount_scale = 0"
  } ⍟ (basis ≡ "empty_source_compatibility") @
  msg ↩ (¬ IsAllowedProofBasis basis) ⊑ msg‿("unsupported arithmetic currency proof basis: " ∾ basis)
  is_decimal_currency ← (domain ≢ "JPY") ∧ (setup.IsSupportedCurrency domain)
  msg ↩ ((IsAllowedProofBasis basis) ∧ is_decimal_currency ∧ basis ≢ "resolved_single_currency") ⊑ msg‿(domain ∾ " requires resolved_single_currency proof basis")
  msg ↩ (¬ setup.IsSupportedCurrency domain) ⊑ msg‿("unsupported arithmetic currency domain: " ∾ domain)
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

# ── Export ───────────────────────────────────────────────────
{
  layer_actual    ⇐ layer_actual,
  layer_plan      ⇐ layer_plan,
  layer_budget    ⇐ layer_budget,
  layer_forecast  ⇐ layer_forecast,
  SourceLayer     ⇐ SourceLayer,
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
  RequireArithmeticCurrencyProof ⇐ RequireArithmeticCurrencyProof
}