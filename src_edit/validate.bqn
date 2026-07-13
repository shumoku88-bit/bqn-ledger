# src_edit/validate.bqn
# Pure validation functions for edit operations.
#
# All functions return ⟨1, ""⟩ on success or ⟨0, "error message"⟩ on failure.
# This module has no side effects and does not read files.

date ← •Import "../src_next/date.bqn"
dec ← •Import "../src_next/exact_decimal.bqn"

supportedCurrencies ← ⟨"JPY", "ILS"⟩

# ── Date validation ─────────────────────────────────────────────

# Validate YYYY-MM-DD format and calendar correctness.
ValidateDate ⇐ {
  s ← 𝕩
  lenOk ← 10 = ≠ s
  sepOk ← lenOk ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ ('-' = 4 ⊑ s) ∧ ('-' = 7 ⊑ s) } ⟩ @
  yearS ← lenOk ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ 4 ↑ s } ⟩ @
  monthS ← lenOk ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ 2 ↑ 5 ↓ s } ⟩ @
  dayS ← lenOk ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ 2 ↑ 8 ↓ s } ⟩ @
  digitsOk ← lenOk ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ (date.IsDigits yearS) ∧ (date.IsDigits monthS) ∧ (date.IsDigits dayS) } ⟩ @
  calendarOk ← digitsOk ∧ date.IsValidDateText s
  {
    (¬ lenOk) ? ⟨0, "invalid date format (expected YYYY-MM-DD): " ∾ s⟩ ;
    (¬ sepOk) ? ⟨0, "invalid date format (expected YYYY-MM-DD): " ∾ s⟩ ;
    (¬ digitsOk) ? ⟨0, "invalid date format (non-digit characters): " ∾ s⟩ ;
    (¬ calendarOk) ? ⟨0, "invalid date (day/month out of range): " ∾ s⟩ ;
    ⟨1, ""⟩
  }
}

# ── Currency and amount validation ──────────────────────────────

IsSupportedCurrency ⇐ { ∨´ 0 ∾ (𝕩⊸≡¨ supportedCurrencies) }

ValidateCurrency ⇐ {
  currency ← 𝕩
  {
    (0 = ≠ currency) ? ⟨0, "currency must be explicit or resolvable from DEFAULT_CURRENCY"⟩ ;
    (¬ IsSupportedCurrency currency) ? ⟨0, "unsupported currency: " ∾ currency⟩ ;
    ⟨1, ""⟩
  }
}

FractionDigits ← {
  s ← 𝕩
  positions ← ('.' = s) / ↕ ≠ s
  count ← 0
  {𝕊: count ↩ ((≠ s) - 1) - ⊑ positions } ⍟ (1 = ≠ positions) @
  count
}

# Existing integer-only validator remains the owner for budget/plan/issue paths.
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

# Journal M2 path: exact decimal source text, with lexical ILS precision policy.
# More than two ILS fractional digits is rejected without rounding, including
# trailing zero forms such as 1.000.
ValidateExactAmountForCurrency ⇐ {
  currency ‿ amount ← 𝕩
  parsed ← dec.Parse amount
  fractionDigits ← FractionDigits amount
  {
    (¬ IsSupportedCurrency currency) ? ⟨0, "unsupported currency: " ∾ currency⟩ ;
    (parsed.state ≢ "ok") ? ⟨0, "amount must be an exact decimal: " ∾ amount⟩ ;
    ((currency ≡ "ILS") ∧ (2 < fractionDigits)) ? ⟨0, "ILS amount must have at most 2 fractional digits: " ∾ amount⟩ ;
    ⟨1, ""⟩
  }
}

# ── Field validation ────────────────────────────────────────────

ValidateNoTabNewline ⇐ {
  name ‿ value ← 𝕩
  tab ← @+9 ⋄ lf ← @+10 ⋄ cr ← @+13
  { (∨´ value ∊ tab‿lf‿cr) ? ⟨0, name ∾ " must not contain TAB or newline"⟩ ; ⟨1, ""⟩ }
}

# ── Account validation ─────────────────────────────────────────

ValidateAccount ⇐ {
  name ‿ acct ‿ accountList ← 𝕩
  {
    (0 = ≠ acct) ? ⟨0, "unknown " ∾ name ∾ " account: (empty)"⟩ ;
    ¬ (∨´ acct ⊸ ≡¨ accountList) ? ⟨0, "unknown " ∾ name ∾ " account: " ∾ acct⟩ ;
    ⟨1, ""⟩
  }
}

ValidateAccountCurrency ⇐ {
  name ‿ acct ‿ selectedCurrency ‿ accountList ‿ accountCurrencies ← 𝕩
  idx ← ⊑ accountList ⊐ ⟨acct⟩
  n ← ≠ accountList
  actual ← idx ⊑ (accountCurrencies ∾ ⟨""⟩)
  {
    (idx ≥ n) ? ⟨0, "unknown " ∾ name ∾ " account: " ∾ acct⟩ ;
    (actual ≢ selectedCurrency) ? ⟨0, name ∾ " account currency mismatch: " ∾ acct ∾ " is " ∾ actual ∾ ", selected " ∾ selectedCurrency⟩ ;
    ⟨1, ""⟩
  }
}

ValidateAccountAdd ⇐ {
  name ← 𝕩.name
  role ← 𝕩.role
  type ← 𝕩.type
  currency ← 𝕩.currency
  accounts ← 𝕩.accounts
  roles ← "asset"‿"liability"‿"income"‿"expense"
  prefixes ← "assets:"‿"liabilities:"‿"income:"‿"expenses:"
  roleMask ← role ⊸ ≡¨ roles
  roleOk ← ∨´ roleMask
  prefix ← roleOk ◶ ⟨ {𝕊 ⋄ ""}, {𝕊 ⋄ ⊑ roleMask / prefixes} ⟩ @
  prefixOk ← (≠prefix) ≤ ≠name
  prefixOk ∧↩ prefix ≡ (≠prefix) ↑ name
  suffixOk ← prefixOk ∧ (≠prefix) < ≠name
  typeOk ← (0 = ≠type) ∨ ((role ≡ "asset") ∧ (∨´ type ⊸ ≡¨ "liquid"‿"savings"‿"invest"))
  fieldCheck ← ValidateNoTabNewline "account name"‿name
  currencyCheck ← ValidateCurrency currency
  {
    (¬ ⊑fieldCheck) ? fieldCheck ;
    (¬ ⊑currencyCheck) ? currencyCheck ;
    (0 = ≠name) ? ⟨0, "account name must not be empty"⟩ ;
    (∨´ name ⊸ ≡¨ accounts) ? ⟨0, "account already exists: " ∾ name⟩ ;
    (¬roleOk) ? ⟨0, "invalid account role: " ∾ role⟩ ;
    (¬prefixOk) ? ⟨0, "account namespace must match role=" ∾ role ∾ ": " ∾ name⟩ ;
    (¬suffixOk) ? ⟨0, "account name must include a name after namespace: " ∾ name⟩ ;
    (¬typeOk) ? ⟨0, "invalid account type for role=" ∾ role ∾ ": " ∾ type⟩ ;
    ⟨1, ""⟩
  }
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

# ── Post-check mode validation ─────────────────────────────────

ValidatePostCheckMode ⇐ {
  mode ← 𝕩
  { (∨´ mode ⊸ ≡¨ "lint"‿"none"‿"full") ? ⟨1, ""⟩ ; ⟨0, "invalid --post-check mode: " ∾ mode⟩ }
}

# ── Combined validation for add operations ─────────────────────

# Integer-only owner retained for budget and plan add operations.
ValidateJournalLikeAdd ⇐ {
  checks ← ⟨
    ValidateDate 𝕩.date
    ValidateNoTabNewline "memo"‿𝕩.memo
    ValidateNoTabNewline "from"‿𝕩.from
    ValidateNoTabNewline "to"‿𝕩.to
    ValidateNoTabNewline "amount"‿𝕩.amount
    ValidateAccount "from"‿𝕩.from‿𝕩.accounts
    ValidateAccount "to"‿𝕩.to‿𝕩.accounts
    ValidateAmount 𝕩.amount
    ValidateMeta 𝕩.meta
  ⟩
  errors ← (¬ ⊑¨ checks) / 1⊸⊑¨ checks
  hasErrors ← 0 < ≠ errors
  { hasErrors ? ⟨0, ⊑ errors⟩ ; ⟨1, ""⟩ }
}

# M2 journal-only exact-decimal and account-currency contract.
ValidateCurrencyJournalAdd ⇐ {
  checks ← ⟨
    ValidateDate 𝕩.date
    ValidateNoTabNewline "memo"‿𝕩.memo
    ValidateNoTabNewline "from"‿𝕩.from
    ValidateNoTabNewline "to"‿𝕩.to
    ValidateNoTabNewline "amount"‿𝕩.amount
    ValidateCurrency 𝕩.currency
    ValidateAccount "from"‿𝕩.from‿𝕩.accounts
    ValidateAccount "to"‿𝕩.to‿𝕩.accounts
    ValidateAccountCurrency "from"‿𝕩.from‿𝕩.currency‿𝕩.accounts‿𝕩.account_currencies
    ValidateAccountCurrency "to"‿𝕩.to‿𝕩.currency‿𝕩.accounts‿𝕩.account_currencies
    ValidateExactAmountForCurrency 𝕩.currency‿𝕩.amount
    ValidateMeta 𝕩.meta
    ValidateNoCurrencyMeta 𝕩.meta
  ⟩
  errors ← (¬ ⊑¨ checks) / 1⊸⊑¨ checks
  hasErrors ← 0 < ≠ errors
  { hasErrors ? ⟨0, ⊑ errors⟩ ; ⟨1, ""⟩ }
}
