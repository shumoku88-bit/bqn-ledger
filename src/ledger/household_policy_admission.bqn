# Strict BQN-native admission for canonical household.toml.
# Account identity/type remains owned by accounts.journal. General Envelope and
# Backing policy remains owned by budget.toml. This owner admits Household-only
# Cycle, Budget structural coordinates, Daily Target selections, and policy axes.

lf ← @+10 ⋄ cr ← @+13 ⋄ space ← @+32 ⋄ tab ← @+9 ⋄ quote ← @+34 ⋄ hash ← ⊑"#"
empty ← ⟨⟩
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IndexOf ← {𝕊 item‿items: ⊑items⊐⟨item⟩}
IsWhitespace ← {𝕊 c: (c=space) ∨ c=tab}
TrimLeft ← {𝕊 xs: prefix ← ∧`IsWhitespace¨xs ⋄ (+´prefix)↓xs}
TrimRight ← {𝕊 xs: ⌽TrimLeft⌽xs}
Trim ← {TrimRight TrimLeft 𝕩}
SplitKeepEmpty ← {𝕊 sep‿text: groups ← (+`sep=text)⊔text ⋄ {(sep≠𝕩)/𝕩}¨groups}
FirstOrSpace ← {𝕊 text: ⊑text∾⟨space⟩}
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
  lines ← SplitKeepEmpty ⟨lf,(cr≠raw)/raw⟩
  diagnostics ← empty ⋄ blocks ← empty ⋄ active ← 0 ⋄ current ← EmptyBlock ⟨"",0⟩
  KnownSection ← {𝕊 name: Contains ⟨name,⟨
    "cycle","budget","budget.envelopes","daily-target","daily-target.assets",
    "account-policy.assets","account-policy.budget.kind","account-policy.budget.envelope-role",
    "account-policy.budget.group","account-policy.expenses"
  ⟩⟩}
  Finalize ← {𝕊:
    {𝕊:blocks∾↩⟨current⟩}⍟active @
    active↩0 ⋄ current↩EmptyBlock ⟨"",0⟩
  }
  {𝕊 i:
    text ← Trim i⊑lines ⋄ row ← i+1
    ignored ← (0=≠text) ∨ hash=FirstOrSpace text
    {𝕊:
      arrayHeader ← (4≤≠text) ∧ ("[["≡2↑text) ∧ "]]"≡¯2↑text
      tableHeader ← (2≤≠text) ∧ ('['=FirstOrSpace text) ∧ (']'=FirstOrSpace⌽text) ∧ ¬arrayHeader
      header ← arrayHeader ∨ tableHeader
      {𝕊:
        Finalize @
        edge ← 1+arrayHeader ⋄ name ← edge↓(-edge)↓text
        known ← KnownSection name
        diagnostics∾↩AddIf ⟨¬known,Diagnostic ⟨"household_section_unsupported",row,"household.toml contains an unsupported section"⟩⟩
        {𝕊:active↩1 ⋄ current↩EmptyBlock ⟨name,row⟩}⍟known @
      }⍟header @
      {𝕊:
        diagnostics∾↩AddIf ⟨¬active,Diagnostic ⟨"household_key_outside_section",row,"Household key must occur inside a supported section"⟩⟩
        {𝕊:
          equals ← '='=text
          diagnostics∾↩AddIf ⟨1≠+´equals,Diagnostic ⟨"household_key_shape_invalid",row,"Household row requires exactly one equals separator"⟩⟩
          {𝕊:
            p ← ⊑equals/↕≠text ⋄ key ← Trim p↑text ⋄ value ← Trim (p+1)↓text
            valid ← (0<≠key) ∧ 0<≠value
            diagnostics∾↩AddIf ⟨¬valid,Diagnostic ⟨"household_key_shape_invalid",row,"Household key and value must be nonempty"⟩⟩
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
  ValidateAccount ← {𝕊 key‿expectedRole‿lineNumber:
    i ← IndexOf ⟨key,accounts.key⟩ ⋄ known ← i<accounts.count ⋄ role ← i⊑accounts.role∾⟨""⟩
    diagnostics∾↩AddIf ⟨¬known,Diagnostic ⟨"household_account_unknown",lineNumber,"Household policy Account must be declared in accounts.journal"⟩⟩
    diagnostics∾↩AddIf ⟨known ∧ (0<≠expectedRole) ∧ role≢expectedRole,Diagnostic ⟨"household_account_role_invalid",lineNumber,"Household policy Account has the wrong accounting type"⟩⟩
    known ∧ ((0=≠expectedRole) ∨ role≡expectedRole)
  }

  cycleBlock ← RequireOne "cycle" ⋄ CheckKeys ⟨cycleBlock,⟨"mode","income-account"⟩,empty⟩
  cycleMode ← StringValue ⟨cycleBlock,"mode"⟩ ⋄ incomeKey ← StringValue ⟨cycleBlock,"income-account"⟩
  diagnostics∾↩AddIf ⟨cycleMode≢"income-anchor",Diagnostic ⟨"household_cycle_mode_invalid",cycleBlock.line,"Canonical Household cycle mode must be income-anchor"⟩⟩
  incomeIndex ← IndexOf ⟨incomeKey,accounts.key⟩ ⋄ incomeValid ← ValidateAccount ⟨incomeKey,"income",cycleBlock.line⟩

  budgetBlock ← RequireOne "budget" ⋄ CheckKeys ⟨budgetBlock,⟨"unassigned-accounts"⟩,empty⟩
  unassignedKeys ← ArrayValue ⟨budgetBlock,"unassigned-accounts"⟩
  diagnostics∾↩AddIf ⟨0=≠unassignedKeys,Diagnostic ⟨"household_unassigned_missing",budgetBlock.line,"Household Budget policy requires at least one unassigned Account"⟩⟩
  diagnostics∾↩AddIf ⟨(≠unassignedKeys)≠≠⍷unassignedKeys,Diagnostic ⟨"household_unassigned_duplicate",budgetBlock.line,"Unassigned Budget Accounts must be unique"⟩⟩
  unassignedIndices ← empty
  {𝕊 key:
    valid ← ValidateAccount ⟨key,"budget",budgetBlock.line⟩
    {𝕊:unassignedIndices∾↩⟨IndexOf ⟨key,accounts.key⟩⟩}⍟valid @
  }¨unassignedKeys

  envelopeRows ← empty
  {𝕊 block:
    CheckKeys ⟨block,⟨"id","allocation-account"⟩,⟨"plan-destination-accounts"⟩⟩
    id ← StringValue ⟨block,"id"⟩ ⋄ allocationKey ← StringValue ⟨block,"allocation-account"⟩
    destinationPair ← PairValue ⟨block,"plan-destination-accounts"⟩ ⋄ destinationKeys ← empty
    {𝕊:destinationKeys↩ArrayValue ⟨block,"plan-destination-accounts"⟩}⍟destinationPair.found @
    validId ← NoWhitespace id
    diagnostics∾↩AddIf ⟨¬validId,Diagnostic ⟨"household_envelope_id_invalid",block.line,"Household envelope id must be nonempty and contain no whitespace"⟩⟩
    allocationValid ← ValidateAccount ⟨allocationKey,"budget",block.line⟩ ⋄ allocationIndex ← IndexOf ⟨allocationKey,accounts.key⟩
    destinationIndices ← empty
    {𝕊 key:
      valid ← ValidateAccount ⟨key,"",block.line⟩
      {𝕊:destinationIndices∾↩⟨IndexOf ⟨key,accounts.key⟩⟩}⍟valid @
    }¨destinationKeys
    {𝕊:envelopeRows∾↩⟨{id⇐id,allocation_key⇐allocationKey,allocation_index⇐allocationIndex,plan_destination_keys⇐destinationKeys,plan_destination_indices⇐destinationIndices,line⇐block.line}⟩}⍟(validId ∧ allocationValid) @
  }¨Singles "budget.envelopes"
  envelopeIds ← {𝕩.id}¨envelopeRows ⋄ allocationIndices ← {𝕩.allocation_index}¨envelopeRows
  diagnostics∾↩AddIf ⟨(≠envelopeIds)≠≠⍷envelopeIds,Diagnostic ⟨"household_envelope_id_duplicate",0,"Household envelope ids must be unique"⟩⟩
  diagnostics∾↩AddIf ⟨(≠allocationIndices)≠≠⍷allocationIndices,Diagnostic ⟨"household_allocation_account_duplicate",0,"One Budget Account may allocate only one envelope"⟩⟩
  diagnostics∾↩AddIf ⟨(≠envelopeIds)≠budgetPolicy.envelopes.count,Diagnostic ⟨"household_envelope_coordinates_incomplete",0,"Every budget.toml envelope requires Household allocation coordinates"⟩⟩
  diagnostics∾↩AddIf ⟨∨´0∾{¬Contains ⟨𝕩,budgetPolicy.envelopes.id⟩}¨envelopeIds,Diagnostic ⟨"household_envelope_unknown",0,"Household envelope coordinates must reference budget.toml"⟩⟩
  diagnostics∾↩AddIf ⟨∨´0∾{¬Contains ⟨𝕩,envelopeIds⟩}¨budgetPolicy.envelopes.id,Diagnostic ⟨"household_envelope_coordinates_missing",0,"Every budget.toml envelope requires Household coordinates"⟩⟩
  allDestinations ← ∾{𝕩.plan_destination_indices}¨envelopeRows
  diagnostics∾↩AddIf ⟨(≠allDestinations)≠≠⍷allDestinations,Diagnostic ⟨"household_plan_destination_duplicate",0,"One Plan destination Account may belong to only one envelope"⟩⟩

  dailyRows ← empty
  {𝕊 block:
    CheckKeys ⟨block,⟨"id","account"⟩,empty⟩
    id ← StringValue ⟨block,"id"⟩ ⋄ key ← StringValue ⟨block,"account"⟩
    validId ← 0<≠id ⋄ validAccount ← ValidateAccount ⟨key,"asset",block.line⟩
    diagnostics∾↩AddIf ⟨¬validId,Diagnostic ⟨"daily_target_id_empty",block.line,"Daily Target selection id must be nonempty"⟩⟩
    {𝕊:dailyRows∾↩⟨{scope_id⇐id,account_key⇐key,account_index⇐IndexOf ⟨key,accounts.key⟩,line⇐block.line}⟩}⍟(validId ∧ validAccount) @
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
        {𝕊 key:
          valid ← ValidateAccount ⟨key,expectedRole,block.line⟩
          {𝕊:axisRows∾↩⟨{axis⇐sectionName,account_index⇐IndexOf ⟨key,accounts.key⟩,label⇐label,line⇐block.line}⟩}⍟valid @
        }¨keys
      }¨members
    }⍟(1=≠found) @
  }¨axisSpec
  AxisValues ← {𝕊 sectionName:
    {𝕊 i:
      selected ← ({(𝕩.axis≡sectionName) ∧ 𝕩.account_index=i}¨axisRows)/axisRows
      diagnostics∾↩AddIf ⟨1<≠selected,Diagnostic ⟨"household_account_axis_duplicate",0,"One Account may occur only once on one Household policy axis"⟩⟩
      labels ← {𝕩.label}¨selected
      value ← ""
      {𝕊:value↩⊑labels}⍟(0<≠labels) @
      value
    }¨accounts.index
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
    budget⇐{
      envelope_count⇐≠admittedEnvelopes,envelope_id⇐{𝕩.id}¨admittedEnvelopes,
      allocation_account_key⇐{𝕩.allocation_key}¨admittedEnvelopes,allocation_account_index⇐{𝕩.allocation_index}¨admittedEnvelopes,
      plan_destination_account_keys⇐{𝕩.plan_destination_keys}¨admittedEnvelopes,plan_destination_account_indices⇐{𝕩.plan_destination_indices}¨admittedEnvelopes,
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
