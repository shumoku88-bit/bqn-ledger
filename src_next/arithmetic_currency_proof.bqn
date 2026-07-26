# arithmetic_currency_proof.bqn
# Pure authorization policy and rejection-message construction for the
# five-field arithmetic-currency proof carrier.
#
# This module does not construct proofs, build Posting IR, render diagnostics,
# print terminal output, or exit the process.

setup ← •Import "currency_setup.bqn"

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

{
  AuthorizeArithmeticCurrencyProof ⇐ AuthorizeArithmeticCurrencyProof,
  ArithmeticCurrencyAuthorizationMessage ⇐ ArithmeticCurrencyAuthorizationMessage
}
