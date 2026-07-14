# currency_selection.bqn
# Pure checked selected-currency projection seam for mixed JPY / ILS snapshots.
#
# Contract:
#   - build row evidence exactly once from the supplied shared snapshot
#   - accept one explicit selected currency (JPY or ILS)
#   - fail closed on invalid row evidence or row/account currency mismatch
#   - filter evidence before reusing the existing single-currency arithmetic path
#   - never aggregate, convert, value, or mutate source data

ctx ← •Import "context.bqn"
arith ← •Import "currency_arithmetic.bqn"
proj ← •Import "projection.bqn"
setup ← •Import "currency_setup.bqn"

empty ← ⟨⟩

IsSupportedCurrency ← {𝕊 currency:
  setup.IsSupportedCurrency currency
}

MakeDiagnostic ← {𝕊 code‿message:
  {
    severity ⇐ "error",
    stage ⇐ "currency_selection",
    code ⇐ code,
    message ⇐ message
  }
}

Failure ← {𝕊 selected‿evidence‿code‿message:
  arithmeticEvidence ← {
    state ⇐ "error",
    domain ⇐ empty,
    amount_scale ⇐ empty,
    normalized_coefficients ⇐ empty,
    message ⇐ message
  }
  proof ← {
    state ⇐ "unsupported",
    domain ⇐ "",
    basis ⇐ "",
    amount_scale ⇐ empty,
    message ⇐ message
  }
  {
    state ⇐ "error",
    selected_currency ⇐ selected,
    row_evidence ⇐ evidence,
    arithmetic_evidence ⇐ arithmeticEvidence,
    arithmetic_currency_proof ⇐ proof,
    posting_rows ⇐ empty,
    diagnostics ⇐ ⟨MakeDiagnostic ⟨code, message⟩⟩
  }
}

WrapChecked ← {𝕊 selected‿checked:
  {
    state ⇐ checked.state,
    selected_currency ⇐ selected,
    row_evidence ⇐ checked.row_evidence,
    arithmetic_evidence ⇐ checked.arithmetic_evidence,
    arithmetic_currency_proof ⇐ checked.arithmetic_currency_proof,
    posting_rows ⇐ checked.posting_rows,
    diagnostics ⇐ checked.diagnostics
  }
}

CheckAccountCurrency ← {𝕊 row‿resolved:
  accounts ← resolved.accounts
  currencies ← resolved.currencies
  n ← ≠ accounts

  fromAccount ← proj.FieldOrEmpty ⟨row.flds, 2⟩
  toAccount ← proj.FieldOrEmpty ⟨row.flds, 3⟩
  fromIdx ← ⊑ accounts ⊐ ⟨fromAccount⟩
  toIdx ← ⊑ accounts ⊐ ⟨toAccount⟩
  fromKnown ← fromIdx < n
  toKnown ← toIdx < n

  currencyWithSentinel ← currencies ∾ ⟨""⟩
  fromCurrency ← fromIdx ⊑ currencyWithSentinel
  toCurrency ← toIdx ⊑ currencyWithSentinel
  fromMismatch ← fromKnown ∧ fromCurrency ≢ row.currency
  toMismatch ← toKnown ∧ toCurrency ≢ row.currency

  prefix ← row.source_file ∾ " row " ∾ (•Fmt row.source_row) ∾ ": "
  message ← fromMismatch ⊑ ""‿(prefix ∾ "from account currency mismatch: " ∾ fromAccount ∾ " is " ∾ fromCurrency ∾ ", row is " ∾ row.currency)
  message ↩ ((¬fromMismatch) ∧ toMismatch) ⊑ message‿(prefix ∾ "to account currency mismatch: " ∾ toAccount ∾ " is " ∾ toCurrency ∾ ", row is " ∾ row.currency)

  {
    state ⇐ (fromMismatch ∨ toMismatch) ⊑ "ok"‿"error",
    message ⇐ message
  }
}

Build ← {𝕊 snapshot‿resolved‿cycleStart‿selectedCurrency:
  # The exact supplied snapshot is interpreted once. Every later operation uses
  # this evidence array or a stable filter of it.
  evidence ← ctx.BuildRowEvidenceFromSnapshot snapshot
  result ← Failure ⟨selectedCurrency, empty, "unsupported_selected_currency", "unsupported selected currency: " ∾ selectedCurrency⟩

  {𝕊:
    badRows ← ({𝕩.state ≢ "ok"}¨ evidence) / evidence

    {𝕊:
      bad ← ⊑ badRows
      result ↩ Failure ⟨selectedCurrency, evidence, "invalid_row_evidence", bad.source_file ∾ " row " ∾ (•Fmt bad.source_row) ∾ ": " ∾ bad.message⟩
    } ⍟ (0 < ≠ badRows) @

    {𝕊:
      accountChecks ← {𝕊 row: CheckAccountCurrency ⟨row, resolved⟩}¨ evidence
      badAccountChecks ← ({𝕩.state ≢ "ok"}¨ accountChecks) / accountChecks

      {𝕊:
        bad ← ⊑ badAccountChecks
        result ↩ Failure ⟨selectedCurrency, evidence, "account_currency_mismatch", bad.message⟩
      } ⍟ (0 < ≠ badAccountChecks) @

      {𝕊:
        selectedMask ← ({𝕩.currency}¨ evidence) ≡¨ <selectedCurrency
        selectedEvidence ← selectedMask / evidence

        {𝕊:
          result ↩ Failure ⟨selectedCurrency, selectedEvidence, "selected_currency_has_no_rows", "selected currency has no source rows: " ∾ selectedCurrency⟩
        } ⍟ (0 = ≠ selectedEvidence) @

        {𝕊:
          arithmeticEvidence ← arith.Build selectedEvidence
          # context currently exports the prepared pure seam under its retained
          # compatibility test name. M1 reuses that exact checked calculation.
          checked ← ctx.BuildCheckedPostingProjectionFromPreparedForTest ⟨selectedEvidence, arithmeticEvidence, resolved, cycleStart⟩
          result ↩ WrapChecked ⟨selectedCurrency, checked⟩
        } ⍟ (0 < ≠ selectedEvidence) @
      } ⍟ (0 = ≠ badAccountChecks) @
    } ⍟ (0 = ≠ badRows) @
  } ⍟ (IsSupportedCurrency selectedCurrency) @

  result
}

{
  IsSupportedCurrency ⇐ IsSupportedCurrency,
  CheckAccountCurrency ⇐ CheckAccountCurrency,
  Build ⇐ Build
}
