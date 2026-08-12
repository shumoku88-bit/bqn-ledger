# Canonical currency registry plus narrow editor default/selection admission.
# DEFAULT_CURRENCY selects an editor view; it never supplies source currency.

io ← •Import "source_io.bqn"
rows ← •Import "config_rows.bqn"
registryBuilder ← •Import "../ledger/currency_registry.bqn"
Failure ← {𝕊 code‿message:
  {state⇐"error",currency⇐"",provenance⇐"",code⇐code,message⇐message}
}
Success ← {𝕊 currency‿provenance:
  {state⇐"ok",currency⇐currency,provenance⇐provenance,code⇐"",message⇐""}
}
Load ← {𝕊:
  built ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
  {𝕊:•Out "CURRENCY REGISTRY ERROR: "∾built.message ⋄ •Exit 1}⍟(built.state≢"ok") @
  registry ← built.registry
  ResolveDefault ← {𝕊 configLines:
    matches ← (rows.Build configLines).Matches "DEFAULT_CURRENCY"
    matchClass ← 2⌊≠matches
    matchClass◶⟨
      {𝕊:Failure ⟨"missing_default_currency","missing ledger config key: DEFAULT_CURRENCY"⟩},
      {𝕊:
        value ← 1⊑⊑matches
        valuePresent ← 0<≠value
        valueClass ← valuePresent + valuePresent∧registry.IsSupportedCurrency value
        valueClass◶⟨
          {𝕊:Failure ⟨"empty_default_currency","empty ledger config value: DEFAULT_CURRENCY"⟩},
          {𝕊:Failure ⟨"unsupported_default_currency","unsupported default currency: "∾value⟩},
          {𝕊:Success ⟨value,"ledger_config"⟩}
        ⟩ @
      },
      {𝕊:Failure ⟨"duplicate_default_currency","duplicate ledger config key: DEFAULT_CURRENCY"⟩}
    ⟩ @
  }
  ResolveSelection ← {𝕊 defaultResult‿explicitCurrency:
    hasExplicit ← 0<≠explicitCurrency
    hasExplicit◶⟨
      {𝕊:
        (defaultResult.state≡"ok")◶⟨
          {𝕊:Failure ⟨"default_currency_unavailable",defaultResult.message⟩},
          {𝕊:Success ⟨defaultResult.currency,"ledger_default"⟩}
        ⟩ @
      },
      {𝕊:
        (registry.IsSupportedCurrency explicitCurrency)◶⟨
          {𝕊:Failure ⟨"unsupported_selected_currency","unsupported selected currency: "∾explicitCurrency⟩},
          {𝕊:Success ⟨explicitCurrency,"explicit_selection"⟩}
        ⟩ @
      }
    ⟩ @
  }
  {
    registry⇐registry,Policy⇐registry.Policy,IsSupportedCurrency⇐registry.IsSupportedCurrency,
    ResolveDefault⇐ResolveDefault,ResolveSelection⇐ResolveSelection
  }
}

{Load⇐Load}
