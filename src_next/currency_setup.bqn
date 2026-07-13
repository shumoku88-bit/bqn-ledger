# currency_setup.bqn
# Pure M1.5 core for explicit ledger default currency and read-only JPY
# migration audit / preview.
#
# Important boundary:
# - DEFAULT_CURRENCY selects an initial view only.
# - It never supplies missing source currency.
# - Migration target is an independent explicit argument and is currently JPY only.
# - This module performs no file I/O and no writes.

util ← •Import "util.bqn"

empty ← ⟨⟩
tab ← @+9
supportedCurrencies ← ⟨"JPY", "ILS"⟩
defaultKey ← "DEFAULT_CURRENCY"

IsSupportedCurrency ← {𝕊 currency:
  ∨´ 0 ∾ (currency⊸≡¨ supportedCurrencies)
}

IsIgnoredLine ← {𝕊 line:
  (0 = ≠ line) ? 1 ; ((⊑ line) = '#') ∨ ((⊑ line) = '\\')
}

HasPrefix ← {𝕊 prefix‿text:
  (≠ prefix) ≤ ≠ text ? prefix ≡ (≠ prefix) ↑ text ; 0
}

ParseConfigLine ← {𝕊 line:
  hasTab ← ∨´ tab = line
  separator ← hasTab ? tab ; '='
  parts ← separator util.SplitKeepEmpty line
  key ← 0 ⊑ parts
  value ← (1 < ≠ parts) ? 1 ⊑ parts ; ""
  { key ⇐ key, value ⇐ value }
}

DefaultFailure ← {𝕊 code‿message:
  {
    state ⇐ "error",
    key ⇐ defaultKey,
    currency ⇐ "",
    provenance ⇐ "",
    code ⇐ code,
    message ⇐ message
  }
}

DefaultSuccess ← {𝕊 currency:
  {
    state ⇐ "ok",
    key ⇐ defaultKey,
    currency ⇐ currency,
    provenance ⇐ "ledger_config",
    code ⇐ "",
    message ⇐ ""
  }
}

ResolveDefault ← {𝕊 configLines:
  dataLines ← (¬ IsIgnoredLine¨ configLines) / configLines
  parsed ← ParseConfigLine¨ dataLines
  hits ← ({ defaultKey ≡ 𝕩.key }¨ parsed) / parsed

  (0 = ≠ hits) ?
    DefaultFailure ⟨"missing_default_currency", "missing ledger config key: " ∾ defaultKey⟩ ;
  (1 < ≠ hits) ?
    DefaultFailure ⟨"duplicate_default_currency", "duplicate ledger config key: " ∾ defaultKey⟩ ;
  {
    value ← (⊑ hits).value
    (0 = ≠ value) ?
      DefaultFailure ⟨"empty_default_currency", "empty ledger config value: " ∾ defaultKey⟩ ;
    (¬ IsSupportedCurrency value) ?
      DefaultFailure ⟨"unsupported_default_currency", "unsupported default currency: " ∾ value⟩ ;
    DefaultSuccess value
  } @
}

SelectionFailure ← {𝕊 code‿message:
  {
    state ⇐ "error",
    currency ⇐ "",
    provenance ⇐ "",
    code ⇐ code,
    message ⇐ message
  }
}

SelectionSuccess ← {𝕊 currency‿provenance:
  {
    state ⇐ "ok",
    currency ⇐ currency,
    provenance ⇐ provenance,
    code ⇐ "",
    message ⇐ ""
  }
}

ResolveSelection ← {𝕊 defaultResult‿explicitCurrency:
  (0 < ≠ explicitCurrency) ?
    ((IsSupportedCurrency explicitCurrency) ?
      SelectionSuccess ⟨explicitCurrency, "explicit_selection"⟩ ;
      SelectionFailure ⟨"unsupported_selected_currency", "unsupported selected currency: " ∾ explicitCurrency⟩) ;
    ((defaultResult.state ≡ "ok") ?
      SelectionSuccess ⟨defaultResult.currency, "ledger_default"⟩ ;
      SelectionFailure ⟨"default_currency_unavailable", defaultResult.message⟩)
}

LineResult ← {𝕊 state‿classification‿rowIndex‿originalLine‿proposedLine‿currency‿message:
  {
    state ⇐ state,
    classification ⇐ classification,
    source_row ⇐ rowIndex,
    original_line ⇐ originalLine,
    proposed_line ⇐ proposedLine,
    currency ⇐ currency,
    message ⇐ message
  }
}

AuditLine ← {𝕊 fileName‿kind‿rowIndex‿line‿targetCurrency:
  IsIgnoredLine line ?
    LineResult ⟨"ok", "ignored", rowIndex, line, line, "", ""⟩ ;
  {
    fields ← tab util.SplitKeepEmpty line
    minFields ← (kind ≡ "accounts") ? 1 ; 5
    structurallyValid ← (minFields ≤ ≠ fields) ∧ ((kind ≢ "accounts") ∨ (0 < ≠ ⊑ fields))

    (¬ structurallyValid) ?
      LineResult ⟨"error", "invalid_structure", rowIndex, line, line, "", fileName ∾ " row " ∾ (•Fmt rowIndex) ∾ ": invalid source structure"⟩ ;
    {
      metaStart ← (kind ≡ "accounts") ? 1 ; 5
      metadata ← metaStart ↓ fields
      currencyTokens ← ({ HasPrefix ⟨"currency=", 𝕩⟩ }¨ metadata) / metadata

      (0 = ≠ currencyTokens) ?
        LineResult ⟨"ok", "missing", rowIndex, line, line ∾ tab ∾ "currency=" ∾ targetCurrency, targetCurrency, ""⟩ ;
      (1 < ≠ currencyTokens) ?
        LineResult ⟨"error", "duplicate", rowIndex, line, line, "", fileName ∾ " row " ∾ (•Fmt rowIndex) ∾ ": duplicate currency metadata"⟩ ;
      {
        currency ← 9 ↓ ⊑ currencyTokens
        (¬ IsSupportedCurrency currency) ?
          LineResult ⟨"error", "unknown", rowIndex, line, line, currency, fileName ∾ " row " ∾ (•Fmt rowIndex) ∾ ": unsupported currency: " ∾ currency⟩ ;
          LineResult ⟨"ok", "explicit", rowIndex, line, line, currency, ""⟩
      } @
    } @
  } @
}

AuditFile ← {𝕊 fileName‿kind‿lines‿targetCurrency:
  rows ← {𝕊 index:
    AuditLine ⟨fileName, kind, index, index ⊑ lines, targetCurrency⟩
  }¨ ↕ ≠ lines

  errorCount ← +´ { 𝕩.state ≢ "ok" }¨ rows
  missingCount ← +´ { 𝕩.classification ≡ "missing" }¨ rows
  explicitCount ← +´ { 𝕩.classification ≡ "explicit" }¨ rows
  ignoredCount ← +´ { 𝕩.classification ≡ "ignored" }¨ rows
  proposedLines ← (0 = errorCount) ? ({𝕩.proposed_line}¨ rows) ; empty

  {
    state ⇐ (0 = errorCount) ? "ok" ; "error",
    file_name ⇐ fileName,
    kind ⇐ kind,
    target_currency ⇐ targetCurrency,
    rows ⇐ rows,
    proposed_lines ⇐ proposedLines,
    missing_count ⇐ missingCount,
    explicit_count ⇐ explicitCount,
    ignored_count ⇐ ignoredCount,
    error_count ⇐ errorCount,
    changed_count ⇐ missingCount
  }
}

Build ← {𝕊 configLines‿accountsLines‿journalLines‿planLines‿budgetLines‿targetCurrency:
  defaultResult ← ResolveDefault configLines
  targetOk ← targetCurrency ≡ "JPY"

  files ← targetOk ? ⟨
    AuditFile ⟨"accounts.tsv", "accounts", accountsLines, targetCurrency⟩,
    AuditFile ⟨"journal.tsv", "journal", journalLines, targetCurrency⟩,
    AuditFile ⟨"plan.tsv", "journal", planLines, targetCurrency⟩,
    AuditFile ⟨"budget_alloc.tsv", "journal", budgetLines, targetCurrency⟩
  ⟩ ; empty

  fileErrorCount ← +´ { 𝕩.error_count }¨ files
  targetMessage ← targetOk ? "" ; "unsupported migration target: " ∾ targetCurrency ∾ "; M1.5 permits JPY only"
  overallOk ← (defaultResult.state ≡ "ok") ∧ targetOk ∧ (0 = fileErrorCount)

  {
    state ⇐ overallOk ? "ok" ; "error",
    default_currency ⇐ defaultResult,
    migration_target ⇐ targetCurrency,
    files ⇐ files,
    changed_count ⇐ +´ { 𝕩.changed_count }¨ files,
    error_count ⇐ fileErrorCount + (¬targetOk) + (defaultResult.state ≢ "ok"),
    message ⇐ (defaultResult.state ≢ "ok") ? defaultResult.message ; targetMessage
  }
}

{
  IsSupportedCurrency ⇐ IsSupportedCurrency,
  ResolveDefault ⇐ ResolveDefault,
  ResolveSelection ⇐ ResolveSelection,
  AuditLine ⇐ AuditLine,
  AuditFile ⇐ AuditFile,
  Build ⇐ Build
}
