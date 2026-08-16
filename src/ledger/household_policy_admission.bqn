# Strict BQN-native admission for canonical household.toml.
# Account identity/type remains owned by accounts.journal. General Envelope and
# Backing policy remains owned by budget.toml. This owner admits Household-only
# Cycle, stable Budget allocation coordinates, Money defaults, Daily Target
# selections, and policy axes. Current Envelope membership remains budget.toml
# authority; allocation coordinates may outlive current membership so historical
# budget.journal evidence remains interpretable.

lf ← @+10 ⋄ cr ← @+13 ⋄ space ← @+32 ⋄ tab ← @+9 ⋄ quote ← @+34 ⋄ hash ← ⊑"#"
empty ← ⟨⟩
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IsWhitespace ← {𝕊 c: (c=space) ∨ c=tab}
TrimLeft ← {𝕊 xs: prefix ← ∧`IsWhitespace¨xs ⋄ (+´prefix)↓xs}
TrimRight ← {𝕊 xs: ⌽TrimLeft⌽xs}
Trim ← {TrimRight TrimLeft 𝕩}
SplitKeepEmpty ← {𝕊 sep‿text: groups ← (+`sep=text)⊔text ⋄ {(sep≠𝕩)/𝕩}¨groups}
FirstOrSpace ← {𝕊 text: ⊑text∾⟨space⟩}

# Canonical Account arrays may span physical TOML lines. A logical row keeps
# the first physical line for diagnostics and preserves item/source order.
ArrayClosed ← {𝕊 text:
  inQuote ← 0 ⋄ closed ← 0
  {𝕊 c:
    wasInQuote ← inQuote
    {𝕊:inQuote↩0}⍟(wasInQuote ∧ c=quote) @
    {𝕊:
      {𝕊:inQuote↩1}⍟(c=quote) @
      {𝕊:closed↩1}⍟(c=']') @
    }⍟(¬wasInQuote) @
  }¨text
  closed ∧ ¬inQuote
}
NoWhitespace ← {𝕊 value: (0<≠value) ∧ ¬∨´0∾IsWhitespace¨value}
Diagnostic ← {𝕊 code‿line‿message:{severity⇐"error",stage⇐"ledger_household_policy_admission",code⇐code,line⇐line,message⇐message}}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}

ParseString ← {𝕊 text:
  t ← Trim text ⋄ diagnostics ← empty ⋄ value ← ""
  enclosed ← (2≤≠t) ∧ (quote=FirstOrSpace t) ∧ quote=FirstOrSpace⌽t
  diagnostics∾↩AddIf ⟨¬enclosed,Diagnostic ⟨"household_string_invalid",0,"Household string value must be quoted"⟩⟩
  {𝕊:value↩¯1↓1↓t}⍟enclosed @
  diagnostics∾↩AddIf ⟨enclosed ∧ ∨´0∾quote=value,Diagnostic ⟨"household_string_escape_unsupported",0,"Embedded quotes are not admitted"⟩⟩
  {ok⇐0=≠diagnostics,value⇐(0=≠diagnostics)/value,diagnostics⇐diagnostics}
}
SplitArrayItems ← {𝕊 inner:
  parts ← empty ⋄ current ← "" ⋄ inQuote ← 0
  {𝕊 c:
    separator ← (c=',') ∧ ¬inQuote
    {𝕊:parts∾↩⟨Trim current⟩ ⋄ current↩""}⍟separator @
    {𝕊:
      current∾↩⟨c⟩
      {𝕊:inQuote↩¬inQuote}⍟(c=quote) @
    }⍟(¬separator) @
  }¨inner
  tail ← Trim current
  {𝕊:parts∾↩⟨tail⟩}⍟(0<≠tail) @
  {parts⇐parts,invalid⇐inQuote}
}
ParseArray ← {𝕊 text:
  t ← Trim text ⋄ diagnostics ← empty ⋄ values ← empty
  enclosed ← (2≤≠t) ∧ ('['=FirstOrSpace t) ∧ ']'=FirstOrSpace⌽t
  diagnostics∾↩AddIf ⟨¬enclosed,Diagnostic ⟨"household_array_invalid",0,"Household Account list must use a TOML array"⟩⟩
  {𝕊:
    inner ← Trim ¯1↓1↓t
    {𝕊:
      split ← SplitArrayItems inner
      diagnostics∾↩AddIf ⟨split.invalid,Diagnostic ⟨"household_array_invalid",0,"Household array has unbalanced quoting"⟩⟩
      {𝕊 part:
        parsed ← ParseString part ⋄ diagnostics∾↩parsed.diagnostics
        {𝕊:values∾↩⟨parsed.value⟩}⍟parsed.ok @
      }¨split.parts
    }⍟(0<≠inner) @
  }⍟enclosed @
  {ok⇐0=≠diagnostics,values⇐(0=≠diagnostics)/values,diagnostics⇐diagnostics}
}
AtLine ← {𝕊 parsed‿lineNumber:{𝕊 d:{severity⇐d.severity,stage⇐d.stage,code⇐d.code,line⇐lineNumber,message⇐d.message}}¨parsed.diagnostics}
EmptyBlock ← {𝕊 kind‿line:{kind⇐kind,line⇐line,pairs⇐empty}}
PairValue ← {𝕊 block‿key:
  matches ← ({𝕩.key≡key}¨block.pairs)/block.pairs
  result ← {found⇐0,text⇐"",line⇐block.line}
  {𝕊:p←⊑matches ⋄ result↩{found⇐1,text⇐p.text,line⇐p.line}}⍟(1=≠matches) @
  result
}

Admit ← {𝕊 raw‿accounts‿budgetPolicy:
  physicalLines ← SplitKeepEmpty ⟨lf,(cr≠raw)/raw⟩
  lines ← empty ⋄ lineRows ← empty ⋄ pending ← 0 ⋄ pendingText ← "" ⋄ pendingRow ← 0
  {𝕊 i:
    text ← Trim i⊑physicalLines ⋄ row ← i+1 ⋄ wasPending ← pending
    {𝕊:
      pendingText∾↩" "∾text
      {𝕊:lines∾↩⟨pendingText⟩ ⋄ lineRows∾↩⟨pendingRow⟩ ⋄ pending↩0 ⋄ pendingText↩""}⍟(ArrayClosed pendingText) @
    }⍟wasPending @
    {𝕊:
      equals ← '='=text ⋄ multiline ← 0
      {𝕊:
        p ← ⊑equals/↕≠text ⋄ value ← Trim (p+1)↓text
        multiline↩('['=FirstOrSpace value) ∧ ¬ArrayClosed value
      }⍟(1=+´equals) @
      {𝕊:pending↩1 ⋄ pendingText↩text ⋄ pendingRow↩row}⍟multiline @
      {𝕊:lines∾↩⟨text⟩ ⋄ lineRows∾↩⟨row⟩}⍟(¬multiline) @
    }⍟(¬wasPending) @
  }¨↕≠physicalLines
  {𝕊:lines∾↩⟨pendingText⟩ ⋄ lineRows∾↩⟨pendingRow⟩}⍟pending @

  diagnostics ← empty ⋄ blocks ← empty
  KnownSection ← {𝕊 name: Contains ⟨name,⟨
    "cycle","budget","budget.envelopes","money","daily-target","daily-target.assets",
    "account-policy.assets","account-policy.budget.kind","account-policy.budget.envelope-role",
    "account-policy.budget.group","account-policy.expenses"
  ⟩⟩}

  # Multiline/quote state above is lexical. Once logical rows exist, section
  # ownership is a source relation: classify headers, Scan one segment axis,
  # then parse each source-ordered segment locally.
  indices ← ↕≠lines
  ignored ← (0=≠¨lines) ∨ hash=FirstOrSpace¨lines
  HeaderShape ← {𝕊 text:
    n ← ≠text
    first ← FirstOrSpace text
    last ← FirstOrSpace⌽text
    firstTwo ← 2↑text∾2⥊space
    lastTwo ← 2↑(⌽text)∾2⥊space
    array ← (4≤n) ∧ ("[["≡firstTwo) ∧ ("]]"≡lastTwo)
    table ← (2≤n) ∧ ('['=first) ∧ (']'=last) ∧ ¬array
    {array⇐array,table⇐table}
  }
  shapes ← HeaderShape¨lines
  arrayHeader ← {𝕩.array}¨shapes
  tableHeader ← {𝕩.table}¨shapes
  header ← arrayHeader ∨ tableHeader
  segmentIds ← +`header
  segments ← segmentIds⊔indices

  ParsePair ← {𝕊 sourceIndex:
    text ← sourceIndex⊑lines ⋄ row ← sourceIndex⊑lineRows ⋄ pair ← empty
    equals ← '='=text
    diagnostics∾↩AddIf ⟨1≠+´equals,Diagnostic ⟨"household_key_shape_invalid",row,"Household row requires exactly one equals separator"⟩⟩
    {𝕊:
      p ← ⊑equals/↕≠text ⋄ key ← Trim p↑text ⋄ value ← Trim (p+1)↓text
      valid ← (0<≠key) ∧ 0<≠value
      diagnostics∾↩AddIf ⟨¬valid,Diagnostic ⟨"household_key_shape_invalid",row,"Household key and value must be nonempty"⟩⟩
      {𝕊:pair↩⟨{key⇐key,text⇐value,line⇐row}⟩}⍟valid @
    }⍟(1=+´equals) @
    pair
  }
  Outside ← {𝕊 sourceIndex:
    diagnostics∾↩⟨Diagnostic ⟨"household_key_outside_section",sourceIndex⊑lineRows,"Household key must occur inside a supported section"⟩⟩
  }

  {𝕊 segmentIndex:
    segment ← segmentIndex⊑segments
    {𝕊:
      outsideIndices ← (¬segment⊏ignored)/segment
      Outside¨outsideIndices
    }⍟(0=segmentIndex) @
    {𝕊:
      headerIndex ← ⊑segment
      headerText ← headerIndex⊑lines
      row ← headerIndex⊑lineRows
      edge ← 1+headerIndex⊑arrayHeader
      name ← edge↓(-edge)↓headerText
      known ← KnownSection name
      diagnostics∾↩AddIf ⟨¬known,Diagnostic ⟨"household_section_unsupported",row,"household.toml contains an unsupported section"⟩⟩
      tail ← 1↓segment
      sourceIndices ← (¬tail⊏ignored)/tail
      {𝕊:
        pairs ← ∾ParsePair¨sourceIndices
        blocks∾↩⟨{kind⇐name,line⇐row,pairs⇐pairs}⟩
      }⍟known @
      {𝕊:Outside¨sourceIndices}⍟(¬known) @
    }⍟(0<segmentIndex) @
  }¨↕≠segments

  Singles ← {𝕊 kind: ({𝕩.kind≡kind}¨blocks)/blocks}
  RequireOne ← {𝕊 kind:
    found ← Singles kind ⋄ result ← EmptyBlock ⟨kind,0⟩
    diagnostics∾↩AddIf ⟨1≠≠found,Diagnostic ⟨"household_section_cardinality_invalid",0,"Required Household section must occur exactly once"⟩⟩
    {𝕊:result↩⊑found}⍟(1=≠found) @ ⋄ result
  }
  CheckKeys ← {𝕊 block‿required‿optional:
    keys ← {𝕩.key}¨block.pairs ⋄ allowed ← required∾optional
    diagnostics∾↩AddIf ⟨(≠keys)≠≠⍷keys,Diagnostic ⟨"household_key_duplicate",block.line,"Household section keys must be unique"⟩⟩
    diagnostics∾↩AddIf ⟨∨´0∾{¬Contains ⟨𝕩,allowed⟩}¨keys,Diagnostic ⟨"household_key_unsupported",block.line,"Household section contains an unsupported key"⟩⟩
    diagnostics∾↩AddIf ⟨∨´0∾{¬Contains ⟨𝕩,keys⟩}¨required,Diagnostic ⟨"household_key_missing",block.line,"Household section is missing a required key"⟩⟩
  }
  StringValue ← {𝕊 block‿key:
    pair ← PairValue ⟨block,key⟩ ⋄ parsed ← ParseString pair.text
    diagnostics∾↩AtLine ⟨parsed,pair.line⟩ ⋄ parsed.value
  }
  ArrayValue ← {𝕊 block‿key:
    pair ← PairValue ⟨block,key⟩ ⋄ parsed ← ParseArray pair.text
    diagnostics∾↩AtLine ⟨parsed,pair.line⟩ ⋄ parsed.values
  }
  AccountRelations ← {𝕊 keys‿expectedRole‿lineNumber:
    coordinates ← accounts.key⊐keys
    known ← coordinates<accounts.count
    roles ← coordinates⊏(accounts.role∾⟨""⟩)
    roleRequired ← 0<≠expectedRole
    roleMatches ← expectedRole⊸≡¨roles
    roleInvalid ← known ∧ roleRequired ∧ ¬roleMatches
    relationDiagnostics ← ∾⟨empty⟩∾{𝕊 i:
      unknownDiagnostic ← (¬i⊑known)/⟨Diagnostic ⟨"household_account_unknown",lineNumber,"Household policy Account must be declared in accounts.journal"⟩⟩
      roleDiagnostic ← (i⊑roleInvalid)/⟨Diagnostic ⟨"household_account_role_invalid",lineNumber,"Household policy Account has the wrong accounting type"⟩⟩
      unknownDiagnostic∾roleDiagnostic
    }¨↕≠keys
    diagnostics∾↩relationDiagnostics
    {coordinates⇐coordinates,valid⇐known ∧ ¬roleInvalid}
  }

  cycleBlock ← RequireOne "cycle" ⋄ CheckKeys ⟨cycleBlock,⟨"mode","income-account"⟩,empty⟩
  cycleMode ← StringValue ⟨cycleBlock,"mode"⟩ ⋄ incomeKey ← StringValue ⟨cycleBlock,"income-account"⟩
  diagnostics∾↩AddIf ⟨cycleMode≢"income-anchor",Diagnostic ⟨"household_cycle_mode_invalid",cycleBlock.line,"Canonical Household cycle mode must be income-anchor"⟩⟩
  AccountRelations ⟨⟨incomeKey⟩,"income",cycleBlock.line⟩

  budgetBlock ← RequireOne "budget" ⋄ CheckKeys ⟨budgetBlock,⟨"unassigned-accounts"⟩,empty⟩
  unassignedKeys ← ArrayValue ⟨budgetBlock,"unassigned-accounts"⟩
  diagnostics∾↩AddIf ⟨0=≠unassignedKeys,Diagnostic ⟨"household_unassigned_missing",budgetBlock.line,"Household Budget policy requires at least one unassigned Account"⟩⟩
  diagnostics∾↩AddIf ⟨(≠unassignedKeys)≠≠⍷unassignedKeys,Diagnostic ⟨"household_unassigned_duplicate",budgetBlock.line,"Unassigned Budget Accounts must be unique"⟩⟩
  unassignedRelation ← AccountRelations ⟨unassignedKeys,"budget",budgetBlock.line⟩
  unassignedIndices ← unassignedRelation.valid/unassignedRelation.coordinates

  moneyBlocks ← Singles "money" ⋄ moneyPresent ← 1=≠moneyBlocks ⋄ primaryCommodity ← ""
  diagnostics∾↩AddIf ⟨1<≠moneyBlocks,Diagnostic ⟨"household_section_cardinality_invalid",0,"Household money section may occur at most once"⟩⟩
  {𝕊:
    moneyBlock ← ⊑moneyBlocks
    CheckKeys ⟨moneyBlock,⟨"primary-commodity"⟩,empty⟩
    primaryCommodity↩StringValue ⟨moneyBlock,"primary-commodity"⟩
    diagnostics∾↩AddIf ⟨¬NoWhitespace primaryCommodity,Diagnostic ⟨"household_primary_commodity_invalid",moneyBlock.line,"Household primary Commodity must be nonempty and contain no whitespace"⟩⟩
  }⍟moneyPresent @

  envelopeRows ← empty
  {𝕊 block:
    CheckKeys ⟨block,⟨"id","allocation-account"⟩,⟨"plan-destination-accounts"⟩⟩
    id ← StringValue ⟨block,"id"⟩ ⋄ allocationKey ← StringValue ⟨block,"allocation-account"⟩
    destinationPair ← PairValue ⟨block,"plan-destination-accounts"⟩ ⋄ destinationKeys ← empty
    {𝕊:destinationKeys↩ArrayValue ⟨block,"plan-destination-accounts"⟩}⍟destinationPair.found @
    validId ← NoWhitespace id
    diagnostics∾↩AddIf ⟨¬validId,Diagnostic ⟨"household_envelope_id_invalid",block.line,"Household envelope id must be nonempty and contain no whitespace"⟩⟩
    allocationRelation ← AccountRelations ⟨⟨allocationKey⟩,"budget",block.line⟩
    allocationValid ← ⊑allocationRelation.valid ⋄ allocationIndex ← ⊑allocationRelation.coordinates
    {𝕊:envelopeRows∾↩⟨{id⇐id,allocation_key⇐allocationKey,allocation_index⇐allocationIndex,line⇐block.line}⟩}⍟(validId ∧ allocationValid) @
  }¨Singles "budget.envelopes"
  envelopeIds ← {𝕩.id}¨envelopeRows ⋄ allocationIndices ← {𝕩.allocation_index}¨envelopeRows
  diagnostics∾↩AddIf ⟨(≠envelopeIds)≠≠⍷envelopeIds,Diagnostic ⟨"household_envelope_id_duplicate",0,"Household envelope ids must be unique"⟩⟩
  diagnostics∾↩AddIf ⟨(≠allocationIndices)≠≠⍷allocationIndices,Diagnostic ⟨"household_allocation_account_duplicate",0,"One Budget Account may allocate only one envelope"⟩⟩
  # Current budget.toml Envelopes must still have a stable allocation coordinate.
  # Extra coordinates are historical identities and remain readable after the
  # current Envelope is retired.
  diagnostics∾↩AddIf ⟨∨´0∾{¬Contains ⟨𝕩,envelopeIds⟩}¨budgetPolicy.envelopes.id,Diagnostic ⟨"household_envelope_coordinates_missing",0,"Every current budget.toml envelope requires Household coordinates"⟩⟩
  dailyRows ← empty
  {𝕊 block:
    CheckKeys ⟨block,⟨"id","account"⟩,empty⟩
    id ← StringValue ⟨block,"id"⟩ ⋄ key ← StringValue ⟨block,"account"⟩
    validId ← 0<≠id ⋄ accountRelation ← AccountRelations ⟨⟨key⟩,"asset",block.line⟩
    validAccount ← ⊑accountRelation.valid ⋄ accountIndex ← ⊑accountRelation.coordinates
    diagnostics∾↩AddIf ⟨¬validId,Diagnostic ⟨"daily_target_id_empty",block.line,"Daily Target selection id must be nonempty"⟩⟩
    {𝕊:dailyRows∾↩⟨{scope_id⇐id,account_key⇐key,account_index⇐accountIndex,line⇐block.line}⟩}⍟(validId ∧ validAccount) @
  }¨Singles "daily-target.assets"
  dailyIds ← {𝕩.scope_id}¨dailyRows
  diagnostics∾↩AddIf ⟨(≠dailyIds)≠≠⍷dailyIds,Diagnostic ⟨"daily_target_id_duplicate",0,"Daily Target selection ids must be unique"⟩⟩

  axisSpec ← ⟨
    ⟨"account-policy.assets",⟨⟨"liquid","liquid"⟩,⟨"savings","savings"⟩,⟨"investment","investment"⟩⟩,"asset"⟩,
    ⟨"account-policy.budget.kind",⟨⟨"opening","opening"⟩,⟨"unassigned","unassigned"⟩,⟨"spent","spent"⟩,⟨"envelope","envelope"⟩⟩,"budget"⟩,
    ⟨"account-policy.budget.envelope-role",⟨⟨"unassigned","unassigned"⟩,⟨"dynamic","dynamic"⟩,⟨"execution","execution"⟩⟩,"budget"⟩,
    ⟨"account-policy.budget.group",⟨⟨"daily","daily"⟩,⟨"flex","flex"⟩,⟨"reserve","reserve"⟩⟩,"budget"⟩,
    ⟨"account-policy.expenses",⟨⟨"fixed","fixed"⟩,⟨"variable","variable"⟩⟩,"expense"⟩
  ⟩
  axisRows ← empty
  {𝕊 spec:
    sectionName‿members‿expectedRole ← spec ⋄ found ← Singles sectionName
    diagnostics∾↩AddIf ⟨1<≠found,Diagnostic ⟨"household_section_cardinality_invalid",0,"Household policy section may occur at most once"⟩⟩
    {𝕊:
      block ← ⊑found ⋄ CheckKeys ⟨block,{⊑𝕩}¨members,empty⟩
      {𝕊 member:
        keyName‿label ← member ⋄ keys ← ArrayValue ⟨block,keyName⟩
        relation ← AccountRelations ⟨keys,expectedRole,block.line⟩
        validIndices ← relation.valid/↕≠keys
        axisRows∾↩{𝕊 i:{axis⇐sectionName,account_index⇐i⊑relation.coordinates,label⇐label,line⇐block.line}}¨validIndices
      }¨members
    }⍟(1=≠found) @
  }¨axisSpec
  AxisValues ← {𝕊 sectionName:
    selected ← ({𝕩.axis≡sectionName}¨axisRows)/axisRows
    coordinates ← {𝕩.account_index}¨selected
    labels ← {𝕩.label}¨selected
    diagnostics∾↩AddIf ⟨(≠coordinates)≠≠⍷coordinates,Diagnostic ⟨"household_account_axis_duplicate",0,"One Account may occur only once on one Household policy axis"⟩⟩
    labelCoordinates ← coordinates⊐accounts.index
    labelCoordinates⊏(labels∾⟨""⟩)
  }
  assetClass ← AxisValues "account-policy.assets"
  budgetKind ← AxisValues "account-policy.budget.kind"
  envelopeRole ← AxisValues "account-policy.budget.envelope-role"
  budgetGroup ← AxisValues "account-policy.budget.group"
  spendClass ← AxisValues "account-policy.expenses"

  ok ← 0=≠diagnostics ⋄ admittedEnvelopes ← ok/envelopeRows ⋄ admittedDaily ← ok/dailyRows
  emptyAxis ← accounts.count⥊⟨""⟩
  cycleAdmission ← {state⇐ok⊑"error"‿"ok",diagnostics⇐diagnostics,definition⇐{
    mode⇐ok⊑""‿"incomeAnchor",start⇐"",end_exclusive⇐"",income_account⇐ok⊑""‿incomeKey,start_day⇐0,offset⇐0
  }}
  {
    state⇐ok⊑"error"‿"ok",source_name⇐"household.toml",cycle⇐cycleAdmission,
    money⇐{present⇐ok∧moneyPresent,primary_commodity⇐ok⊑""‿primaryCommodity},
    budget⇐{
      envelope_count⇐≠admittedEnvelopes,envelope_id⇐{𝕩.id}¨admittedEnvelopes,
      allocation_account_key⇐{𝕩.allocation_key}¨admittedEnvelopes,allocation_account_index⇐{𝕩.allocation_index}¨admittedEnvelopes,
      unassigned_account_keys⇐ok/unassignedKeys,unassigned_account_indices⇐ok/unassignedIndices
    },
    daily_target⇐{count⇐≠admittedDaily,index⇐↕≠admittedDaily,scope_id⇐{𝕩.scope_id}¨admittedDaily,account_key⇐{𝕩.account_key}¨admittedDaily,account_index⇐{𝕩.account_index}¨admittedDaily},
    account_policy⇐{
      account_key⇐accounts.key,
      asset_class⇐ok⊑⟨emptyAxis,assetClass⟩,budget_kind⇐ok⊑⟨emptyAxis,budgetKind⟩,
      envelope_role⇐ok⊑⟨emptyAxis,envelopeRole⟩,budget_group⇐ok⊑⟨emptyAxis,budgetGroup⟩,
      spend_class⇐ok⊑⟨emptyAxis,spendClass⟩
    },
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}