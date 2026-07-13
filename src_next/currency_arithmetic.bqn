# currency_arithmetic.bqn
# Pure Currency Stage 2 B2 snapshot arithmetic over pre-built B1 row evidence.
# This module does not load source data, parse source rows, authorize projection,
# or build posting rows. Exact normalization is admitted through exact_decimal.

dec ← •Import "exact_decimal.bqn"
setup ← •Import "currency_setup.bqn"

empty ← ⟨⟩

Success ← {𝕊 domain‿amountScale‿coefficients:
  {
    state ⇐ "ok",
    domain ⇐ domain,
    amount_scale ⇐ amountScale,
    normalized_coefficients ⇐ coefficients,
    message ⇐ ""
  }
}

Failure ← {𝕊 messageText:
  {
    state ⇐ "error",
    domain ⇐ empty,
    amount_scale ⇐ empty,
    normalized_coefficients ⇐ empty,
    message ⇐ messageText
  }
}

Normalize ← {𝕊 row‿amountScale:
  zeroCount ← amountScale - row.parsed.scale
  normalizedText ← (•Fmt row.parsed.coefficient) ∾ zeroCount ⥊ '0'
  dec.Parse normalizedText
}

Build ← {𝕊 evidence:
  result ← Success ⟨"JPY", 0, empty⟩

  {𝕊:
    rowsOk ← ∧´ { (𝕩.state ≡ "ok") ∧ (𝕩.parsed.state ≡ "ok") } ¨ evidence

    rowsOk ◶ ⟨
      {𝕊: result ↩ Failure "invalid_row_evidence" },
      {𝕊:
        currencies ← {𝕩.currency} ¨ evidence
        domain ← ⊑ currencies
        oneDomain ← ∧´ currencies ≡¨ <domain
        supportedDomain ← setup.IsSupportedCurrency domain

        (oneDomain ∧ supportedDomain) ◶ ⟨
          {𝕊: result ↩ Failure "mixed_currency_domains" },
          {𝕊:
            amountScale ← ⌈´ {𝕩.parsed.scale} ¨ evidence
            normalized ← {𝕊 row: Normalize ⟨row, amountScale⟩} ¨ evidence
            normalizedOk ← ∧´ {𝕩.state ≡ "ok"} ¨ normalized

            normalizedOk ◶ ⟨
              {𝕊: result ↩ Failure "normalized_amount_out_of_exact_range" },
              {𝕊: result ↩ Success ⟨domain, amountScale, {𝕩.coefficient} ¨ normalized⟩ }
            ⟩ @
          }
        ⟩ @
      }
    ⟩ @
  } ⍟ (0 < ≠ evidence) @

  result
}

{ Build ⇐ Build }
