# Strict pure admission for canonical accounts.journal.
#
# Canonical ownership is intentionally narrow: Account identity, accounting
# type, optional default Commodity, declaration order, and source line. Legacy
# Household policy columns are published empty only to preserve the existing
# aligned Account carrier shape; their meaning belongs to household.toml.

parse ← •Import "../text/parse.bqn"

lf ← @+10
cr ← @+13
space ← @+32
tab ← @+9
semicolon ← ⊑ ";"
colon ← ⊑ ":"
empty ← ⟨⟩
upper ← "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
lower ← "abcdefghijklmnopqrstuvwxyz"
accountTypes ← ⟨"asset","liability","equity","income","expense","budget"⟩
canonicalTypes ← ⟨"Asset","Liability","Equity","Income","Expense","Budget"⟩

IndexOf ← {𝕊 item‿items: ⊑ items ⊐ ⟨item⟩ }
IsWhitespace ← {𝕊 c: (c=space) ∨ c=tab }
TrimLeft ← {𝕊 xs:
  prefix ← ∧` IsWhitespace¨xs
  (+´prefix) ↓ xs
}
TrimRight ← {𝕊 xs: ⌽ TrimLeft ⌽ xs }
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
LowerChar ← {𝕊 c:
  i ← IndexOf ⟨c,upper⟩
  result ← c
  {𝕊: result↩i⊑lower}⍟(i<≠upper) @
  result
}
Lower ← { LowerChar¨𝕩 }
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
    role⇐empty,type⇐empty,budget⇐empty,budget_group⇐empty,spend_class⇐empty,
    kind⇐empty,envelope_role⇐empty,metadata⇐empty,source_row⇐empty
  }
}
TypeValue ← {𝕊 value:
  normalized ← Lower Trim value
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
  diagnostics ← empty
  rows ← empty

  active ← 0
  activeValid ← 0
  activeHasError ← 0
  activeKey ← ""
  activeType ← ""
  activeRole ← ""
  activeCommodity ← ""
  activeLine ← 0
  typeCount ← 0
  commodityCount ← 0

  AddActiveError ← {𝕊 diagnostic:
    diagnostics∾↩⟨diagnostic⟩
    activeHasError↩1
  }

  Finalize ← {𝕊:
    {𝕊:
      {𝕊: AddActiveError Diagnostic ⟨"account_type_missing",activeLine,"account declaration must contain exactly one type or role"⟩}⍟(0=typeCount) @
      {𝕊:
        metadata ← ⟨{key⇐"type",value⇐activeType}⟩
        {𝕊: metadata∾↩⟨{key⇐"commodity",value⇐activeCommodity}⟩}⍟(0<≠activeCommodity) @
        rows∾↩⟨{
          key⇐activeKey,
          currency⇐activeCommodity,
          default_commodity⇐activeCommodity,
          role⇐activeRole,
          type⇐activeType,
          budget⇐"",budget_group⇐"",spend_class⇐"",kind⇐"",envelope_role⇐"",
          metadata⇐metadata,
          source_row⇐activeLine
        }⟩
      }⍟((¬activeHasError) ∧ 1=typeCount ∧ commodityCount≤1) @
    }⍟(active ∧ activeValid) @
    active↩0
    activeValid↩0
    activeHasError↩0
    activeKey↩""
    activeType↩""
    activeRole↩""
    activeCommodity↩""
    activeLine↩0
    typeCount↩0
    commodityCount↩0
  }

  StartAccount ← {𝕊 line‿row:
    body ← Trim BeforeComment TrimLeft line
    name ← Trim (≠"account")↓body
    active↩1
    activeValid↩1
    activeLine↩row
    {𝕊: AddActiveError Diagnostic ⟨"account_key_empty",row,"account directive requires a nonempty Account identity"⟩ ⋄ activeValid↩0}⍟(0=≠name) @
    {𝕊: AddActiveError Diagnostic ⟨"account_key_control_invalid",row,"Account identity must not contain control whitespace"⟩ ⋄ activeValid↩0}⍟(∨´0∾tab=name) @
    activeKey↩name
  }

  ParseMetadata ← {𝕊 line‿row:
    comment ← IsComment line
    text ← DropMetadataPrefix Trim line
    p ← IndexOf ⟨colon,text⟩
    hasColon ← p<≠text
    {𝕊:
      {𝕊: AddActiveError Diagnostic ⟨"account_metadata_shape_invalid",row,"account metadata must use key: value shape"⟩}⍟(¬comment) @
    }⍟(¬hasColon) @
    {𝕊:
      key ← Lower Trim p↑text
      value ← Trim (p+1)↓text
      supported ← (key≡"type") ∨ (key≡"role") ∨ key≡"commodity"
      {𝕊: AddActiveError Diagnostic ⟨"account_metadata_unsupported",row,"accounts.journal admits only type, role, and commodity metadata"⟩}⍟(¬supported) @
      {𝕊:
        typeCount+↩1
        {𝕊: AddActiveError Diagnostic ⟨"account_type_duplicate",row,"account declaration must contain exactly one type or role"⟩}⍟(1<typeCount) @
        parsedType ← TypeValue value
        {𝕊: AddActiveError Diagnostic ⟨"account_type_invalid",row,"account type must be Asset, Liability, Equity, Income, Expense, or Budget"⟩}⍟(¬parsedType.ok) @
        {𝕊: activeType↩parsedType.type ⋄ activeRole↩parsedType.role}⍟(parsedType.ok ∧ 1=typeCount) @
      }⍟((key≡"type") ∨ key≡"role") @
      {𝕊:
        commodityCount+↩1
        {𝕊: AddActiveError Diagnostic ⟨"account_commodity_duplicate",row,"account declaration may contain at most one default Commodity"⟩}⍟(1<commodityCount) @
        validCommodity ← CommodityValid value
        {𝕊: AddActiveError Diagnostic ⟨"account_commodity_invalid",row,"default Commodity must be nonempty and contain no whitespace"⟩}⍟(¬validCommodity) @
        {𝕊: activeCommodity↩value}⍟(validCommodity ∧ 1=commodityCount) @
      }⍟(key≡"commodity") @
    }⍟hasColon @
  }

  {𝕊 i:
    line ← i⊑lines
    row ← i+1
    text ← Trim line
    blank ← 0=≠text
    indented ← IsIndented line
    comment ← IsComment line

    {𝕊: Finalize @}⍟blank @
    {𝕊:
      {𝕊: ParseMetadata ⟨line,row⟩}⍟active @
      {𝕊: diagnostics∾↩⟨Diagnostic ⟨"account_indented_line_unexpected",row,"indented source is valid only inside an account declaration"⟩⟩}⍟((¬active) ∧ ¬comment) @
    }⍟((¬blank) ∧ indented) @
    {𝕊:
      isAccount ← StartsDirective ⟨"account",line⟩
      {𝕊: Finalize @ ⋄ StartAccount ⟨line,row⟩}⍟isAccount @
      {𝕊: Finalize @ ⋄ diagnostics∾↩⟨Diagnostic ⟨"account_block_unsupported",row,"accounts.journal may contain only account declarations and comments"⟩⟩}⍟(¬isAccount) @
    }⍟((¬blank) ∧ (¬indented) ∧ (¬comment)) @
  }¨↕≠lines
  Finalize @

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
      budget⇐{𝕩.budget}¨rows,
      budget_group⇐{𝕩.budget_group}¨rows,
      spend_class⇐{𝕩.spend_class}¨rows,
      kind⇐{𝕩.kind}¨rows,
      envelope_role⇐{𝕩.envelope_role}¨rows,
      metadata⇐{𝕩.metadata}¨rows,
      source_row⇐{𝕩.source_row}¨rows
    }
  }⍟(¬hasError) @
  {state⇐hasError⊑"ok"‿"error",source_name⇐"accounts.journal",accounts⇐accounts,diagnostics⇐diagnostics}
}

{Admit⇐Admit}
