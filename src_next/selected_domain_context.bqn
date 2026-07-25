# selected_domain_context.bqn
# Pure selected-currency composition plus a small read-only source adapter.
#
# One explicitly selected registry-supported currency is projected at a time.
# Currency proof remains attached until every selected row has been normalized
# to one context-local scale. No Currency axis, FX, valuation, or cross-domain
# total is introduced.
#
# BuildFromPrepared is deliberately arranged as a flat semantic stage sequence:
# policy -> Actual admission -> Actual currency proof -> non-Actual preparation
# -> selected scale -> exact normalization -> period views.

loader ← •Import "loader.bqn"
ak ← •Import "account_key.bqn"
cycle ← •Import "cycle.bqn"
actual_source ← •Import "actual_source.bqn"
setup ← •Import "currency_setup.bqn"
arith ← •Import "currency_arithmetic.bqn"
decimal ← •Import "exact_decimal.bqn"
admission ← •Import "journal_complete_source_admission.bqn"
carrier ← •Import "journal_currency_proof_carrier_stage2a.bqn"
context ← •Import "context.bqn"
proj ← •Import "projection.bqn"

empty ← ⟨⟩

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error", stage⇐"selected_domain_context", code⇐codeText, message⇐messageText}
}
Failure ← {𝕊 currency‿code‿message‿diagnostics:
  {
    state⇐"error", selected_currency⇐currency, calculation_scale⇐⟨⟩,
    posting_rows⇐empty, actual_transactions⇐empty, cube⇐{cube⇐empty}, tbds⇐empty,
    diagnostics⇐diagnostics ∾ ⟨Diagnostic ⟨code, message⟩⟩, message⇐message
  }
}

LookupAccount ← {𝕊 accountName‿resolved:
  mask ← accountName⊸≡¨ resolved.accounts
  count ← +´ mask
  index ← ≠ resolved.accounts
  {𝕊: index ↩ ⊑ mask / ↕ ≠ mask}⍟(1 = count) @
  {count⇐count, index⇐index}
}

ValidateNonActualEvidence ← {𝕊 evidence‿resolved:
  diagnostics ← empty
  {𝕊 row:
    {𝕊:
      diagnostics ∾↩ ⟨Diagnostic ⟨"nonactual_evidence_invalid", row.source_file ∾ " row " ∾ (•Fmt row.source_row) ∾ ": " ∾ row.message⟩⟩
    }⍟(row.state ≢ "ok") @
    {𝕊:
      from ← proj.FieldOrEmpty ⟨row.flds, 2⟩
      to ← proj.FieldOrEmpty ⟨row.flds, 3⟩
      {𝕊 accountName:
        found ← LookupAccount ⟨accountName, resolved⟩
        diagnostics ∾↩ (found.count ≠ 1) / ⟨Diagnostic ⟨"nonactual_account_unresolved", row.source_file ∾ " row " ∾ (•Fmt row.source_row) ∾ ": account must resolve exactly once"⟩⟩
        {𝕊:
          accountCurrency ← found.index ⊑ resolved.currencies
          diagnostics ∾↩ (accountCurrency ≢ row.currency) / ⟨Diagnostic ⟨"nonactual_account_currency_mismatch", row.source_file ∾ " row " ∾ (•Fmt row.source_row) ∾ ": account currency differs from source currency"⟩⟩
        }⍟(found.count = 1) @
      }¨ ⟨from, to⟩
    }⍟(row.state ≡ "ok") @
  }¨ evidence
  diagnostics
}

NormalizeCoefficient ← {𝕊 coefficient‿sourceScale‿targetScale:
  valid ← (0 ≤ sourceScale) ∧ (sourceScale ≤ targetScale)
  value ← 0
  {𝕊:
    zeros ← targetScale - sourceScale
    parsed ← decimal.Parse ((•Fmt | coefficient) ∾ zeros ⥊ '0')
    valid ↩ valid ∧ parsed.state ≡ "ok"
    {𝕊: value ↩ (1 - 2 × coefficient < 0) × parsed.coefficient}⍟(parsed.state ≡ "ok") @
  }⍟valid @
  {valid⇐valid, value⇐value}
}

ProjectionRow ← {𝕊 row‿delta‿domain‿scale:
  {
    source_file⇐row.source_file,
    source_row⇐row.source_row,
    source_id⇐row.source_id,
    tx_id⇐row.tx_id,
    posting_id⇐row.posting_id,
    date⇐row.date,
    day_index⇐row.day_index,
    account_key⇐row.account_key,
    account_key_index⇐row.account_key_index,
    layer_name⇐row.layer_name,
    layer_index⇐row.layer_index,
    side⇐row.side,
    delta⇐delta,
    kind⇐row.kind,
    status⇐"ok",
    message⇐"",
    domain⇐domain,
    calculation_scale⇐scale,
    normalized_coefficient⇐delta
  }
}

NonActualFailure ← {𝕊 codeText‿messageText‿diagnostics:
  {state⇐"error", code⇐codeText, rows⇐empty, scale⇐0, diagnostics⇐diagnostics, message⇐messageText}
}
NonActualSuccess ← {𝕊 rows‿scale:
  {state⇐"ok", code⇐"", rows⇐rows, scale⇐scale, diagnostics⇐empty, message⇐""}
}

# Prepare plan/budget rows for one selected arithmetic domain. This stage owns
# source-evidence validation, selected-domain arithmetic proof, and the checked
# Posting IR projection. It does not choose the combined Actual/non-Actual scale.
PrepareNonActualRows ← {𝕊 selectedCurrency‿nonactualSnapshot‿resolved‿cycleStart:
  evidence ← context.BuildRowEvidenceFromSnapshot nonactualSnapshot
  evidenceDiagnostics ← ValidateNonActualEvidence ⟨evidence, resolved⟩
  result ← NonActualFailure ⟨"nonactual_proof_failed", "plan or budget currency proof failed", evidenceDiagnostics⟩
  stageOk ← 0 = ≠ evidenceDiagnostics

  selectedEvidence ← empty
  {𝕊:
    selectedEvidence ↩ (selectedCurrency⊸≡¨ {𝕩.currency}¨ evidence) / evidence
    result ↩ NonActualSuccess ⟨empty, 0⟩
  }⍟stageOk @

  hasSelectedEvidence ← stageOk ∧ 0 < ≠ selectedEvidence
  arithmetic ← {state⇐"not_run", amount_scale⇐0, message⇐""}
  {𝕊:
    arithmetic ↩ arith.Build selectedEvidence
    {𝕊:
      result ↩ NonActualFailure ⟨"nonactual_projection_failed", arithmetic.message, empty⟩
    }⍟(arithmetic.state ≢ "ok") @
  }⍟hasSelectedEvidence @
  stageOk ∧↩ (¬hasSelectedEvidence) ∨ arithmetic.state ≡ "ok"

  checked ← {state⇐"not_run", posting_rows⇐empty, diagnostics⇐empty}
  {𝕊:
    checked ↩ context.BuildCheckedPostingProjectionFromPreparedForTest ⟨selectedEvidence, arithmetic, resolved, cycleStart⟩
    {𝕊:
      result ↩ NonActualSuccess ⟨checked.posting_rows, arithmetic.amount_scale⟩
    }⍟(checked.state ≡ "ok") @
    {𝕊:
      result ↩ NonActualFailure ⟨"nonactual_projection_failed", (⊑ checked.diagnostics).message, empty⟩
    }⍟(checked.state ≢ "ok") @
  }⍟(hasSelectedEvidence ∧ stageOk) @

  result
}

# Normalize the two already-admitted row sets to the selected context scale.
# Invalid normalization may build a partial local candidate, but callers receive
# no rows unless the complete stage succeeds.
NormalizeSelectedRows ← {𝕊 actualRows‿nonactualRows‿nonactualScale‿contextScale‿selectedCurrency:
  rows ← empty
  valid ← 1

  AppendNormalized ← {𝕊 row‿sourceScale‿coefficient:
    normalized ← NormalizeCoefficient ⟨coefficient, sourceScale, contextScale⟩
    valid ∧↩ normalized.valid
    {𝕊:
      rows ∾↩ ⟨ProjectionRow ⟨row, normalized.value, selectedCurrency, contextScale⟩⟩
    }⍟normalized.valid @
  }

  {𝕊 row: AppendNormalized ⟨row, row.calculation_scale, row.normalized_coefficient⟩}¨ actualRows
  {𝕊 row: AppendNormalized ⟨row, nonactualScale, row.delta⟩}¨ nonactualRows

  {state⇐valid ⊑ "error"‿"ok", rows⇐rows}
}

BuildFromPrepared ← {𝕊 selectedCurrency‿raw‿resolved‿cy‿sourceFile‿nonactualSnapshot:
  policy ← setup.Policy selectedCurrency
  result ← Failure ⟨selectedCurrency, "selected_currency_unsupported", "selected currency must be admitted by registry", empty⟩
  stageOk ← policy.state ≡ "ok"

  admitted ← {state⇐"not_run", transactions⇐empty, diagnostics⇐empty}
  {𝕊:
    admitted ↩ admission.Admit ⟨raw, resolved⟩
    {𝕊:
      result ↩ Failure ⟨selectedCurrency, "actual_admission_failed", "complete Journal admission failed", admitted.diagnostics⟩
    }⍟(admitted.state ≢ "ok") @
  }⍟stageOk @
  stageOk ∧↩ admitted.state ≡ "ok"

  carried ← {state⇐"not_run", currency_proof_rows⇐empty, diagnostics⇐empty}
  {𝕊:
    carried ↩ carrier.BuildForSource ⟨admitted.transactions, resolved, cy.start, sourceFile⟩
    {𝕊:
      result ↩ Failure ⟨selectedCurrency, "actual_currency_proof_failed", "Stage 2A currency-proof carriage failed", carried.diagnostics⟩
    }⍟(carried.state ≢ "ok") @
  }⍟stageOk @
  stageOk ∧↩ carried.state ≡ "ok"

  preparedNonActual ← {state⇐"not_run", code⇐"", rows⇐empty, scale⇐0, diagnostics⇐empty, message⇐""}
  {𝕊:
    preparedNonActual ↩ PrepareNonActualRows ⟨selectedCurrency, nonactualSnapshot, resolved, cy.start⟩
    {𝕊:
      result ↩ Failure ⟨selectedCurrency, preparedNonActual.code, preparedNonActual.message, preparedNonActual.diagnostics⟩
    }⍟(preparedNonActual.state ≢ "ok") @
  }⍟stageOk @
  stageOk ∧↩ preparedNonActual.state ≡ "ok"

  actualRows ← empty
  actualTransactions ← empty
  contextScale ← 0
  scaleOk ← 0
  {𝕊:
    actualRows ↩ (selectedCurrency⊸≡¨ {𝕩.domain}¨ carried.currency_proof_rows) / carried.currency_proof_rows
    actualTransactions ↩ (selectedCurrency⊸≡¨ {𝕩.domain}¨ admitted.transactions) / admitted.transactions
    scales ← {𝕩.calculation_scale}¨ actualRows
    contextScale ↩ ⌈´ 0 ∾ scales ∾ ⟨preparedNonActual.scale⟩
    scaleOk ↩ (policy.max_fraction_digits < 0) ∨ contextScale ≤ policy.max_fraction_digits
    {𝕊:
      result ↩ Failure ⟨selectedCurrency, "selected_scale_invalid", "selected context scale exceeds currency policy", empty⟩
    }⍟(¬scaleOk) @
  }⍟stageOk @
  stageOk ∧↩ scaleOk

  normalized ← {state⇐"not_run", rows⇐empty}
  {𝕊:
    normalized ↩ NormalizeSelectedRows ⟨actualRows, preparedNonActual.rows, preparedNonActual.scale, contextScale, selectedCurrency⟩
    {𝕊:
      result ↩ Failure ⟨selectedCurrency, "selected_normalization_failed", "selected rows could not normalize exactly", empty⟩
    }⍟(normalized.state ≢ "ok") @
  }⍟stageOk @
  stageOk ∧↩ normalized.state ≡ "ok"

  {𝕊:
    view ← context.BuildPeriodView ⟨normalized.rows, resolved, cy⟩
    result ↩ {
      state⇐"ok", selected_currency⇐selectedCurrency, calculation_scale⇐contextScale,
      posting_rows⇐normalized.rows, actual_transactions⇐actualTransactions,
      cube⇐view.cube, tbds⇐view.tbds, resolved⇐resolved, cy⇐cy,
      actual_source_file⇐sourceFile, diagnostics⇐empty, message⇐""
    }
  }⍟stageOk @

  result
}

Build ← {𝕊 base‿selectedCurrency:
  resolved ← ak.Resolve loader.ReadLines (base ∾ "/accounts.tsv")
  sourceFile ← actual_source.ResolveRelativePath base
  raw ← loader.ReadRaw (base ∾ "/" ∾ sourceFile)
  preliminary ← admission.Admit ⟨raw, resolved⟩
  result ← Failure ⟨selectedCurrency, "actual_admission_failed", "complete Journal admission failed", preliminary.diagnostics⟩
  {𝕊:
    # Preserve the existing latest-Actual observation when Actual exists. A
    # declaration-only Journal delegates to the common cycle resolver, which
    # supplies its normal no-Actual rule without inspecting the currency.
    cy ← cycle.ReadCycle base
    {𝕊:
      asOf ← ¯1 ⊑ ∧ {𝕩.date}¨ preliminary.transactions
      cy ↩ cycle.ReadCycle ⟨base, asOf⟩
    }⍟(0 < ≠ preliminary.transactions) @
    snapshot ← context.LoadNonActualPostingSourceSnapshot base
    result ↩ BuildFromPrepared ⟨selectedCurrency, raw, resolved, cy, sourceFile, snapshot⟩
  }⍟(preliminary.state ≡ "ok") @
  result
}

{Build⇐Build, BuildFromPrepared⇐BuildFromPrepared, ValidateNonActualEvidence⇐ValidateNonActualEvidence, NormalizeCoefficient⇐NormalizeCoefficient}