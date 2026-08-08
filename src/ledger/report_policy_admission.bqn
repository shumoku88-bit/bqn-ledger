# Strict BQN-native admission for canonical report.toml.
#
# This owner admits only Report query defaults and presentation policy. Physical
# source basenames, Household classification, Envelope membership, writer
# authority, clocks, and legacy manifest rows are deliberately outside it.

date ← •Import "date_ordinal.bqn"

lf ← @+10 ⋄ cr ← @+13 ⋄ space ← @+32 ⋄ tab ← @+9 ⋄ quote ← @+34 ⋄ hash ← ⊑"#"
empty ← ⟨⟩
digits ← "0123456789"

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IsWhitespace ← {𝕊 c: (c=space) ∨ c=tab}
TrimLeft ← {𝕊 xs: prefix ← ∧`IsWhitespace¨xs ⋄ (+´prefix)↓xs}
TrimRight ← {𝕊 xs: ⌽TrimLeft⌽xs}
Trim ← {TrimRight TrimLeft 𝕩}
SplitKeepEmpty ← {𝕊 sep‿text: groups ← (+`sep=text)⊔text ⋄ {(sep≠𝕩)/𝕩}¨groups}
FirstOrSpace ← {𝕊 text: ⊑text∾⟨space⟩}
IsDigits ← {𝕊 text: (0<≠text) ∧ ∧´text∊digits}
ToNum ← {𝕊 text: +´(text-⊑"0")×10⋆⌽↕≠text}

Diagnostic ← {𝕊 code‿line‿message:{severity⇐"error",stage⇐"ledger_report_policy_admission",code⇐code,line⇐line,message⇐message}}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyBlock ← {𝕊 kind‿line:{kind⇐kind,line⇐line,pairs⇐empty}}

ParseString ← {𝕊 text:
  t ← Trim text ⋄ diagnostics ← empty ⋄ value ← ""
  enclosed ← (2≤≠t) ∧ (quote=FirstOrSpace t) ∧ quote=FirstOrSpace⌽t
  diagnostics∾↩AddIf ⟨¬enclosed,Diagnostic ⟨"report_policy_string_invalid",0,"Report policy string value must be quoted"⟩⟩
  {𝕊:value↩¯1↓1↓t}⍟enclosed @
  diagnostics∾↩AddIf ⟨enclosed ∧ ∨´0∾quote=value,Diagnostic ⟨"report_policy_string_escape_unsupported",0,"Embedded quotes are not admitted"⟩⟩
  {ok⇐0=≠diagnostics,value⇐(0=≠diagnostics)/value,diagnostics⇐diagnostics}
}
AtLine ← {𝕊 parsed‿lineNumber:{𝕊 d:{severity⇐d.severity,stage⇐d.stage,code⇐d.code,line⇐lineNumber,message⇐d.message}}¨parsed.diagnostics}
PairValue ← {𝕊 block‿key:
  matches ← ({𝕩.key≡key}¨block.pairs)/block.pairs
  result ← {found⇐0,text⇐"",line⇐block.line}
  {𝕊:p←⊑matches ⋄ result↩{found⇐1,text⇐p.text,line⇐p.line}}⍟(1=≠matches) @
  result
}

Admit ← {𝕊 raw:
  lines ← SplitKeepEmpty ⟨lf,(cr≠raw)/raw⟩
  diagnostics ← empty ⋄ blocks ← empty ⋄ active ← 0 ⋄ current ← EmptyBlock ⟨"",0⟩
  knownSections ← ⟨
    "presentation.amounts","reports.trial-balance","reports.balance-sheet",
    "reports.profit-and-loss","reports.daily-flow","reports.monthly-accounts",
    "reports.recent-transactions"
  ⟩
  Finalize ← {𝕊:
    {𝕊:blocks∾↩⟨current⟩}⍟active @
    active↩0 ⋄ current↩EmptyBlock ⟨"",0⟩
  }
  {𝕊 i:
    text ← Trim i⊑lines ⋄ row ← i+1
    ignored ← (0=≠text) ∨ hash=FirstOrSpace text
    {𝕊:
      header ← (2≤≠text) ∧ ('['=FirstOrSpace text) ∧ ']'=FirstOrSpace⌽text
      {𝕊:
        Finalize @
        name ← ¯1↓1↓text ⋄ known ← Contains ⟨name,knownSections⟩
        diagnostics∾↩AddIf ⟨¬known,Diagnostic ⟨"report_policy_section_unsupported",row,"report.toml contains an unsupported section"⟩⟩
        {𝕊:active↩1 ⋄ current↩EmptyBlock ⟨name,row⟩}⍟known @
      }⍟header @
      {𝕊:
        diagnostics∾↩AddIf ⟨¬active,Diagnostic ⟨"report_policy_key_outside_section",row,"Report policy key must occur inside a supported section"⟩⟩
        {𝕊:
          equals ← '='=text
          diagnostics∾↩AddIf ⟨1≠+´equals,Diagnostic ⟨"report_policy_key_shape_invalid",row,"Report policy row requires exactly one equals separator"⟩⟩
          {𝕊:
            p ← ⊑equals/↕≠text ⋄ key ← Trim p↑text ⋄ value ← Trim (p+1)↓text
            valid ← (0<≠key) ∧ 0<≠value
            diagnostics∾↩AddIf ⟨¬valid,Diagnostic ⟨"report_policy_key_shape_invalid",row,"Report policy key and value must be nonempty"⟩⟩
            {𝕊:current↩{kind⇐current.kind,line⇐current.line,pairs⇐current.pairs∾⟨{key⇐key,text⇐value,line⇐row}⟩}}⍟valid @
          }⍟(1=+´equals) @
        }⍟active @
      }⍟(¬header) @
    }⍟(¬ignored) @
  }¨↕≠lines
  Finalize @

  Singles ← {𝕊 kind: ({𝕩.kind≡kind}¨blocks)/blocks}
  RequireOne ← {𝕊 kind:
    found ← Singles kind ⋄ result ← EmptyBlock ⟨kind,0⟩
    diagnostics∾↩AddIf ⟨1≠≠found,Diagnostic ⟨"report_policy_section_cardinality_invalid",0,"Required Report section must occur exactly once"⟩⟩
    {𝕊:result↩⊑found}⍟(1=≠found) @ ⋄ result
  }
  OptionalOne ← {𝕊 kind:
    found ← Singles kind ⋄ result ← EmptyBlock ⟨kind,0⟩
    diagnostics∾↩AddIf ⟨1<≠found,Diagnostic ⟨"report_policy_section_cardinality_invalid",0,"Optional Report section may occur at most once"⟩⟩
    {𝕊:result↩⊑found}⍟(1=≠found) @ ⋄ result
  }
  CheckKeys ← {𝕊 block‿required‿optional:
    keys ← {𝕩.key}¨block.pairs ⋄ allowed ← required∾optional
    diagnostics∾↩AddIf ⟨(≠keys)≠≠⍷keys,Diagnostic ⟨"report_policy_key_duplicate",block.line,"Report policy section keys must be unique"⟩⟩
    diagnostics∾↩AddIf ⟨∨´0∾{¬Contains ⟨𝕩,allowed⟩}¨keys,Diagnostic ⟨"report_policy_key_unsupported",block.line,"Report policy section contains an unsupported key"⟩⟩
    diagnostics∾↩AddIf ⟨∨´0∾{¬Contains ⟨𝕩,keys⟩}¨required,Diagnostic ⟨"report_policy_key_missing",block.line,"Report policy section is missing a required key"⟩⟩
  }
  StringValue ← {𝕊 block‿key:
    pair ← PairValue ⟨block,key⟩ ⋄ parsed ← ParseString pair.text
    diagnostics∾↩AtLine ⟨parsed,pair.line⟩ ⋄ parsed.value
  }
  PositiveInteger ← {𝕊 block‿key‿fallback:
    pair ← PairValue ⟨block,key⟩ ⋄ value ← fallback
    {𝕊:
      text ← Trim pair.text ⋄ valid ← IsDigits text
      diagnostics∾↩AddIf ⟨¬valid,Diagnostic ⟨"report_policy_positive_integer_invalid",pair.line,"Report policy integer must contain decimal digits"⟩⟩
      {𝕊:
        parsed ← ToNum text
        diagnostics∾↩AddIf ⟨parsed≤0,Diagnostic ⟨"report_policy_positive_integer_invalid",pair.line,"Report policy integer must be positive"⟩⟩
        {𝕊:value↩parsed}⍟(0<parsed) @
      }⍟valid @
    }⍟pair.found @
    value
  }
  ValidateDateReference ← {𝕊 value‿allowBeginning‿lineNumber:
    symbolic ← (value≡"latest") ∨ (allowBeginning ∧ value≡"beginning")
    valid ← symbolic ∨ date.IsValid value
    diagnostics∾↩AddIf ⟨¬valid,Diagnostic ⟨"report_policy_date_reference_invalid",lineNumber,"Report date must be latest, beginning where allowed, or YYYY-MM-DD"⟩⟩
    valid
  }
  StringDate ← {𝕊 block‿key‿allowBeginning:
    pair ← PairValue ⟨block,key⟩ ⋄ value ← StringValue ⟨block,key⟩
    ValidateDateReference ⟨value,allowBeginning,pair.line⟩ ⋄ value
  }
  CheckExplicitRange ← {𝕊 from‿through‿lineNumber:
    both ← date.IsValid from ∧ date.IsValid through
    diagnostics∾↩AddIf ⟨both ∧ (date.Ordinal from)>date.Ordinal through,Diagnostic ⟨"report_policy_range_invalid",lineNumber,"Report range start must not be after its through date"⟩⟩
  }

  presentationBlock ← OptionalOne "presentation.amounts"
  negativeStyle ← "parentheses" ⋄ negativeColor ← "red"
  {𝕊:
    CheckKeys ⟨presentationBlock,⟨"negative-style"⟩,⟨"negative-color"⟩⟩
    negativeStyle↩StringValue ⟨presentationBlock,"negative-style"⟩
    diagnostics∾↩AddIf ⟨¬Contains ⟨negativeStyle,⟨"parentheses","minus"⟩⟩,Diagnostic ⟨"report_policy_negative_style_invalid",presentationBlock.line,"negative-style must be parentheses or minus"⟩⟩
    colorPair ← PairValue ⟨presentationBlock,"negative-color"⟩
    {𝕊:negativeColor↩StringValue ⟨presentationBlock,"negative-color"⟩}⍟colorPair.found @
    diagnostics∾↩AddIf ⟨¬Contains ⟨negativeColor,⟨"red","bright-red","green","yellow","blue","magenta","cyan","white"⟩⟩,Diagnostic ⟨"report_policy_negative_color_invalid",presentationBlock.line,"negative-color is not a supported terminal color"⟩⟩
  }⍟(0<presentationBlock.line) @

  trialBlock ← RequireOne "reports.trial-balance" ⋄ CheckKeys ⟨trialBlock,⟨"as-of"⟩,empty⟩
  trialAsOf ← StringDate ⟨trialBlock,"as-of",0⟩

  balanceBlock ← RequireOne "reports.balance-sheet" ⋄ CheckKeys ⟨balanceBlock,⟨"as-of"⟩,empty⟩
  balanceAsOf ← StringDate ⟨balanceBlock,"as-of",0⟩

  profitBlock ← RequireOne "reports.profit-and-loss" ⋄ CheckKeys ⟨profitBlock,⟨"from","through"⟩,empty⟩
  profitFrom ← StringDate ⟨profitBlock,"from",1⟩ ⋄ profitThrough ← StringDate ⟨profitBlock,"through",0⟩
  CheckExplicitRange ⟨profitFrom,profitThrough,profitBlock.line⟩

  dailyBlock ← RequireOne "reports.daily-flow" ⋄ CheckKeys ⟨dailyBlock,⟨"from","through"⟩,⟨"max-date-columns"⟩⟩
  dailyFrom ← StringDate ⟨dailyBlock,"from",1⟩ ⋄ dailyThrough ← StringDate ⟨dailyBlock,"through",0⟩
  dailyColumns ← PositiveInteger ⟨dailyBlock,"max-date-columns",14⟩
  CheckExplicitRange ⟨dailyFrom,dailyThrough,dailyBlock.line⟩

  monthlyBlock ← RequireOne "reports.monthly-accounts" ⋄ CheckKeys ⟨monthlyBlock,⟨"from","through"⟩,empty⟩
  monthlyFrom ← StringDate ⟨monthlyBlock,"from",1⟩ ⋄ monthlyThrough ← StringDate ⟨monthlyBlock,"through",0⟩
  CheckExplicitRange ⟨monthlyFrom,monthlyThrough,monthlyBlock.line⟩

  recentBlock ← RequireOne "reports.recent-transactions" ⋄ CheckKeys ⟨recentBlock,⟨"through","count"⟩,empty⟩
  recentThrough ← StringDate ⟨recentBlock,"through",0⟩
  recentCount ← PositiveInteger ⟨recentBlock,"count",0⟩

  state ← (0=≠diagnostics)⊑"error"‿"ok"
  {
    state⇐state,source_name⇐"report.toml",
    presentation⇐{negative_style⇐negativeStyle,negative_color⇐negativeColor,daily_flow_max_date_columns⇐dailyColumns},
    reports⇐{
      trial_balance⇐{as_of⇐trialAsOf},
      balance_sheet⇐{as_of⇐balanceAsOf},
      profit_and_loss⇐{from⇐profitFrom,through⇐profitThrough},
      daily_flow⇐{from⇐dailyFrom,through⇐dailyThrough,max_date_columns⇐dailyColumns},
      monthly_accounts⇐{from⇐monthlyFrom,through⇐monthlyThrough},
      recent_transactions⇐{through⇐recentThrough,count⇐recentCount}
    },
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}
