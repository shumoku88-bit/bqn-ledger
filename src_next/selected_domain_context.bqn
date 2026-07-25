# selected_domain_context.bqn
# Pure selected-currency composition plus a small read-only source adapter.
#
# One explicitly selected registry-supported currency is projected at a time.
# Currency proof remains attached until every selected row has been normalized
# to one context-local scale. No Currency axis, FX, valuation, or cross-domain
# total is introduced.

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

BuildFromPrepared ← {𝕊 selectedCurrency‿raw‿resolved‿cy‿sourceFile‿nonactualSnapshot:
  policy ← setup.Policy selectedCurrency
  result ← Failure ⟨selectedCurrency, "selected_currency_unsupported", "selected currency must be admitted by registry", empty⟩
  {𝕊:
    admitted ← admission.Admit ⟨raw, resolved⟩
    result ↩ Failure ⟨selectedCurrency, "actual_admission_failed", "complete Journal admission failed", admitted.diagnostics⟩
    {𝕊:
      carried ← carrier.BuildForSource ⟨admitted.transactions, resolved, cy.start, sourceFile⟩
      result ↩ Failure ⟨selectedCurrency, "actual_currency_proof_failed", "Stage 2A currency-proof carriage failed", carried.diagnostics⟩
      {𝕊:
        evidence ← context.BuildRowEvidenceFromSnapshot nonactualSnapshot
        evidenceDiagnostics ← ValidateNonActualEvidence ⟨evidence, resolved⟩
        result ↩ Failure ⟨selectedCurrency, "nonactual_proof_failed", "plan or budget currency proof failed", evidenceDiagnostics⟩
        {𝕊:
          selectedEvidence ← (selectedCurrency⊸≡¨ {𝕩.currency}¨ evidence) / evidence
          nonactualScale ← 0
          nonactualRows ← empty
          nonactualOk ← 1
          nonactualMessage ← ""
          {𝕊:
            arithmetic ← arith.Build selectedEvidence
            nonactualOk ↩ arithmetic.state ≡ "ok"
            nonactualMessage ↩ arithmetic.message
            {𝕊:
              checked ← context.BuildCheckedPostingProjectionFromPreparedForTest ⟨selectedEvidence, arithmetic, resolved, cy.start⟩
              nonactualOk ↩ checked.state ≡ "ok"
              {𝕊: nonactualRows ↩ checked.posting_rows ⋄ nonactualScale ↩ arithmetic.amount_scale}⍟nonactualOk @
              {𝕊: nonactualMessage ↩ (⊑ checked.diagnostics).message}⍟(¬nonactualOk) @
            }⍟nonactualOk @
          }⍟(0 < ≠ selectedEvidence) @
          result ↩ Failure ⟨selectedCurrency, "nonactual_projection_failed", nonactualMessage, empty⟩
          {𝕊:
            actualRows ← (selectedCurrency⊸≡¨ {𝕩.domain}¨ carried.currency_proof_rows) / carried.currency_proof_rows
            actualTransactions ← (selectedCurrency⊸≡¨ {𝕩.domain}¨ admitted.transactions) / admitted.transactions
            scales ← {𝕩.calculation_scale}¨ actualRows
            contextScale ← ⌈´ 0 ∾ scales ∾ ⟨nonactualScale⟩
            scaleOk ← (policy.max_fraction_digits < 0) ∨ contextScale ≤ policy.max_fraction_digits
            result ↩ Failure ⟨selectedCurrency, "selected_scale_invalid", "selected context scale exceeds currency policy", empty⟩
            {𝕊:
              rows ← empty
              normalizationOk ← 1
              {𝕊 row:
                normalized ← NormalizeCoefficient ⟨row.normalized_coefficient, row.calculation_scale, contextScale⟩
                normalizationOk ∧↩ normalized.valid
                {𝕊: rows ∾↩ ⟨ProjectionRow ⟨row, normalized.value, selectedCurrency, contextScale⟩⟩}⍟normalized.valid @
              }¨ actualRows
              {𝕊 row:
                normalized ← NormalizeCoefficient ⟨row.delta, nonactualScale, contextScale⟩
                normalizationOk ∧↩ normalized.valid
                {𝕊: rows ∾↩ ⟨ProjectionRow ⟨row, normalized.value, selectedCurrency, contextScale⟩⟩}⍟normalized.valid @
              }¨ nonactualRows
              result ↩ Failure ⟨selectedCurrency, "selected_normalization_failed", "selected rows could not normalize exactly", empty⟩
              {𝕊:
                view ← context.BuildPeriodView ⟨rows, resolved, cy⟩
                result ↩ {
                  state⇐"ok", selected_currency⇐selectedCurrency, calculation_scale⇐contextScale,
                  posting_rows⇐rows, actual_transactions⇐actualTransactions,
                  cube⇐view.cube, tbds⇐view.tbds, resolved⇐resolved, cy⇐cy,
                  actual_source_file⇐sourceFile, diagnostics⇐empty, message⇐""
                }
              }⍟normalizationOk @
            }⍟scaleOk @
          }⍟nonactualOk @
        }⍟(0 = ≠ evidenceDiagnostics) @
      }⍟(carried.state ≡ "ok") @
    }⍟(admitted.state ≡ "ok") @
  }⍟(policy.state ≡ "ok") @
  result
}

Build ← {𝕊 base‿selectedCurrency:
  resolved ← ak.Resolve loader.ReadLines (base ∾ "/accounts.tsv")
  sourceFile ← actual_source.ResolveRelativePath base
  raw ← loader.ReadRaw (base ∾ "/" ∾ sourceFile)
  preliminary ← admission.Admit ⟨raw, resolved⟩
  result ← Failure ⟨selectedCurrency, "actual_admission_failed", "complete Journal admission failed", preliminary.diagnostics⟩
  {𝕊:
    asOf ← ¯1 ⊑ ∧ {𝕩.date}¨ preliminary.transactions
    cy ← cycle.ReadCycle ⟨base, asOf⟩
    snapshot ← context.LoadNonActualPostingSourceSnapshot base
    result ↩ BuildFromPrepared ⟨selectedCurrency, raw, resolved, cy, sourceFile, snapshot⟩
  }⍟(preliminary.state ≡ "ok") @
  result
}

{Build⇐Build, BuildFromPrepared⇐BuildFromPrepared, ValidateNonActualEvidence⇐ValidateNonActualEvidence, NormalizeCoefficient⇐NormalizeCoefficient}
