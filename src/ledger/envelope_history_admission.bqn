# Strict source-local admission for historical Envelope evidence co-located in
# canonical household.toml. Account and Plan references are retained as stable
# keys here; cross-source qualification belongs to the Household composition
# boundary that owns those admitted identity universes.

projection ← •Import "household_current_policy_projection.bqn"
dates ← •Import "date_ordinal.bqn"
lf ← @+10 ⋄ cr ← @+13 ⋄ space ← @+32 ⋄ tab ← @+9 ⋄ quote ← @+34 ⋄ hash ← ⊑"#"
empty ← ⟨⟩
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IsWhitespace ← {𝕊 c:(c=space) ∨ c=tab}
TrimLeft ← {𝕊 xs:prefix ← ∧`IsWhitespace¨xs ⋄ (+´prefix)↓xs}
TrimRight ← {𝕊 xs:⌽TrimLeft⌽xs}
Trim ← {TrimRight TrimLeft 𝕩}
SplitKeepEmpty ← {𝕊 sep‿text:groups ← (+`sep=text)⊔text ⋄ {(sep≠𝕩)/𝕩}¨groups}
FirstOrSpace ← {𝕊 text:⊑text∾⟨space⟩}
Diagnostic ← {𝕊 code‿line‿message:{severity⇐"error",stage⇐"ledger_envelope_history_admission",code⇐code,line⇐line,message⇐message}}
AddIf ← {𝕊 invalid‿diagnostic:invalid/⟨diagnostic⟩}

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

ParseString ← {𝕊 text:
  t ← Trim text ⋄ diagnostics ← empty ⋄ value ← ""
  enclosed ← (2≤≠t) ∧ (quote=FirstOrSpace t) ∧ quote=FirstOrSpace⌽t
  diagnostics∾↩AddIf ⟨¬enclosed,Diagnostic ⟨"envelope_history_string_invalid",0,"Envelope history string value must be quoted"⟩⟩
  {𝕊:value↩¯1↓1↓t}⍟enclosed @
  diagnostics∾↩AddIf ⟨enclosed ∧ ∨´0∾quote=value,Diagnostic ⟨"envelope_history_string_escape_unsupported",0,"Embedded quotes are not admitted"⟩⟩
  {ok⇐0=≠diagnostics,value⇐(0=≠diagnostics)/value,diagnostics⇐diagnostics}
}

SplitArrayItems ← {𝕊 inner:
  parts ← empty ⋄ current ← "" ⋄ inQuote ← 0
  {𝕊 c:
    separator ← (c=',') ∧ ¬inQuote
    {𝕊:parts∾↩⟨Trim current⟩ ⋄ current↩""}⍟separator @
    {𝕊:current∾↩⟨c⟩ ⋄ {𝕊:inQuote↩¬inQuote}⍟(c=quote) @}⍟(¬separator) @
  }¨inner
  tail ← Trim current
  {𝕊:parts∾↩⟨tail⟩}⍟(0<≠tail) @
  {parts⇐parts,invalid⇐inQuote}
}

ParseArray ← {𝕊 text:
  t ← Trim text ⋄ diagnostics ← empty ⋄ values ← empty
  enclosed ← (2≤≠t) ∧ ('['=FirstOrSpace t) ∧ ']'=FirstOrSpace⌽t
  diagnostics∾↩AddIf ⟨¬enclosed,Diagnostic ⟨"envelope_history_array_invalid",0,"Envelope identities must use a TOML array"⟩⟩
  {𝕊:
    inner ← Trim ¯1↓1↓t
    {𝕊:
      split ← SplitArrayItems inner
      diagnostics∾↩AddIf ⟨split.invalid,Diagnostic ⟨"envelope_history_array_invalid",0,"Envelope history array has unbalanced quoting"⟩⟩
      {𝕊 part:
        parsed ← ParseString part ⋄ diagnostics∾↩parsed.diagnostics
        {𝕊:values∾↩⟨parsed.value⟩}⍟parsed.ok @
      }¨split.parts
    }⍟(0<≠inner) @
  }⍟enclosed @
  {ok⇐0=≠diagnostics,values⇐(0=≠diagnostics)/values,diagnostics⇐diagnostics}
}

AtLine ← {𝕊 parsed‿lineNumber:{𝕊 d:{severity⇐d.severity,stage⇐d.stage,code⇐d.code,line⇐lineNumber,message⇐d.message}}¨parsed.diagnostics}
PairValue ← {𝕊 block‿key:
  matches ← ({𝕩.key≡key}¨block.pairs)/block.pairs
  result ← {found⇐0,text⇐"",line⇐block.line}
  {𝕊:p←⊑matches ⋄ result↩{found⇐1,text⇐p.text,line⇐p.line}}⍟(1=≠matches) @
  result
}
EmptyRegistry ← {𝕊:{count⇐0,index⇐empty,id⇐empty}}
EmptyExpense ← {𝕊:{count⇐0,index⇐empty,effective_from⇐empty,initial⇐empty,effective_ordinal⇐empty,expense_account_key⇐empty,route⇐empty,target_id⇐empty,note⇐empty,source_row⇐empty}}
EmptyFulfillment ← {𝕊:{count⇐0,index⇐empty,effective_from⇐empty,effective_ordinal⇐empty,plan_id⇐empty,route⇐empty,target_id⇐empty,note⇐empty,source_row⇐empty}}

Admit ← {𝕊 raw:
  source ← projection.EnvelopeHistory raw
  physicalLines ← SplitKeepEmpty ⟨lf,(cr≠source)/source⟩
  lines ← empty ⋄ lineRows ← empty ⋄ pending ← 0 ⋄ pendingText ← "" ⋄ pendingRow ← 0
  {𝕊 i:
    text ← Trim i⊑physicalLines ⋄ row ← i+1 ⋄ wasPending ← pending
    {𝕊:
      pendingText∾↩" "∾text
      {𝕊:lines∾↩⟨pendingText⟩ ⋄ lineRows∾↩⟨pendingRow⟩ ⋄ pending↩0 ⋄ pendingText↩""}⍟(ArrayClosed pendingText) @
    }⍟wasPending @
    {𝕊:
      equals ← '='=text ⋄ multiline ← 0
      {𝕊:p←⊑equals/↕≠text ⋄ value←Trim (p+1)↓text ⋄ multiline↩('['=FirstOrSpace value) ∧ ¬ArrayClosed value}⍟(1=+´equals) @
      {𝕊:pending↩1 ⋄ pendingText↩text ⋄ pendingRow↩row}⍟multiline @
      {𝕊:lines∾↩⟨text⟩ ⋄ lineRows∾↩⟨row⟩}⍟(¬multiline) @
    }⍟(¬wasPending) @
  }¨↕≠physicalLines
  {𝕊:lines∾↩⟨pendingText⟩ ⋄ lineRows∾↩⟨pendingRow⟩}⍟pending @

  diagnostics ← empty ⋄ blocks ← empty
  indices ← ↕≠lines
  ignored ← (0=≠¨lines) ∨ hash=FirstOrSpace¨lines
  HeaderShape ← {𝕊 text:
    n ← ≠text ⋄ first←FirstOrSpace text ⋄ last←FirstOrSpace⌽text
    firstTwo←2↑text∾2⥊space ⋄ lastTwo←2↑(⌽text)∾2⥊space
    array←(4≤n) ∧ ("[["≡firstTwo) ∧ ("]]"≡lastTwo)
    table←(2≤n) ∧ ('['=first) ∧ (']'=last) ∧ ¬array
    {array⇐array,table⇐table}
  }
  shapes ← HeaderShape¨lines ⋄ arrayHeader←{𝕩.array}¨shapes ⋄ tableHeader←{𝕩.table}¨shapes
  header ← arrayHeader ∨ tableHeader ⋄ segmentIds←+`header ⋄ segments←segmentIds⊔indices
  KnownSection ← {𝕊 name:Contains ⟨name,⟨"envelope-history","envelope-history.expense-routing","envelope-history.fulfillment-routing"⟩⟩}
  ParsePair ← {𝕊 sourceIndex:
    text←sourceIndex⊑lines ⋄ row←sourceIndex⊑lineRows ⋄ pair←empty ⋄ equals←'='=text
    diagnostics∾↩AddIf ⟨1≠+´equals,Diagnostic ⟨"envelope_history_key_shape_invalid",row,"Envelope history row requires exactly one equals separator"⟩⟩
    {𝕊:
      p←⊑equals/↕≠text ⋄ key←Trim p↑text ⋄ value←Trim (p+1)↓text ⋄ valid←(0<≠key) ∧ 0<≠value
      diagnostics∾↩AddIf ⟨¬valid,Diagnostic ⟨"envelope_history_key_shape_invalid",row,"Envelope history key and value must be nonempty"⟩⟩
      {𝕊:pair↩⟨{key⇐key,text⇐value,line⇐row}⟩}⍟valid @
    }⍟(1=+´equals) @
    pair
  }
  {𝕊 segmentIndex:
    segment←segmentIndex⊑segments
    {𝕊:
      headerIndex←⊑segment ⋄ headerText←headerIndex⊑lines ⋄ row←headerIndex⊑lineRows
      edge←1+headerIndex⊑arrayHeader ⋄ name←edge↓(-edge)↓headerText ⋄ known←KnownSection name
      diagnostics∾↩AddIf ⟨¬known,Diagnostic ⟨"envelope_history_section_unsupported",row,"Envelope history projection contains an unsupported section"⟩⟩
      tail←1↓segment ⋄ sourceIndices←(¬tail⊏ignored)/tail
      {𝕊:pairs←∾ParsePair¨sourceIndices ⋄ blocks∾↩⟨{kind⇐name,line⇐row,pairs⇐pairs}⟩}⍟known @
    }⍟(0<segmentIndex) @
  }¨↕≠segments

  Singles ← {𝕊 kind:({𝕩.kind≡kind}¨blocks)/blocks}
  CheckKeys ← {𝕊 block‿required‿optional:
    keys←{𝕩.key}¨block.pairs ⋄ allowed←required∾optional
    diagnostics∾↩AddIf ⟨(≠keys)≠≠⍷keys,Diagnostic ⟨"envelope_history_key_duplicate",block.line,"Envelope history section keys must be unique"⟩⟩
    diagnostics∾↩AddIf ⟨∨´0∾{¬Contains ⟨𝕩,allowed⟩}¨keys,Diagnostic ⟨"envelope_history_key_unsupported",block.line,"Envelope history section contains an unsupported key"⟩⟩
    diagnostics∾↩AddIf ⟨∨´0∾{¬Contains ⟨𝕩,keys⟩}¨required,Diagnostic ⟨"envelope_history_key_missing",block.line,"Envelope history section is missing a required key"⟩⟩
  }
  StringValue ← {𝕊 block‿key:
    pair←PairValue ⟨block,key⟩ ⋄ parsed←ParseString pair.text ⋄ diagnostics∾↩AtLine ⟨parsed,pair.line⟩ ⋄ parsed.value
  }
  OptionalString ← {𝕊 block‿key:
    pair←PairValue ⟨block,key⟩ ⋄ value←""
    {𝕊:parsed←ParseString pair.text ⋄ diagnostics∾↩AtLine ⟨parsed,pair.line⟩ ⋄ value↩parsed.value}⍟pair.found @
    value
  }

  rootBlocks←Singles "envelope-history" ⋄ expenseBlocks←Singles "envelope-history.expense-routing" ⋄ fulfillmentBlocks←Singles "envelope-history.fulfillment-routing"
  present←1=≠rootBlocks
  diagnostics∾↩AddIf ⟨1<≠rootBlocks,Diagnostic ⟨"envelope_history_section_cardinality_invalid",0,"Envelope history root may occur at most once"⟩⟩
  diagnostics∾↩AddIf ⟨(0=≠rootBlocks) ∧ 0<≠expenseBlocks∾fulfillmentBlocks,Diagnostic ⟨"envelope_history_root_missing",0,"Envelope routing sections require an envelope-history root"⟩⟩

  identities←empty ⋄ rootLine←0
  {𝕊:
    root←⊑rootBlocks ⋄ rootLine↩root.line ⋄ CheckKeys ⟨root,⟨"identities"⟩,empty⟩
    pair←PairValue ⟨root,"identities"⟩ ⋄ parsed←ParseArray pair.text ⋄ diagnostics∾↩AtLine ⟨parsed,pair.line⟩ ⋄ identities↩parsed.values
    diagnostics∾↩AddIf ⟨0=≠identities,Diagnostic ⟨"envelope_history_identity_missing",root.line,"Envelope history requires at least one stable identity"⟩⟩
    diagnostics∾↩AddIf ⟨∨´0∾0=≠¨identities,Diagnostic ⟨"envelope_history_identity_empty",root.line,"Envelope identities must be nonempty"⟩⟩
    diagnostics∾↩AddIf ⟨(≠identities)≠≠⍷identities,Diagnostic ⟨"envelope_history_identity_duplicate",root.line,"Envelope identities must be unique"⟩⟩
  }⍟present @

  ParseExpense ← {𝕊 block:
    before←≠diagnostics
    CheckKeys ⟨block,⟨"effective-from","expense-account","route","note"⟩,⟨"target"⟩⟩
    effective←StringValue ⟨block,"effective-from"⟩ ⋄ accountKey←StringValue ⟨block,"expense-account"⟩
    route←StringValue ⟨block,"route"⟩ ⋄ target←OptionalString ⟨block,"target"⟩ ⋄ note←StringValue ⟨block,"note"⟩
    initial←effective≡"initial" ⋄ dayValid←dates.IsValid effective ⋄ effectiveOk←initial ∨ dayValid
    routeOk←Contains ⟨route,⟨"managed","unmanaged"⟩⟩
    targetPresent←0<≠target ⋄ targetShapeOk←(route≡"managed")=targetPresent
    targetKnown←(¬targetPresent) ∨ Contains ⟨target,identities⟩
    diagnostics∾↩AddIf ⟨¬effectiveOk,Diagnostic ⟨"envelope_expense_routing_effective_invalid",block.line,"Expense routing effective-from must be initial or strict Gregorian text"⟩⟩
    diagnostics∾↩AddIf ⟨0=≠accountKey,Diagnostic ⟨"envelope_expense_routing_account_missing",block.line,"Expense routing Account key must be nonempty"⟩⟩
    diagnostics∾↩AddIf ⟨¬routeOk,Diagnostic ⟨"envelope_expense_routing_route_invalid",block.line,"Expense routing route must be managed or unmanaged"⟩⟩
    diagnostics∾↩AddIf ⟨routeOk ∧ ¬targetShapeOk,Diagnostic ⟨"envelope_expense_routing_target_shape_invalid",block.line,"managed routing requires target and unmanaged routing forbids target"⟩⟩
    diagnostics∾↩AddIf ⟨targetPresent ∧ ¬targetKnown,Diagnostic ⟨"envelope_expense_routing_target_unknown",block.line,"Expense routing target must name a stable Envelope identity"⟩⟩
    item←@
    {𝕊:
      ordinal←¯1 ⋄ {𝕊:ordinal↩dates.Ordinal effective}⍟dayValid @
      item↩{effective_from⇐effective,initial⇐initial,effective_ordinal⇐ordinal,expense_account_key⇐accountKey,route⇐route,target_id⇐target,note⇐note,source_row⇐block.line}
    }⍟(before=≠diagnostics) @
    item
  }

  ParseFulfillment ← {𝕊 block:
    before←≠diagnostics
    CheckKeys ⟨block,⟨"effective-from","plan-id","route","note"⟩,⟨"target"⟩⟩
    effective←StringValue ⟨block,"effective-from"⟩ ⋄ planId←StringValue ⟨block,"plan-id"⟩
    route←StringValue ⟨block,"route"⟩ ⋄ target←OptionalString ⟨block,"target"⟩ ⋄ note←StringValue ⟨block,"note"⟩
    dayValid←dates.IsValid effective ⋄ routeOk←Contains ⟨route,⟨"fulfills","not-target"⟩⟩
    targetPresent←0<≠target ⋄ targetShapeOk←(route≡"fulfills")=targetPresent
    targetKnown←(¬targetPresent) ∨ Contains ⟨target,identities⟩
    diagnostics∾↩AddIf ⟨¬dayValid,Diagnostic ⟨"envelope_fulfillment_routing_effective_invalid",block.line,"Fulfillment routing effective-from must be strict Gregorian text"⟩⟩
    diagnostics∾↩AddIf ⟨0=≠planId,Diagnostic ⟨"envelope_fulfillment_routing_plan_missing",block.line,"Fulfillment routing PlanId must be nonempty"⟩⟩
    diagnostics∾↩AddIf ⟨¬routeOk,Diagnostic ⟨"envelope_fulfillment_routing_route_invalid",block.line,"Fulfillment routing route must be fulfills or not-target"⟩⟩
    diagnostics∾↩AddIf ⟨routeOk ∧ ¬targetShapeOk,Diagnostic ⟨"envelope_fulfillment_routing_target_shape_invalid",block.line,"fulfills routing requires target and not-target routing forbids target"⟩⟩
    diagnostics∾↩AddIf ⟨targetPresent ∧ ¬targetKnown,Diagnostic ⟨"envelope_fulfillment_routing_target_unknown",block.line,"Fulfillment routing target must name a stable Envelope identity"⟩⟩
    item←@
    {𝕊:item↩{effective_from⇐effective,effective_ordinal⇐dates.Ordinal effective,plan_id⇐planId,route⇐route,target_id⇐target,note⇐note,source_row⇐block.line}}⍟((before=≠diagnostics) ∧ dayValid) @
    item
  }

  expenseItems←ParseExpense¨expenseBlocks ⋄ expenseRows←({𝕩≢@}¨expenseItems)/expenseItems
  fulfillmentItems←ParseFulfillment¨fulfillmentBlocks ⋄ fulfillmentRows←({𝕩≢@}¨fulfillmentItems)/fulfillmentItems
  expenseCoordinates←{𝕩.expense_account_key∾"\t"∾𝕩.effective_from}¨expenseRows
  fulfillmentCoordinates←{𝕩.plan_id∾"\t"∾𝕩.effective_from}¨fulfillmentRows
  diagnostics∾↩AddIf ⟨(≠expenseCoordinates)≠≠⍷expenseCoordinates,Diagnostic ⟨"envelope_expense_routing_duplicate",0,"Expense routing Account/effective coordinates must be unique"⟩⟩
  diagnostics∾↩AddIf ⟨(≠fulfillmentCoordinates)≠≠⍷fulfillmentCoordinates,Diagnostic ⟨"envelope_fulfillment_routing_duplicate",0,"Fulfillment routing PlanId/effective coordinates must be unique"⟩⟩

  registry←EmptyRegistry @ ⋄ expense←EmptyExpense @ ⋄ fulfillment←EmptyFulfillment @
  {𝕊:
    registry↩{count⇐≠identities,index⇐↕≠identities,id⇐identities}
    expense↩{count⇐≠expenseRows,index⇐↕≠expenseRows,effective_from⇐{𝕩.effective_from}¨expenseRows,initial⇐{𝕩.initial}¨expenseRows,effective_ordinal⇐{𝕩.effective_ordinal}¨expenseRows,expense_account_key⇐{𝕩.expense_account_key}¨expenseRows,route⇐{𝕩.route}¨expenseRows,target_id⇐{𝕩.target_id}¨expenseRows,note⇐{𝕩.note}¨expenseRows,source_row⇐{𝕩.source_row}¨expenseRows}
    fulfillment↩{count⇐≠fulfillmentRows,index⇐↕≠fulfillmentRows,effective_from⇐{𝕩.effective_from}¨fulfillmentRows,effective_ordinal⇐{𝕩.effective_ordinal}¨fulfillmentRows,plan_id⇐{𝕩.plan_id}¨fulfillmentRows,route⇐{𝕩.route}¨fulfillmentRows,target_id⇐{𝕩.target_id}¨fulfillmentRows,note⇐{𝕩.note}¨fulfillmentRows,source_row⇐{𝕩.source_row}¨fulfillmentRows}
  }⍟(0=≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",source_name⇐"household.toml",present⇐present,registry⇐registry,expense_routing⇐expense,fulfillment_routing⇐fulfillment,diagnostics⇐diagnostics}
}

{Admit⇐Admit}
