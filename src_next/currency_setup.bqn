# currency_setup.bqn
# Pure M1.5 core for explicit ledger default currency, built-in currency policy,
# and read-only JPY migration audit / preview.
#
# Important boundary:
# - DEFAULT_CURRENCY selects an initial view only.
# - It never supplies missing source currency.
# - Built-in currency policy owns admission and lexical precision metadata.
# - Migration target is an independent explicit argument and is currently JPY only.
# - This module performs no file I/O and no writes.

util ← •Import "util.bqn"

empty ← ⟨⟩
tab ← @+9
currencyCodes ← ⟨"JPY", "ILS"⟩
currencyMaxFractionDigits ← ⟨¯1, 2⟩
defaultKey ← "DEFAULT_CURRENCY"

PolicyFailure ← {𝕊 currency:
  {
    state ⇐ "error",
    currency ⇐ currency,
    max_fraction_digits ⇐ ¯1,
    code ⇐ "unsupported_currency",
    message ⇐ "unsupported currency: " ∾ currency
  }
}

PolicySuccess ← {𝕊 index:
  {
    state ⇐ "ok",
    currency ⇐ index ⊑ currencyCodes,
    max_fraction_digits ⇐ index ⊑ currencyMaxFractionDigits,
    code ⇐ "",
    message ⇐ ""
  }
}

Policy ← {𝕊 currency:
  index ← ⊑ currencyCodes ⊐ ⟨currency⟩
  result ← PolicyFailure currency
  {𝕊: result ↩ PolicySuccess index } ⍟ (index < ≠ currencyCodes) @
  result
}

IsSupportedCurrency ← {𝕊 currency:
  policy ← Policy currency
  policy.state ≡ "ok"
}

IsIgnoredLine ← {𝕊 line:
  ignored ← 0
  {𝕊: ignored ↩ 1 } ⍟ (0 = ≠ line) @
  {𝕊: ignored ↩ ((⊑ line) = '#') ∨ ((⊑ line) = ⊑"\\") } ⍟ (0 < ≠ line) @
  ignored
}

HasPrefix ← {𝕊 prefix‿text:
  matches ← 0
  {𝕊: matches ↩ prefix ≡ (≠ prefix) ↑ text } ⍟ ((≠ prefix) ≤ ≠ text) @
  matches
}

ParseConfigLine ← {𝕊 line:
  hasTab ← ∨´ tab = line
  separator ← hasTab ⊑ ⟨'=', tab⟩
  parts ← separator util.SplitKeepEmpty line
  key ← 0 ⊑ parts
  value ← ""
  {𝕊: value ↩ 1 ⊑ parts } ⍟ (1 < ≠ parts) @
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
  hitCount ← ≠ hits

  result ← DefaultFailure ⟨"missing_default_currency", "missing ledger config key: " ∾ defaultKey⟩

  {𝕊:
    result ↩ DefaultFailure ⟨"duplicate_default_currency", "duplicate ledger config key: " ∾ defaultKey⟩
  } ⍟ (1 < hitCount) @

  {𝕊:
    value ← (⊑ hits).value
    result ↩ DefaultFailure ⟨"empty_default_currency", "empty ledger config value: " ∾ defaultKey⟩
    {𝕊:
      result ↩ DefaultFailure ⟨"unsupported_default_currency", "unsupported default currency: " ∾ value⟩
    } ⍟ ((0 < ≠ value) ∧ (¬ IsSupportedCurrency value)) @
    {𝕊:
      result ↩ DefaultSuccess value
    } ⍟ ((0 < ≠ value) ∧ IsSupportedCurrency value) @
  } ⍟ (1 = hitCount) @

  result
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
  result ← SelectionFailure ⟨"default_currency_unavailable", defaultResult.message⟩
  hasExplicit ← 0 < ≠ explicitCurrency

  {𝕊:
    result ↩ SelectionFailure ⟨"unsupported_selected_currency", "unsupported selected currency: " ∾ explicitCurrency⟩
    {𝕊: result ↩ SelectionSuccess ⟨explicitCurrency, "explicit_selection"⟩ } ⍟ (IsSupportedCurrency explicitCurrency) @
  } ⍟ hasExplicit @

  {𝕊:
    {𝕊: result ↩ SelectionSuccess ⟨defaultResult.currency, "ledger_default"⟩ } ⍟ (defaultResult.state ≡ "ok") @
  } ⍟ (¬ hasExplicit) @

  result
}

LineResult ← {𝕊 stateValue‿classificationValue‿rowIndex‿originalLine‿proposedLine‿currencyValue‿messageValue:
  {
    state ⇐ stateValue,
    classification ⇐ classificationValue,
    source_row ⇐ rowIndex,
    original_line ⇐ originalLine,
    proposed_line ⇐ proposedLine,
    currency ⇐ currencyValue,
    message ⇐ messageValue
  }
}

AuditLine ← {𝕊 fileName‿kind‿rowIndex‿line‿targetCurrency:
  result ← LineResult ⟨"ok", "ignored", rowIndex, line, line, "", ""⟩

  {𝕊:
    fields ← tab util.SplitKeepEmpty line
    minFields ← (kind ≡ "accounts") ⊑ 5‿1
    structurallyValid ← (minFields ≤ ≠ fields) ∧ ((kind ≢ "accounts") ∨ (0 < ≠ ⊑ fields))

    {𝕊:
      result ↩ LineResult ⟨"error", "invalid_structure", rowIndex, line, line, "", fileName ∾ " row " ∾ (•Fmt rowIndex) ∾ ": invalid source structure"⟩
    } ⍟ (¬ structurallyValid) @

    {𝕊:
      metaStart ← (kind ≡ "accounts") ⊑ 5‿1
      metadata ← metaStart ↓ fields
      currencyTokens ← ({ HasPrefix ⟨"currency=", 𝕩⟩ }¨ metadata) / metadata
      tokenCount ← ≠ currencyTokens

      {𝕊:
        result ↩ LineResult ⟨"ok", "missing", rowIndex, line, line ∾ tab ∾ "currency=" ∾ targetCurrency, targetCurrency, ""⟩
      } ⍟ (0 = tokenCount) @

      {𝕊:
        result ↩ LineResult ⟨"error", "duplicate", rowIndex, line, line, "", fileName ∾ " row " ∾ (•Fmt rowIndex) ∾ ": duplicate currency metadata"⟩
      } ⍟ (1 < tokenCount) @

      {𝕊:
        currencyValue ← 9 ↓ ⊑ currencyTokens
        result ↩ LineResult ⟨"error", "unknown", rowIndex, line, line, currencyValue, fileName ∾ " row " ∾ (•Fmt rowIndex) ∾ ": unsupported currency: " ∾ currencyValue⟩
        {𝕊:
          result ↩ LineResult ⟨"ok", "explicit", rowIndex, line, line, currencyValue, ""⟩
        } ⍟ (IsSupportedCurrency currencyValue) @
      } ⍟ (1 = tokenCount) @
    } ⍟ structurallyValid @
  } ⍟ (¬ IsIgnoredLine line) @

  result
}

AuditFile ← {𝕊 fileName‿kind‿lines‿targetCurrency:
  rows ← {𝕊 index:
    AuditLine ⟨fileName, kind, index, index ⊑ lines, targetCurrency⟩
  }¨ ↕ ≠ lines

  errorCount ← +´ { 𝕩.state ≢ "ok" }¨ rows
  missingCount ← +´ { 𝕩.classification ≡ "missing" }¨ rows
  explicitCount ← +´ { 𝕩.classification ≡ "explicit" }¨ rows
  ignoredCount ← +´ { 𝕩.classification ≡ "ignored" }¨ rows
  proposedLines ← empty
  {𝕊: proposedLines ↩ {𝕩.proposed_line}¨ rows } ⍟ (0 = errorCount) @
  stateValue ← (0 = errorCount) ⊑ "error"‿"ok"

  {
    state ⇐ stateValue,
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
  files ← empty

  {𝕊:
    files ↩ ⟨
      AuditFile ⟨"accounts.tsv", "accounts", accountsLines, targetCurrency⟩,
      AuditFile ⟨"journal.tsv", "journal", journalLines, targetCurrency⟩,
      AuditFile ⟨"plan.tsv", "journal", planLines, targetCurrency⟩,
      AuditFile ⟨"budget_alloc.tsv", "journal", budgetLines, targetCurrency⟩
    ⟩
  } ⍟ targetOk @

  fileErrorCount ← +´ { 𝕩.error_count }¨ files
  changedCount ← +´ { 𝕩.changed_count }¨ files
  overallOk ← (defaultResult.state ≡ "ok") ∧ targetOk ∧ (0 = fileErrorCount)
  stateValue ← overallOk ⊑ "error"‿"ok"
  messageValue ← ""
  {𝕊: messageValue ↩ "unsupported migration target: " ∾ targetCurrency ∾ "; M1.5 permits JPY only" } ⍟ (¬targetOk) @
  {𝕊: messageValue ↩ defaultResult.message } ⍟ (defaultResult.state ≢ "ok") @

  {
    state ⇐ stateValue,
    default_currency ⇐ defaultResult,
    migration_target ⇐ targetCurrency,
    files ⇐ files,
    changed_count ⇐ changedCount,
    error_count ⇐ fileErrorCount + (¬targetOk) + (defaultResult.state ≢ "ok"),
    message ⇐ messageValue
  }
}

{
  supported_currencies ⇐ currencyCodes,
  Policy ⇐ Policy,
  IsSupportedCurrency ⇐ IsSupportedCurrency,
  ResolveDefault ⇐ ResolveDefault,
  ResolveSelection ⇐ ResolveSelection,
  AuditLine ⇐ AuditLine,
  AuditFile ⇐ AuditFile,
  Build ⇐ Build
}
