# Strict pure admission for canonical accounts.journal.
#
# Canonical ownership is intentionally narrow: Account identity, accounting
# type, optional default Commodity, declaration order, and source line.
# Household classification belongs to household.toml and is not published in
# the canonical Account carrier.

parse ← •Import "../text/parse.bqn"

lf ← @+10
cr ← @+13
space ← @+32
tab ← @+9
semicolon ← ⊑ ";"
colon ← ⊑ ":"
empty ← ⟨⟩
upperAlphabet ← "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
lowerAlphabet ← "abcdefghijklmnopqrstuvwxyz"
accountTypes ← ⟨"asset","liability","equity","income","expense","budget"⟩
canonicalTypes ← ⟨"Asset","Liability","Equity","Income","Expense","Budget"⟩

IndexOf ← {𝕊 item‿items: ⊑ items ⊐ ⟨item⟩ }
IsWhitespace ← {𝕊 c: (c=space) ∨ c=tab }
TrimLeft ← {𝕊 xs:
  prefix ← ∧` IsWhitespace¨xs
  (+´prefix) ↓ xs
}
TrimRight ← {𝕊 xs:
  reversed ← ⌽xs
  trimmed ← TrimLeft reversed
  ⌽trimmed
}
Trim ← { TrimRight TrimLeft 𝕩 }
IsComment ← {𝕊 line:
  text ← TrimLeft line
  (0<≠text) ∧ semicolon=⊑(text∾";")
}
IsIndented ← {𝕊 line: (0<≠line) ∧ IsWhitespace ⊑(line∾" ") }
StartsDirective ← {𝕊 keyword‿line:
  text ← TrimLeft line
  n ← ≠keyword
  remainder ← n↓text
  enough ← n≤≠text
  boundary ← (0=≠remainder) ∨ IsWhitespace ⊑(remainder∾" ")
  enough ∧ (keyword≡n↑text) ∧ boundary
}
BeforeComment ← {𝕊 text: (IndexOf ⟨semicolon,text⟩) ↑ text }
AsciiLowerChar ← {𝕊 c:
  i ← IndexOf ⟨c,upperAlphabet⟩
  result ← c
  {𝕊: result↩i⊑lowerAlphabet}⍟(i<≠upperAlphabet) @
  result
}
AsciiLower ← { AsciiLowerChar¨𝕩 }
DropMetadataPrefix ← {𝕊 text:
  PrefixChar ← {𝕊 c: (c=semicolon) ∨ IsWhitespace c }
  prefix ← ∧` PrefixChar¨text
  (+´prefix)↓text
}

Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {severity⇐"error",stage⇐"ledger_account_journal_admission",code⇐codeText,line⇐lineNumber,message⇐messageText}
}
EmptyAccounts ← {𝕊:
  {
    count⇐0,index⇐empty,key⇐empty,currency⇐empty,default_commodity⇐empty,
    role⇐empty,type⇐empty,metadata⇐empty,source_row⇐empty
  }
}
TypeValue ← {𝕊 value:
  normalized ← AsciiLower Trim value
  i ← IndexOf ⟨normalized,accountTypes⟩
  ok ← i<≠accountTypes
  canonical ← ""
  role ← ""
  {𝕊: canonical↩i⊑canonicalTypes ⋄ role↩i⊑accountTypes}⍟ok @
  {ok⇐ok,type⇐canonical,role⇐role}
}
CommodityValid ← {𝕊 value:
  (0<≠value) ∧ ¬∨´0∾IsWhitespace¨value
}

Admit ← {𝕊 raw:
  normalized ← (cr≠raw)/raw
  lines ← lf parse.SplitKeepEmpty normalized
  indices ← ↕≠lines

  # Make the source grammar visible as one aligned line classification. Blank lines and
  # top-level non-comment lines start new segments; comments never terminate an Account block.
  trimmed ← Trim¨lines
  blank ← 0=≠¨trimmed
  indented ← IsIndented¨lines
  comment ← IsComment¨lines
  topLevel ← (¬blank) ∧ (¬indented) ∧ ¬comment
  accountStart ← topLevel ∧ {StartsDirective ⟨"account",𝕩⟩}¨lines
  segmentIds ← +`(blank ∨ topLevel)
  segments ← segmentIds⊔indices

  ParseAccountSegment ← {𝕊 segment:
    diagnostics ← empty
    hasError ← 0
    headerValid ← 1
    headerIndex ← ⊑segment
    headerRow ← headerIndex+1
    headerLine ← headerIndex⊑lines
    body ← Trim BeforeComment TrimLeft headerLine
    name ← Trim (≠"account")↓body

    AddError ← {𝕊 diagnostic:
      diagnostics∾↩⟨diagnostic⟩
      hasError↩1
    }

    {𝕊: AddError Diagnostic ⟨"account_key_empty",headerRow,"account directive requires a nonempty Account identity"⟩ ⋄ headerValid↩0}⍟(0=≠name) @
    {𝕊: AddError Diagnostic ⟨"account_key_control_invalid",headerRow,"Account identity must not contain control whitespace"⟩ ⋄ headerValid↩0}⍟(∨´0∾tab=name) @

    accountType ← ""
    accountRole ← ""
    accountCommodity ← ""
    typeCount ← 0
    commodityCount ← 0

    ParseMetadata ← {𝕊 sourceIndex:
      line ← sourceIndex⊑lines
      row ← sourceIndex+1
      isComment ← sourceIndex⊑comment
      text ← DropMetadataPrefix Trim line
      p ← IndexOf ⟨colon,text⟩
      hasColon ← p<≠text
      {𝕊:
        {𝕊: AddError Diagnostic ⟨"account_metadata_shape_invalid",row,"account metadata must use key: value shape"⟩}⍟(¬isComment) @
      }⍟(¬hasColon) @
      {𝕊:
        key ← AsciiLower Trim p↑text
        value ← Trim (p+1)↓text
        supported ← (key≡"type") ∨ (key≡"role") ∨ key≡"commodity"
        {𝕊: AddError Diagnostic ⟨"account_metadata_unsupported",row,"accounts.journal admits only type, role, and commodity metadata"⟩}⍟(¬supported) @
        {𝕊:
          typeCount+↩1
          {𝕊: AddError Diagnostic ⟨"account_type_duplicate",row,"account declaration must contain exactly one type or role"⟩}⍟(1<typeCount) @
          parsedType ← TypeValue value
          {𝕊: AddError Diagnostic ⟨"account_type_invalid",row,"account type must be Asset, Liability, Equity, Income, Expense, or Budget"⟩}⍟(¬parsedType.ok) @
          {𝕊: accountType↩parsedType.type ⋄ accountRole↩parsedType.role}⍟(parsedType.ok ∧ 1=typeCount) @
        }⍟((key≡"type") ∨ key≡"role") @
        {𝕊:
          commodityCount+↩1
          {𝕊: AddError Diagnostic ⟨"account_commodity_duplicate",row,"account declaration may contain at most one default Commodity"⟩}⍟(1<commodityCount) @
          validCommodity ← CommodityValid value
          {𝕊: AddError Diagnostic ⟨"account_commodity_invalid",row,"default Commodity must be nonempty and contain no whitespace"⟩}⍟(¬validCommodity) @
          {𝕊: accountCommodity↩value}⍟(validCommodity ∧ 1=commodityCount) @
        }⍟(key≡"commodity") @
      }⍟hasColon @
    }

    metadataIndices ← (segment⊏indented)/segment
    ParseMetadata¨metadataIndices
    {𝕊: AddError Diagnostic ⟨"account_type_missing",headerRow,"account declaration must contain exactly one type or role"⟩}⍟(headerValid ∧ 0=typeCount) @

    item ← @
    {𝕊:
      metadata ← ⟨{key⇐"type",value⇐accountType}⟩
      {𝕊: metadata∾↩⟨{key⇐"commodity",value⇐accountCommodity}⟩}⍟(0<≠accountCommodity) @
      item↩{
        key⇐name,
        currency⇐accountCommodity,
        default_commodity⇐accountCommodity,
        role⇐accountRole,
        type⇐accountType,
        metadata⇐metadata,
        source_row⇐headerRow
      }
    }⍟(headerValid ∧ ¬hasError ∧ 1=typeCount ∧ commodityCount≤1) @
    {diagnostics⇐diagnostics,item⇐item}
  }

  ParseOutsideSegment ← {𝕊 segment:
    diagnostics ← empty
    {𝕊:
      first ← ⊑segment
      {𝕊: diagnostics∾↩⟨Diagnostic ⟨"account_block_unsupported",first+1,"accounts.journal may contain only account declarations and comments"⟩⟩}⍟(first⊑topLevel) @
      stray ← ((segment⊏indented) ∧ ¬segment⊏comment)/segment
      diagnostics∾↩{𝕊 sourceIndex:
        Diagnostic ⟨"account_indented_line_unexpected",sourceIndex+1,"indented source is valid only inside an account declaration"⟩
      }¨stray
    }⍟(0<≠segment) @
    {diagnostics⇐diagnostics,item⇐@}
  }

  ParseSegment ← {𝕊 segment:
    result ← {diagnostics⇐empty,item⇐@}
    {𝕊:
      first ← ⊑segment
      isAccount ← first⊑accountStart
      {𝕊: result↩ParseAccountSegment segment}⍟isAccount @
      {𝕊: result↩ParseOutsideSegment segment}⍟(¬isAccount) @
    }⍟(0<≠segment) @
    result
  }

  parsed ← ParseSegment¨segments
  diagnostics ← ∾{𝕩.diagnostics}¨parsed
  items ← {𝕩.item}¨parsed
  rows ← ({𝕩≢@}¨items)/items

  keys ← {𝕩.key}¨rows
  duplicate ← (≠keys)≠≠⍷keys
  diagnostics∾↩duplicate/⟨Diagnostic ⟨"account_key_duplicate",0,"Account identities must be unique"⟩⟩
  hasError ← 0<≠diagnostics
  accounts ← EmptyAccounts @
  {𝕊:
    n ← ≠rows
    accounts↩{
      count⇐n,index⇐↕n,
      key⇐{𝕩.key}¨rows,
      currency⇐{𝕩.currency}¨rows,
      default_commodity⇐{𝕩.default_commodity}¨rows,
      role⇐{𝕩.role}¨rows,
      type⇐{𝕩.type}¨rows,
      metadata⇐{𝕩.metadata}¨rows,
      source_row⇐{𝕩.source_row}¨rows
    }
  }⍟(¬hasError) @
  {state⇐hasError⊑"ok"‿"error",source_name⇐"accounts.journal",accounts⇐accounts,diagnostics⇐diagnostics}
}

{Admit⇐Admit}
