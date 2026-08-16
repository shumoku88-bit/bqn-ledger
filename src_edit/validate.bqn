# src_edit/validate.bqn
# Pure validation functions for edit operations.
#
# All functions return ⟨1, ""⟩ on success or ⟨0, "error message"⟩ on failure.
# This module has no side effects and does not read files or load editor policy.

date ← •Import "../src/ledger/date_ordinal.bqn"
dec ← •Import "../src/ledger/exact_decimal.bqn"

# ── Date validation ─────────────────────────────────────────────

# Validate YYYY-MM-DD format and calendar correctness.
IsDigits ← {𝕊 text:(0<≠text) ∧ ∧´text∊"0123456789"}
ValidateDate ⇐ {
  s ← 𝕩
  lenOk ← 10 = ≠ s
  sepOk ← lenOk ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ ('-' = 4 ⊑ s) ∧ ('-' = 7 ⊑ s) } ⟩ @
  yearS ← lenOk ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ 4 ↑ s } ⟩ @
  monthS ← lenOk ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ 2 ↑ 5 ↓ s } ⟩ @
  dayS ← lenOk ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ 2 ↑ 8 ↓ s } ⟩ @
  digitsOk ← lenOk ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ (IsDigits yearS) ∧ (IsDigits monthS) ∧ IsDigits dayS } ⟩ @
  calendarOk ← digitsOk ∧ date.IsValid s
  {
    (¬ lenOk) ? ⟨0, "invalid date format (expected YYYY-MM-DD): " ∾ s⟩ ;
    (¬ sepOk) ? ⟨0, "invalid date format (expected YYYY-MM-DD): " ∾ s⟩ ;
    (¬ digitsOk) ? ⟨0, "invalid date format (non-digit characters): " ∾ s⟩ ;
    (¬ calendarOk) ? ⟨0, "invalid date (day/month out of range): " ∾ s⟩ ;
    ⟨1, ""⟩
  }
}

# ── Amount validation ───────────────────────────────────────────

FractionDigits ← {
  s ← 𝕩
  positions ← ('.' = s) / ↕ ≠ s
  (1 = ≠ positions) ◶ ⟨
    { 𝕊 ⋄ 0 },
    { 𝕊 ⋄ ((≠ s) - 1) - ⊑ positions }
  ⟩ @
}

# Integer-only validator retained for the Issue TSV input contract.
ValidateAmount ⇐ {
  s ← 𝕩
  digits ← "0123456789"
  hasMinus ← (0 < ≠ s) ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ ('-' = ⊑ s) } ⟩ @
  body ← hasMinus ◶ ⟨ { 𝕊 ⋄ s }, { 𝕊 ⋄ 1 ↓ s } ⟩ @
  bodyOk ← (0 < ≠ body) ∧ (∧´ body ∊ digits)

  {
    (0 = ≠ s) ? ⟨0, "amount must be an integer: (empty)"⟩ ;
    (0 = ≠ body) ? ⟨0, "amount must be an integer: " ∾ s⟩ ;
    (¬ bodyOk) ? ⟨0, "amount must be an integer: " ∾ s⟩ ;
    ⟨1, ""⟩
  }
}

# Exact decimal lexical validation against a caller-owned admitted currency
# policy. Policy acquisition is intentionally outside this pure module.
ValidateExactAmountForPolicy ⇐ {
  currency ‿ policy ‿ amount ← 𝕩
  parsed ← dec.Parse amount
  fractionDigits ← FractionDigits amount
  hasFiniteLimit ← 0 ≤ policy.max_fraction_digits
  exceedsLimit ← hasFiniteLimit ∧ (policy.max_fraction_digits < fractionDigits)
  {
    (policy.state ≢ "ok") ? ⟨0, "unsupported currency: " ∾ currency⟩ ;
    (parsed.state ≢ "ok") ? ⟨0, "amount must be an exact decimal: " ∾ amount⟩ ;
    exceedsLimit ? ⟨0, currency ∾ " amount must have at most " ∾ (•Fmt policy.max_fraction_digits) ∾ " fractional digits: " ∾ amount⟩ ;
    ⟨1, ""⟩
  }
}

# ── Field validation ────────────────────────────────────────────

ValidateNoTabNewline ⇐ {
  name ‿ value ← 𝕩
  tab ← @+9 ⋄ lf ← @+10 ⋄ cr ← @+13
  { (∨´ value ∊ tab‿lf‿cr) ? ⟨0, name ∾ " must not contain TAB or newline"⟩ ; ⟨1, ""⟩ }
}

# ── Metadata validation ────────────────────────────────────────

ValidateMetaToken ⇐ {
  token ← 𝕩
  tab ← @+9 ⋄ lf ← @+10 ⋄ cr ← @+13
  hasEq ← ∨´ '=' = token
  eqPos ← hasEq ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ ⊑ / '=' = token } ⟩ @
  key ← hasEq ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ eqPos ↑ token } ⟩ @
  validKeyChars ← "abcdefghijklmnopqrstuvwxyz0123456789_-"

  {
    (∨´ token ∊ tab‿lf‿cr) ? ⟨0, "metadata token must not contain TAB or newline: " ∾ token⟩ ;
    ¬ hasEq ? ⟨0, "invalid metadata token (missing '='): " ∾ token⟩ ;
    (0 = ≠ key) ? ⟨0, "invalid metadata token (empty key): " ∾ token⟩ ;
    ¬ (∧´ key ∊ validKeyChars) ? ⟨0, "invalid metadata token (key contains invalid chars): " ∾ token⟩ ;
    ⟨1, ""⟩
  }
}

ValidateMeta ⇐ {
  tokens ← 𝕩
  results ← ValidateMetaToken¨ tokens
  errors ← (¬ ⊑¨ results) / 1⊸⊑¨ results
  hasErrors ← 0 < ≠ errors
  {
    (0 = ≠ tokens) ? ⟨1, ""⟩ ;
    hasErrors ? ⟨0, ⊑ errors⟩ ;
    ⟨1, ""⟩
  }
}

ValidateNoCurrencyMeta ⇐ {
  tokens ← 𝕩
  prefix ← "currency="
  hasCurrency ← ∨´ 0 ∾ ({ (≠prefix) ≤ ≠𝕩 ? prefix ≡ (≠prefix) ↑ 𝕩 ; 0 }¨ tokens)
  { hasCurrency ? ⟨0, "currency metadata is owned by --currency/default selection"⟩ ; ⟨1, ""⟩ }
}
