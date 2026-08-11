# Pure canonical posting-line text split.
#
# One ordinary space remains legal inside an Account name. A tab or two
# consecutive spaces separates the Account from an explicit Amount. Trailing
# semicolon comments are outside the posting body, matching the canonical
# Journal grammar.
#
# Retained legacy BQN fixtures used three single-space tokens. When no canonical
# separator exists, that shape is admitted only if token 2 is an exact number.
# This keeps the compatibility surface finite without making every single space
# an Account/Amount boundary.

parse ← •Import "../text/parse.bqn"
decimal ← •Import "exact_decimal.bqn"

space ← @+32
tab ← @+9
semicolon ← ⊑ ";"

IsWhitespace ← {𝕊 c: (c=space) ∨ c=tab }
TrimLeft ← {𝕊 xs:
  prefix ← ∧` IsWhitespace¨xs
  (+´prefix)↓xs
}
TrimRight ← {𝕊 xs:
  reversed ← ⌽xs
  trimmed ← TrimLeft reversed
  ⌽trimmed
}
Trim ← { TrimRight TrimLeft 𝕩 }
BeforeComment ← {𝕊 text:
  mask ← semicolon=text
  commentCoordinates ← mask/↕≠text
  commentStart ← ⊑(commentCoordinates∾⟨≠text⟩)
  commentStart↑text
}

Split ← {𝕊 line:
  body ← Trim BeforeComment TrimLeft line
  next ← 1↓body∾" "
  separatorMask ← (tab=body) ∨ ((space=body) ∧ space=next)
  separatorCoordinates ← separatorMask/↕≠body
  separatorIndex ← ⊑(separatorCoordinates∾⟨≠body⟩)
  hasSeparator ← separatorIndex<≠body
  account ← hasSeparator⊑⟨body,Trim separatorIndex↑body⟩
  amount ← hasSeparator⊑⟨"",Trim separatorIndex↓body⟩

  legacyWords ← space parse.Split body
  {𝕊:
    candidate ← 1⊑legacyWords
    negative ← '-'=⊑(candidate∾"0")
    parsed ← decimal.Parse negative↓candidate
    legacyExplicit ← parsed.state≡"ok"
    {𝕊:
      account↩0⊑legacyWords
      amount↩(1⊑legacyWords)∾" "∾2⊑legacyWords
    }⍟legacyExplicit @
  }⍟((¬hasSeparator) ∧ 3=≠legacyWords) @

  normalizedAmount ← {(𝕩=tab)⊑𝕩‿space}¨amount
  words ← space parse.Split normalizedAmount
  elided ← 0=≠amount
  explicit ← 2=≠words
  valid ← (0<≠account) ∧ (elided ∨ explicit)
  {account⇐account,amount⇐amount,words⇐words,elided⇐elided,explicit⇐explicit,valid⇐valid}
}

{Split⇐Split}
