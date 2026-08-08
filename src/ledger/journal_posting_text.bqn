# Pure canonical posting-line text split.
#
# One ordinary space remains legal inside an Account name. A tab or two
# consecutive spaces separates the Account from an explicit Amount. Trailing
# semicolon comments are outside the posting body, matching the canonical
# Journal grammar.

parse ← •Import "../text/parse.bqn"

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
  index ← ≠text
  {𝕊:index↩⊑mask/↕≠text}⍟(∨´0∾mask) @
  index↑text
}

Split ← {𝕊 line:
  body ← Trim BeforeComment TrimLeft line
  next ← 1↓body∾" "
  separatorMask ← (tab=body) ∨ ((space=body) ∧ space=next)
  hasSeparator ← ∨´0∾separatorMask
  account ← body
  amount ← ""
  {𝕊:
    i ← ⊑separatorMask/↕≠body
    account↩Trim i↑body
    amount↩Trim i↓body
  }⍟hasSeparator @
  normalizedAmount ← {(𝕩=tab)⊑𝕩‿space}¨amount
  words ← space parse.Split normalizedAmount
  elided ← 0=≠amount
  explicit ← 2=≠words
  valid ← (0<≠account) ∧ (elided ∨ explicit)
  {account⇐account,amount⇐amount,words⇐words,elided⇐elided,explicit⇐explicit,valid⇐valid}
}

{Split⇐Split}
