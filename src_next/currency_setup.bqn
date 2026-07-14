# currency_setup.bqn
# Core policy and registry for explicit ledger default currency and selection.
#
# Important boundary:
# - DEFAULT_CURRENCY selects an initial view only.
# - It never supplies missing source currency.
# - Built-in currency policy owns admission and lexical precision metadata.
# - This module reads the registry file on import but performs no writes to source TSVs.

util ← •Import "util.bqn"
loader ← •Import "loader.bqn"
registry_core ← •Import "currency_registry.bqn"

tab ← @+9
defaultKey ← "DEFAULT_CURRENCY"

# This is the sole I/O boundary for the repository currency registry. All
# validation and policy lookup below consume the resulting immutable registry.
registryResult ← registry_core.Build loader.ReadLines "config/currencies.tsv"
{𝕊:
  •Out "CURRENCY REGISTRY ERROR: " ∾ registryResult.message
  •Exit 1
}⍟(registryResult.state ≢ "ok") @
registry ← registryResult.registry
currencyCodes ← registry.codes
Policy ← registry.Policy
IsSupportedCurrency ← registry.IsSupportedCurrency

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

AuditLine ← {𝕊 fileName‿kind‿rowIndex‿line:
  result ← {
    state ⇐ "ok",
    classification ⇐ "ignored",
    source_row ⇐ rowIndex,
    original_line ⇐ line,
    message ⇐ ""
  }

  {𝕊:
    fields ← tab util.SplitKeepEmpty line
    minFields ← (kind ≡ "accounts") ⊑ 5‿1
    structurallyValid ← (minFields ≤ ≠ fields) ∧ ((kind ≢ "accounts") ∨ (0 < ≠ ⊑ fields))

    {𝕊:
      result ↩ {
        state ⇐ "error",
        classification ⇐ "invalid_structure",
        source_row ⇐ rowIndex,
        original_line ⇐ line,
        message ⇐ fileName ∾ " row " ∾ (•Fmt rowIndex) ∾ ": invalid source structure"
      }
    } ⍟ (¬ structurallyValid) @

    {𝕊:
      metaStart ← (kind ≡ "accounts") ⊑ 5‿1
      metadata ← metaStart ↓ fields
      currencyTokens ← ({ HasPrefix ⟨"currency=", 𝕩⟩ }¨ metadata) / metadata
      tokenCount ← ≠ currencyTokens

      {𝕊:
        result ↩ {
          state ⇐ "ok",
          classification ⇐ "missing",
          source_row ⇐ rowIndex,
          original_line ⇐ line,
          message ⇐ ""
        }
      } ⍟ (0 = tokenCount) @

      {𝕊:
        result ↩ {
          state ⇐ "error",
          classification ⇐ "duplicate",
          source_row ⇐ rowIndex,
          original_line ⇐ line,
          message ⇐ fileName ∾ " row " ∾ (•Fmt rowIndex) ∾ ": duplicate currency metadata"
        }
      } ⍟ (1 < tokenCount) @

      {𝕊:
        currencyValue ← 9 ↓ ⊑ currencyTokens
        result ↩ {
          state ⇐ "error",
          classification ⇐ "unknown",
          source_row ⇐ rowIndex,
          original_line ⇐ line,
          message ⇐ fileName ∾ " row " ∾ (•Fmt rowIndex) ∾ ": unsupported currency: " ∾ currencyValue
        }
        {𝕊:
          result ↩ {
            state ⇐ "ok",
            classification ⇐ "explicit",
            source_row ⇐ rowIndex,
            original_line ⇐ line,
            message ⇐ ""
          }
        } ⍟ (IsSupportedCurrency currencyValue) @
      } ⍟ (1 = tokenCount) @
    } ⍟ structurallyValid @
  } ⍟ (¬ IsIgnoredLine line) @

  result
}

AuditFile ← {𝕊 fileName‿kind‿lines:
  rows ← {𝕊 index:
    AuditLine ⟨fileName, kind, index, index ⊑ lines⟩
  }¨ ↕ ≠ lines

  errorCount ← +´ { 𝕩.state ≢ "ok" }¨ rows
  stateValue ← (0 = errorCount) ⊑ "error"‿"ok"

  {
    state ⇐ stateValue,
    rows ⇐ rows
  }
}

{
  supported_currencies ⇐ currencyCodes,
  Policy ⇐ Policy,
  IsSupportedCurrency ⇐ IsSupportedCurrency,
  ResolveDefault ⇐ ResolveDefault,
  ResolveSelection ⇐ ResolveSelection,
  AuditLine ⇐ AuditLine,
  AuditFile ⇐ AuditFile
}
