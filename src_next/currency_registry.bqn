# currency_registry.bqn
# Pure parser and validator for the repository-owned currency registry.
# I/O is intentionally owned by currency_setup.bqn.

util ← •Import "util.bqn"

tab ← @+9
empty ← ⟨⟩

IsIgnored ← {𝕊 line:
  (0=≠line) ∨ ((0<≠line) ∧ (((⊑line)='#') ∨ ((⊑line)=⊑"\\")))
}

IsFractionDigits ← {𝕊 text:
  digits ← "0123456789"
  nonnegative ← (0<≠text) ∧ (∧´ text∊digits)
  (text≡"-1") ∨ nonnegative
}

ParseLine ← {𝕊 line:
  fields ← tab util.SplitKeepEmpty line
  currency ← (0<≠fields) ⊑ ⟨"", 0⊑fields⟩
  fraction ← (1<≠fields) ⊑ ⟨"", 1⊑fields⟩
  symbol ← (2<≠fields) ⊑ ⟨"", 2⊑fields⟩
  {currency⇐currency, fraction_text⇐fraction, symbol⇐symbol, field_count⇐≠fields}
}

Failure ← {𝕊 code‿message:
  {state⇐"error", code⇐code, message⇐message, registry⇐{codes⇐⟨⟩, Policy⇐{𝕊 c:{state⇐"error",currency⇐c,max_fraction_digits⇐¯1,symbol⇐"",code⇐"unsupported_currency",message⇐"unsupported currency: "∾c}}, IsSupportedCurrency⇐{𝕊:0}}}
}

Build ← {𝕊 lines:
  data ← (¬IsIgnored¨lines)/lines
  parsed ← ParseLine¨data
  result ← Failure ⟨"currency_registry_empty", "currency registry is empty"⟩
  {𝕊:
    codes ← <¨ {𝕩.currency}¨parsed
    fractions ← {𝕩.fraction_text}¨parsed
    fieldOk ← ∧´ {𝕩.field_count=3}¨parsed
    codeOk ← ∧´ {0<≠>𝕩}¨codes
    fractionOk ← ∧´ IsFractionDigits¨fractions
    sorted ← (⍋ codes) ⊏ codes
    duplicate ← 0 < +´ ((1↓sorted) ≡¨ (¯1↓sorted))
    {𝕊: result ↩ Failure ⟨"currency_registry_row_invalid", "currency registry rows require currency, max_fraction_digits, and symbol"⟩}⍟(¬fieldOk) @
    {𝕊: result ↩ Failure ⟨"currency_registry_currency_empty", "currency registry contains an empty currency code"⟩}⍟(fieldOk ∧ ¬codeOk) @
    {𝕊: result ↩ Failure ⟨"currency_registry_fraction_digits_invalid", "currency registry contains invalid max_fraction_digits"⟩}⍟(fieldOk ∧ codeOk ∧ ¬fractionOk) @
    {𝕊: result ↩ Failure ⟨"currency_registry_currency_duplicate", "currency registry contains duplicate currency code"⟩}⍟(fieldOk ∧ codeOk ∧ fractionOk ∧ duplicate) @
    {𝕊:
      maxes ← •BQN¨fractions
      symbols ← <¨ {𝕩.symbol}¨parsed
      Policy ← {𝕊 requested:
        idx ← ⊑codes⊐⟨<requested⟩
        result ← {state⇐"error",currency⇐requested,max_fraction_digits⇐¯1,symbol⇐"",code⇐"unsupported_currency",message⇐"unsupported currency: "∾requested}
        {𝕊:
          result ↩ {state⇐"ok",currency⇐>idx⊑codes,max_fraction_digits⇐idx⊑maxes,symbol⇐>idx⊑symbols,code⇐"",message⇐""}
        }⍟(idx<≠codes) @
        result
      }
      IsSupportedCurrency ← {𝕊 requested: (Policy requested).state≡"ok"}
      result ↩ {state⇐"ok",code⇐"",message⇐"",registry⇐{codes⇐>¨codes,Policy⇐Policy,IsSupportedCurrency⇐IsSupportedCurrency}}
    }⍟(fieldOk ∧ codeOk ∧ fractionOk ∧ ¬duplicate) @
  }⍟(0<≠data) @
  result
}

{Build⇐Build}
