# source_currency_admission.bqn
# Pure source-currency admission before account resolution or posting projection.
# It operates only on supplied source lines and a supplied posting snapshot.

setup ← •Import "currency_setup.bqn"

empty ← ⟨⟩
tab ← @+9
sourceCurrencyPolicy ← {
  production_strict ⇐ "production_strict",
  legacy_compatibility ⇐ "legacy_compatibility"
}

IsSupportedCurrency ← {𝕊 currency:
  setup.IsSupportedCurrency currency
}

# Keep the source-audit rule: blank, # comment, and \ comment lines are ignored.
IsIgnoredLine ← {𝕊 line:
  ignored ← 0
  {𝕊: ignored ↩ 1 } ⍟ (0 = ≠ line) @
  {𝕊: ignored ↩ ((⊑ line) = '#') ∨ ((⊑ line) = ⊑"\\") } ⍟ (0 < ≠ line) @
  ignored
}

SplitKeepEmpty ← {𝕊 text:
  mask ← tab = text
  groups ← (+` mask) ⊔ text
  { (tab ≠ 𝕩) / 𝕩 } ¨ groups
}

HasPrefix ← {𝕊 prefix‿text:
  ((≠ prefix) ≤ ≠ text) ∧ (prefix ≡ (≠ prefix) ↑ text)
}

CurrencyTokens ← {𝕊 metadata:
  ({ HasPrefix ⟨"currency=", 𝕩⟩ } ¨ metadata) / metadata
}

Classification ← {𝕊 tokens:
  count ← ≠ tokens
  classification ← "missing"
  {𝕊: classification ↩ "duplicate" } ⍟ (1 < count) @
  {𝕊:
    value ← 9 ↓ ⊑ tokens
    classification ↩ "empty"
    {𝕊: classification ↩ "unsupported" } ⍟ ((0 < ≠ value) ∧ (¬ IsSupportedCurrency value)) @
    {𝕊: classification ↩ "explicit" } ⍟ ((0 < ≠ value) ∧ IsSupportedCurrency value) @
  } ⍟ (1 = count) @
  classification
}

IsPostingSourceFile ← {𝕊 sourceFile:
  ∨´ 0 ∾ (sourceFile⊸≡¨ ⟨"actual.journal", "plan.tsv", "budget_alloc.tsv"⟩)
}

Diagnostic ← {𝕊 code‿sourceKind‿sourceFile‿sourceRow:
  {
    severity ⇐ "error",
    stage ⇐ "source_currency_admission",
    code ⇐ code,
    source_kind ⇐ sourceKind,
    source_file ⇐ sourceFile,
    source_row ⇐ sourceRow,
    message ⇐ sourceFile ∾ " row " ∾ (•Fmt sourceRow) ∾ ": " ∾ code
  }
}

NoSourceDiagnostic ← {𝕊 code‿message:
  {
    severity ⇐ "error",
    stage ⇐ "source_currency_admission",
    code ⇐ code,
    source_kind ⇐ "",
    source_file ⇐ "",
    source_row ⇐ ¯1,
    message ⇐ message
  }
}

policyDiagnostic ← NoSourceDiagnostic ⟨"source_currency_policy_unknown", "source currency policy: unknown"⟩
invalidSourceDiagnostic ← NoSourceDiagnostic ⟨"source_currency_source_file_invalid", "posting source file invalid"⟩

Evidence ← {𝕊 sourceKind‿sourceFile‿sourceRow‿currency‿provenance:
  {
    source_kind ⇐ sourceKind,
    source_file ⇐ sourceFile,
    source_row ⇐ sourceRow,
    currency ⇐ currency,
    provenance ⇐ provenance
  }
}

AdmissionForLine ← {𝕊 policy‿sourceKind‿sourceFile‿sourceRow‿metadata:
  tokens ← CurrencyTokens metadata
  classification ← Classification tokens
  result ← { state ⇐ "ok", evidence ⇐ ⟨⟩, diagnostics ⇐ ⟨⟩ }
  missing ← classification ≡ "missing"
  explicit ← classification ≡ "explicit"
  fatal ← (¬ explicit) ∧ ((policy ≢ sourceCurrencyPolicy.legacy_compatibility) ∨ (¬ missing))

  {𝕊:
    result ↩ {
      state ⇐ "ok",
      evidence ⇐ ⟨Evidence ⟨sourceKind, sourceFile, sourceRow, "JPY", "legacy_compatibility"⟩⟩,
      diagnostics ⇐ ⟨⟩
    }
  } ⍟ ((policy ≡ sourceCurrencyPolicy.legacy_compatibility) ∧ missing) @

  {𝕊:
    value ← 9 ↓ ⊑ tokens
    result ↩ {
      state ⇐ "ok",
      evidence ⇐ ⟨Evidence ⟨sourceKind, sourceFile, sourceRow, value, "explicit"⟩⟩,
      diagnostics ⇐ ⟨⟩
    }
  } ⍟ explicit @

  {𝕊:
    codePrefix ← (sourceKind ≡ "account") ⊑ "row_currency_"‿"account_currency_"
    result ↩ {
      state ⇐ "error",
      evidence ⇐ ⟨⟩,
      diagnostics ⇐ ⟨Diagnostic ⟨codePrefix ∾ classification, sourceKind, sourceFile, sourceRow⟩⟩
    }
  } ⍟ fatal @

  result
}

AdmitAccounts ← {𝕊 policy‿lines:
  results ← {𝕊 row:
    line ← row ⊑ lines
    result ← { state ⇐ "ok", evidence ⇐ ⟨⟩, diagnostics ⇐ ⟨⟩ }
    {𝕊:
      fields ← SplitKeepEmpty line
      result ↩ AdmissionForLine ⟨policy, "account", "accounts.tsv", row, 1 ↓ fields⟩
    } ⍟ (¬ IsIgnoredLine line) @
    result
  } ¨ ↕ ≠ lines
  {
    evidence ⇐ ∾ {𝕩.evidence} ¨ results,
    diagnostics ⇐ ∾ {𝕩.diagnostics} ¨ results
  }
}

AdmitRowsForSource ← {𝕊 policy‿source:
  sourceFile ← source.source_file
  results ← ⟨{ state ⇐ "error", evidence ⇐ ⟨⟩, diagnostics ⇐ ⟨invalidSourceDiagnostic⟩ }⟩
  {𝕊:
    results ↩ {𝕊 row:
      line ← row ⊑ source.lines
      result ← { state ⇐ "ok", evidence ⇐ ⟨⟩, diagnostics ⇐ ⟨⟩ }
      {𝕊:
        fields ← SplitKeepEmpty line
        result ↩ AdmissionForLine ⟨policy, "journal_like", sourceFile, row, 5 ↓ fields⟩
      } ⍟ (¬ IsIgnoredLine line) @
      result
    } ¨ ↕ ≠ source.lines
  } ⍟ (IsPostingSourceFile sourceFile) @
  results
}

AdmitRows ← {𝕊 policy‿snapshot:
  results ← ∾ { AdmitRowsForSource ⟨policy, 𝕩⟩ } ¨ snapshot.sources
  {
    evidence ⇐ ∾ {𝕩.evidence} ¨ results,
    diagnostics ⇐ ∾ {𝕩.diagnostics} ¨ results
  }
}

# Admit accepts only supplied account lines, a context-shaped supplied snapshot,
# and an explicit closed policy value. It never partially admits on any error.
Admit ← {𝕊 policy‿accountLines‿snapshot:
  result ← {
    state ⇐ "error",
    admitted_account_evidence ⇐ ⟨⟩,
    admitted_row_evidence ⇐ ⟨⟩,
    diagnostics ⇐ ⟨policyDiagnostic⟩
  }
  knownPolicy ← (policy ≡ sourceCurrencyPolicy.production_strict) ∨ (policy ≡ sourceCurrencyPolicy.legacy_compatibility)
  {𝕊:
    accounts ← AdmitAccounts ⟨policy, accountLines⟩
    rows ← AdmitRows ⟨policy, snapshot⟩
    diagnostics ← accounts.diagnostics ∾ rows.diagnostics
    {𝕊:
      result ↩ {
        state ⇐ "ok",
        admitted_account_evidence ⇐ accounts.evidence,
        admitted_row_evidence ⇐ rows.evidence,
        diagnostics ⇐ ⟨⟩
      }
    } ⍟ (0 = ≠ diagnostics) @
    {𝕊:
      result ↩ {
        state ⇐ "error",
        admitted_account_evidence ⇐ ⟨⟩,
        admitted_row_evidence ⇐ ⟨⟩,
        diagnostics ⇐ diagnostics
      }
    } ⍟ (0 < ≠ diagnostics) @
  } ⍟ knownPolicy @
  result
}

{
  policy ⇐ sourceCurrencyPolicy,
  Admit ⇐ Admit
}
