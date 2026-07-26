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
# produce report sections. Developer inspection presentation lives in
# developer_inspection.bqn.

dt ← •Import "date.bqn"
layer ← •Import "layer.bqn"
proof ← •Import "arithmetic_currency_proof.bqn"


# ── Layer compatibility delegates ─────────────────────────────

layer_actual   ← layer.layer_actual
layer_plan     ← layer.layer_plan
layer_budget   ← layer.layer_budget
layer_forecast ← layer.layer_forecast
LayerName      ← layer.LayerName

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

# ── Scalar field helper ──────────────────────────────────────

FieldOrEmpty ← {𝕊 flds‿i:
  (i < ≠ flds) ? (i ⊑ flds) ; ""
}

# ── Day index resolution (cycle-start-based) ────────────────
# Returns day offset from cycle start (0 = cycle start date).
# Negative for dates before cycle start.
ResolveDayFromCycle ← {𝕊 date‿cycleStart:
  (dt.DaysFromEpoch date) - dt.DaysFromEpoch cycleStart
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

PostingId ← {𝕊 srcFile‿rowIdx‿side:
  srcFile ∾ ":" ∾ (•Fmt rowIdx) ∾ ":" ∾ side
}

# ── Arithmetic currency proof compatibility delegates ───────

AuthorizeArithmeticCurrencyProof ← proof.AuthorizeArithmeticCurrencyProof
ArithmeticCurrencyAuthorizationMessage ← proof.ArithmeticCurrencyAuthorizationMessage

# ── Export ───────────────────────────────────────────────────
{
  layer_actual    ⇐ layer_actual,
  layer_plan      ⇐ layer_plan,
  layer_budget    ⇐ layer_budget,
  layer_forecast  ⇐ layer_forecast,
  SourceLayer     ⇐ SourceLayer,
  InferKind       ⇐ InferKind,
  TxIdFromMeta          ⇐ TxIdFromMeta,
  LayerName             ⇐ LayerName,
  PostingId             ⇐ PostingId,
  FieldOrEmpty         ⇐ FieldOrEmpty,
  ResolveDayFromCycle   ⇐ ResolveDayFromCycle,
  AuthorizeArithmeticCurrencyProof ⇐ AuthorizeArithmeticCurrencyProof,
  ArithmeticCurrencyAuthorizationMessage ⇐ ArithmeticCurrencyAuthorizationMessage
}
