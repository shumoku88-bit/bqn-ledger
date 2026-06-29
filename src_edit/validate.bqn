# src_edit/validate.bqn
# Pure validation functions for edit operations.
# Replicates the Go editor's validateJournalLikeAddOptions logic.
#
# All functions return ⟨1, ""⟩ on success or ⟨0, "error message"⟩ on failure.
# This module has no side effects and does not read files.

lib ← •Import "../src_next/util.bqn"
date ← •Import "../src_next/date.bqn"

# ── Date validation ─────────────────────────────────────────────

# Validate YYYY-MM-DD format and calendar correctness.
ValidateDate ⇐ {
  s ← 𝕩
  
  lenOk ← 10 = ≠ s
  sepOk ← lenOk ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ ('-' = 4 ⊑ s) ∧ ('-' = 7 ⊑ s) } ⟩ @
  yearS ← lenOk ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ 4 ↑ s } ⟩ @
  monthS ← lenOk ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ 2 ↑ 5 ↓ s } ⟩ @
  dayS ← lenOk ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ 2 ↑ 8 ↓ s } ⟩ @
  
  digits ← "0123456789"
  AllDigits ← { ∧´ 𝕩 ∊ digits }
  digitsOk ← lenOk ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ ((AllDigits yearS) ∧ (AllDigits monthS) ∧ (AllDigits dayS)) } ⟩ @
  
  y ← digitsOk ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ lib.ToNum yearS } ⟩ @
  m ← digitsOk ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ lib.ToNum monthS } ⟩ @
  d ← digitsOk ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ lib.ToNum dayS } ⟩ @
  
  monthOk ← digitsOk ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ ((m ≥ 1) ∧ (m ≤ 12)) } ⟩ @
  IsLeap ← { yr ← 𝕩 ⋄ ((0 = 4 | yr) ∧ (0 ≠ 100 | yr)) ∨ (0 = 400 | yr) }
  daysInMonth ← monthOk ◶ ⟨ { 𝕊 ⋄ ⟨⟩ }, { 𝕊 ⋄ ⟨31, 28 + IsLeap y, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31⟩ } ⟩ @
  maxDay ← monthOk ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ (m - 1) ⊑ daysInMonth } ⟩ @
  dayOk ← monthOk ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ ((d ≥ 1) ∧ (d ≤ maxDay)) } ⟩ @
  
  # Inner block with checks only (no variable assignments, so semicolon bodies are safe)
  {
    (¬ lenOk) ? ⟨0, "invalid date format (expected YYYY-MM-DD): " ∾ s⟩ ;
    (¬ sepOk) ? ⟨0, "invalid date format (expected YYYY-MM-DD): " ∾ s⟩ ;
    (¬ digitsOk) ? ⟨0, "invalid date format (non-digit characters): " ∾ s⟩ ;
    (¬ monthOk) ? ⟨0, "invalid date (month out of range): " ∾ s⟩ ;
    (¬ dayOk) ? ⟨0, "invalid date (day out of range): " ∾ s⟩ ;
    ⟨1, ""⟩
  }
}

# ── Amount validation ───────────────────────────────────────────

# Validate integer amount (allows negative via leading '-').
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

# ── Field validation ────────────────────────────────────────────

# Check that a string does not contain TAB or newline.
ValidateNoTabNewline ⇐ {
  name ‿ value ← 𝕩
  tab ← @+9 ⋄ lf ← @+10 ⋄ cr ← @+13
  { (∨´ value ∊ tab‿lf‿cr) ? ⟨0, name ∾ " must not contain TAB or newline"⟩ ; ⟨1, ""⟩ }
}

# ── Account validation ─────────────────────────────────────────

# Validate that an account exists in the account list.
# accountList: list of account name strings.
ValidateAccount ⇐ {
  name ‿ acct ‿ accountList ← 𝕩
  {
    (0 = ≠ acct) ? ⟨0, "unknown " ∾ name ∾ " account: (empty)"⟩ ;
    ¬ (∨´ acct ⊸ ≡¨ accountList) ? ⟨0, "unknown " ∾ name ∾ " account: " ∾ acct⟩ ;
    ⟨1, ""⟩
  }
}

# ── Metadata validation ────────────────────────────────────────

# Validate a single metadata token: must be key=value where key is [a-z0-9_-]+
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

# Validate a list of metadata tokens.
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

# ── Post-check mode validation ──────────────────────────────────

ValidatePostCheckMode ⇐ {
  mode ← 𝕩
  { (∨´ mode ⊸ ≡¨ "lint"‿"none"‿"full") ? ⟨1, ""⟩ ; ⟨0, "invalid --post-check mode: " ∾ mode⟩ }
}

# ── Combined validation for journal-like add ────────────────────

# Validate all fields for a journal/budget/plan add operation.
# 𝕩: namespace with date, memo, from, to, amount, meta, accounts
# Returns ⟨1, ""⟩ or ⟨0, "first error"⟩
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
  {
    hasErrors ? ⟨0, ⊑ errors⟩ ;
    ⟨1, ""⟩
  }
}
