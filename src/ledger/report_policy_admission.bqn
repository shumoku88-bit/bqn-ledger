# Strict BQN-native admission for canonical report.toml.
#
# This owner admits only Report query defaults and presentation policy. Physical
# source basenames, Household classification, Envelope membership, writer
# authority, clocks, and legacy manifest rows are deliberately outside it.

date ← •Import "date_ordinal.bqn"

lf ← @+10 ⋄ cr ← @+13 ⋄ space ← @+32 ⋄ tab ← @+9 ⋄ quote ← @+34 ⋄ hash ← ⊑"#"
empty ← ⟨⟩
digits ← "0123456789"
printableAscii ← @+32+↕95

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IsWhitespace ← {𝕊 c: (c=space) ∨ c=tab}
TrimLeft ← {𝕊 xs: prefix ← ∧`IsWhitespace¨xs ⋄ (+´prefix)↓xs}
TrimRight ← {𝕊 xs: ⌽TrimLeft⌽xs}
Trim ← {TrimRight TrimLeft 𝕩}
SplitKeepEmpty ← {𝕊 sep‿text: groups ← (+`sep=text)⊔text ⋄ {(sep≠𝕩)/𝕩}¨groups}
FirstOrSpace ← {𝕊 text: ⊑text∾⟨space⟩}
IsDigits ← {𝕊 text: (0<≠text) ∧ ∧´text∊digits}
IsMarker ← {𝕊 text: (1=≠text) ∧ ∧´text∊printableAscii}
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
  knownSections ← ⟨
    "presentation.amounts","presentation.calendar","reports.trial-balance","reports.balance-sheet",
    "reports.profit-and-loss","reports.daily-flow","reports.monthly-accounts",
    "reports.recent-transactions"
  ⟩

  indices ← ↕≠lines
  trimmed ← Trim¨lines
  ignored ← (0=≠¨trimmed) ∨ hash=FirstOrSpace¨trimmed
  header ← {(2≤≠𝕩) ∧ ('['=FirstOrSpace 𝕩) ∧ ']'=FirstOrSpace⌽𝕩}¨trimmed
  segmentIds ← +`header
  segments ← segmentIds⊔indices

  ParsePair ← {𝕊 sourceIndex:
    text ← sourceIndex⊑trimmed
    row ← sourceIndex+1
    diagnostics ← empty
    pair ← @
    equals ← '='=text
    diagnostics∾↩AddIf ⟨1≠+´equals,Diagnostic ⟨"report_policy_key_shape_invalid",row,"Report policy row requires exactly one equals separator"⟩⟩
    {𝕊:
      p ← ⊑equals/↕≠text
      key ← Trim p↑text
      value ← Trim (p+1)↓text
      valid ← (0<≠key) ∧ 0<≠value
      diagnostics∾↩AddIf ⟨¬valid,Diagnostic ⟨"report_policy_key_shape_invalid",row,"Report policy key and value must be nonempty"⟩⟩
      {𝕊:pair↩{key⇐key,text⇐value,line⇐row}}⍟valid @
    }⍟(1=+´equals) @
    {diagnostics⇐diagnostics,pair⇐pair}
  }

  ParseSegment ← {𝕊 segment:
    diagnostics ← empty
    block ← @
    {𝕊:
      first ← ⊑segment
      sectionSegment ← first⊑header
      rowIndices ← ((¬segment⊏ignored) ∧ ¬segment⊏header)/segment
      {𝕊:
        name ← ¯1↓1↓first⊑trimmed
        known ← Contains ⟨name,knownSections⟩
        diagnostics∾↩AddIf ⟨¬known,Diagnostic ⟨"report_policy_section_unsupported",first+1,"report.toml contains an unsupported section"⟩⟩
        {𝕊:
          parsedPairs ← ParsePair¨rowIndices
          diagnostics∾↩∾⟨empty⟩∾{𝕩.diagnostics}¨parsedPairs
          pairItems ← {𝕩.pair}¨parsedPairs
          pairs ← ({𝕩≢@}¨pairItems)/pairItems
          block↩{kind⇐name,line⇐first+1,pairs⇐pairs}
        }⍟known @
        {𝕊:
          diagnostics∾↩{𝕊 sourceIndex:
            Diagnostic ⟨"report_policy_key_outside_section",sourceIndex+1,"Report policy key must occur inside a supported section"⟩
          }¨rowIndices
        }⍟(¬known) @
      }⍟sectionSegment @
      {𝕊:
        outside ← (¬segment⊏ignored)/segment
        diagnostics∾↩{𝕊 sourceIndex:
          Diagnostic ⟨"report_policy_key_outside_section",sourceIndex+1,"Report policy key must occur inside a supported section"⟩
        }¨outside
      }⍟(¬sectionSegment) @
    }⍟(0<≠segment) @
    {diagnostics⇐diagnostics,block⇐block}
  }

  parsedSegments ← ParseSegment¨segments
  diagnostics ← ∾⟨empty⟩∾{𝕩.diagnostics}¨parsedSegments
  blockItems ← {𝕩.block}¨parsedSegments
  blocks ← ({𝕩≢@}¨blockItems)/blockItems

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
  MarkerValue ← {𝕊 block‿key‿fallback:
    pair ← PairValue ⟨block,key⟩ ⋄ value ← fallback
    {𝕊:
      value↩StringValue ⟨block,key⟩
      diagnostics∾↩AddIf ⟨¬IsMarker value,Diagnostic ⟨"report_policy_calendar_marker_invalid",pair.line,"Calendar marker must be exactly one printable ASCII character"⟩⟩
    }⍟pair.found @
    value
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
    both ← (date.IsValid from) ∧ date.IsValid through
    {𝕊:
      reversed ← (date.Ordinal from)>date.Ordinal through
      diagnostics∾↩AddIf ⟨reversed,Diagnostic ⟨"report_policy_range_invalid",lineNumber,"Report range start must not be after its through date"⟩⟩
    }⍟both @
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

  calendarBlock ← OptionalOne "presentation.calendar"
  cycleEndMarker ← "*" ⋄ planDueMarker ← "$" ⋄ issueDueMarker ← "!" ⋄ multipleMarker ← "+"
  {𝕊:
    CheckKeys ⟨calendarBlock,empty,⟨"cycle-end-marker","plan-due-marker","issue-due-marker","multiple-marker"⟩⟩
    cycleEndMarker↩MarkerValue ⟨calendarBlock,"cycle-end-marker",cycleEndMarker⟩
    planDueMarker↩MarkerValue ⟨calendarBlock,"plan-due-marker",planDueMarker⟩
    issueDueMarker↩MarkerValue ⟨calendarBlock,"issue-due-marker",issueDueMarker⟩
    multipleMarker↩MarkerValue ⟨calendarBlock,"multiple-marker",multipleMarker⟩
  }⍟(0<calendarBlock.line) @

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
    presentation⇐{
      negative_style⇐negativeStyle,negative_color⇐negativeColor,daily_flow_max_date_columns⇐dailyColumns,
      calendar⇐{cycle_end_marker⇐cycleEndMarker,plan_due_marker⇐planDueMarker,issue_due_marker⇐issueDueMarker,multiple_marker⇐multipleMarker}
    },
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
