# Strict BQN-native admission for current budget.toml Envelope and Backing policy.
#
# Canonical syntax is the deterministic shape shared with h-kernel:
# [[backing-pools]] with id + asset-accounts, and [[envelopes]] with
# id + label + pacing + backing-pool. Expense routing is historical evidence
# owned by household.toml, never reconstructed from this current policy.

lf ← @+10
cr ← @+13
space ← @+32
tab ← @+9
quote ← @+34
slash ← @+92
hash ← ⊑"#"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IsWhitespace ← {𝕊 c: (c=space) ∨ c=tab}
TrimLeft ← {𝕊 xs: prefix ← ∧`IsWhitespace¨xs ⋄ (+´prefix)↓xs}
TrimRight ← {𝕊 xs: ⌽TrimLeft⌽xs}
Trim ← {TrimRight TrimLeft 𝕩}
SplitKeepEmpty ← {𝕊 sep‿text: groups ← (+`sep=text)⊔text ⋄ {(sep≠𝕩)/𝕩}¨groups}
NoWhitespace ← {𝕊 value: (0<≠value) ∧ ¬∨´0∾IsWhitespace¨value}
FirstOrSpace ← {𝕊 text: ⊑text∾⟨space⟩}

ArrayClosed ← {𝕊 text:
  inQuote ← 0 ⋄ escaped ← 0 ⋄ closed ← 0
  {𝕊 c:
    wasInQuote ← inQuote ⋄ wasEscaped ← escaped
    {𝕊:
      {𝕊:escaped↩0}⍟wasEscaped @
      {𝕊:
        {𝕊:escaped↩1}⍟(c=slash) @
        {𝕊:inQuote↩0}⍟(c=quote) @
      }⍟(¬wasEscaped) @
    }⍟wasInQuote @
    {𝕊:
      {𝕊:inQuote↩1}⍟(c=quote) @
      {𝕊:closed↩1}⍟(c=']') @
    }⍟(¬wasInQuote) @
  }¨text
  closed ∧ ¬inQuote ∧ ¬escaped
}

Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {severity⇐"error",stage⇐"ledger_budget_policy_admission",code⇐codeText,line⇐lineNumber,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}

ParseString ← {𝕊 text:
  value ← "" ⋄ diagnostics ← empty
  t ← Trim text
  first ← FirstOrSpace t
  last ← FirstOrSpace ⌽t
  enclosed ← (2≤≠t) ∧ (quote=first) ∧ quote=last
  diagnostics∾↩AddIf ⟨¬enclosed,Diagnostic ⟨"budget_policy_string_invalid",0,"policy string value must be quoted"⟩⟩
  {𝕊:
    body ← ¯1↓1↓t
    escaped ← 0 ⋄ invalid ← 0
    {𝕊 c:
      {𝕊:
        supported ← (c=quote) ∨ c=slash
        {𝕊:value∾↩⟨c⟩}⍟supported @
        {𝕊:invalid↩1}⍟(¬supported) @
        escaped↩0
      }⍟escaped @
      {𝕊:
        {𝕊:escaped↩1}⍟(c=slash) @
        {𝕊:invalid↩1}⍟(c=quote) @
        {𝕊:value∾↩⟨c⟩}⍟((c≠slash) ∧ c≠quote) @
      }⍟(¬escaped) @
    }¨body
    invalid ∨↩ escaped
    diagnostics∾↩AddIf ⟨invalid,Diagnostic ⟨"budget_policy_string_escape_invalid",0,"policy string contains an unsupported escape or quote"⟩⟩
  }⍟enclosed @
  {ok⇐0=≠diagnostics,value⇐(0=≠diagnostics)/value,diagnostics⇐diagnostics}
}

SplitArrayItems ← {𝕊 inner:
  parts ← empty ⋄ current ← "" ⋄ inQuote ← 0 ⋄ escaped ← 0
  {𝕊 c:
    separator ← (c=',') ∧ ¬inQuote
    {𝕊:parts∾↩⟨Trim current⟩ ⋄ current↩""}⍟separator @
    {𝕊:current∾↩⟨c⟩}⍟(¬separator) @
    {𝕊:
      {𝕊:escaped↩0}⍟escaped @
      {𝕊:
        {𝕊:escaped↩1}⍟(c=slash) @
        {𝕊:inQuote↩¬inQuote}⍟(c=quote) @
      }⍟(¬escaped) @
    }⍟(¬separator) @
  }¨inner
  trimmed ← Trim current
  {𝕊:parts∾↩⟨trimmed⟩}⍟(0<≠trimmed) @
  {parts⇐parts,invalid⇐inQuote ∨ escaped}
}

ParseStringArray ← {𝕊 text:
  values ← empty ⋄ diagnostics ← empty
  t ← Trim text
  first ← FirstOrSpace t
  last ← FirstOrSpace ⌽t
  enclosed ← (2≤≠t) ∧ ('['=first) ∧ ']'=last
  diagnostics∾↩AddIf ⟨¬enclosed,Diagnostic ⟨"budget_policy_array_invalid",0,"policy Account list must use a TOML array"⟩⟩
  {𝕊:
    inner ← Trim ¯1↓1↓t
    {𝕊:
      split ← SplitArrayItems inner
      diagnostics∾↩AddIf ⟨split.invalid,Diagnostic ⟨"budget_policy_array_invalid",0,"policy Account list has unbalanced quoting"⟩⟩
      {𝕊 part:
        parsed ← ParseString part
        diagnostics∾↩parsed.diagnostics
        {𝕊:values∾↩⟨parsed.value⟩}⍟parsed.ok @
      }¨split.parts
    }⍟(0<≠inner) @
  }⍟enclosed @
  {ok⇐0=≠diagnostics,values⇐(0=≠diagnostics)/values,diagnostics⇐diagnostics}
}

PairValue ← {𝕊 block‿key:
  matches ← ({𝕩.key≡key}¨block.pairs)/block.pairs
  result ← {found⇐0,text⇐"",line⇐block.line}
  {𝕊:pair←⊑matches ⋄ result↩{found⇐1,text⇐pair.text,line⇐pair.line}}⍟(1=≠matches) @
  result
}

AtLine ← {𝕊 parsed‿lineNumber:
  {𝕊 d:{severity⇐d.severity,stage⇐d.stage,code⇐d.code,line⇐lineNumber,message⇐d.message}}¨parsed.diagnostics
}

Admit ← {𝕊 raw‿accounts:
  normalized ← (cr≠raw)/raw
  physicalLines ← SplitKeepEmpty ⟨lf,normalized⟩
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

  indices ← ↕≠lines
  ignored ← (0=≠¨lines) ∨ hash=FirstOrSpace¨lines
  poolHeader ← {𝕩≡"[[backing-pools]]"}¨lines
  envelopeHeader ← {𝕩≡"[[envelopes]]"}¨lines
  header ← poolHeader ∨ envelopeHeader
  segmentIds ← +`header
  segments ← segmentIds⊔indices

  ParsePair ← {𝕊 sourceIndex:
    line ← sourceIndex⊑lines
    row ← sourceIndex⊑lineRows
    diagnostics ← empty
    pair ← @
    equals ← '='=line
    diagnostics∾↩AddIf ⟨1≠+´equals,Diagnostic ⟨"budget_policy_key_shape_invalid",row,"policy row requires exactly one equals separator"⟩⟩
    {𝕊:
      p ← ⊑equals/↕≠line
      key ← Trim p↑line ⋄ value ← Trim (p+1)↓line
      validPair ← (0<≠key) ∧ 0<≠value
      diagnostics∾↩AddIf ⟨¬validPair,Diagnostic ⟨"budget_policy_key_shape_invalid",row,"policy key and value must be nonempty"⟩⟩
      {𝕊:pair↩{key⇐key,text⇐value,line⇐row}}⍟validPair @
    }⍟(1=+´equals) @
    {diagnostics⇐diagnostics,pair⇐pair}
  }

  ParseSegment ← {𝕊 segment:
    diagnostics ← empty
    block ← @
    {𝕊:
      first ← ⊑segment
      tableSegment ← first⊑header
      {𝕊:
        pairIndices ← ((¬segment⊏ignored) ∧ ¬segment⊏header)/segment
        parsedPairs ← ParsePair¨pairIndices
        diagnostics∾↩∾⟨empty⟩∾{𝕩.diagnostics}¨parsedPairs
        pairItems ← {𝕩.pair}¨parsedPairs
        pairs ← ({𝕩≢@}¨pairItems)/pairItems
        kind ← (first⊑poolHeader)⊑⟨"envelope","backing-pool"⟩
        block↩{kind⇐kind,line⇐first⊑lineRows,pairs⇐pairs}
      }⍟tableSegment @
      {𝕊:
        outside ← (¬segment⊏ignored)/segment
        diagnostics∾↩{𝕊 sourceIndex:
          Diagnostic ⟨"budget_policy_key_outside_table",sourceIndex⊑lineRows,"policy key must occur inside a canonical array-of-tables block"⟩
        }¨outside
      }⍟(¬tableSegment) @
    }⍟(0<≠segment) @
    {diagnostics⇐diagnostics,block⇐block}
  }

  parsedSegments ← ParseSegment¨segments
  diagnostics ← ∾⟨empty⟩∾{𝕩.diagnostics}¨parsedSegments
  blockItems ← {𝕩.block}¨parsedSegments
  blocks ← ({𝕩≢@}¨blockItems)/blockItems

  pools ← empty ⋄ envelopes ← empty
  {𝕊 block:
    poolBlock ← block.kind≡"backing-pool"
    allowed ← poolBlock⊑⟨⟨"id","label","pacing","backing-pool"⟩,⟨"id","asset-accounts"⟩⟩
    keys ← {𝕩.key}¨block.pairs
    diagnostics∾↩AddIf ⟨(≠keys)≠≠⍷keys,Diagnostic ⟨"budget_policy_key_duplicate",block.line,"policy table keys must be unique"⟩⟩
    diagnostics∾↩AddIf ⟨∨´0∾{¬Contains ⟨𝕩,allowed⟩}¨keys,Diagnostic ⟨"budget_policy_key_unsupported",block.line,"policy table contains an unsupported key"⟩⟩
    diagnostics∾↩AddIf ⟨∨´0∾{¬Contains ⟨𝕩,keys⟩}¨allowed,Diagnostic ⟨"budget_policy_key_missing",block.line,"policy table is missing a required key"⟩⟩
    blockClean ← 0=≠diagnostics
    {𝕊:
      idPair ← PairValue ⟨block,"id"⟩ ⋄ idParsed ← ParseString idPair.text
      accountsPair ← PairValue ⟨block,"asset-accounts"⟩ ⋄ accountsParsed ← ParseStringArray accountsPair.text
      diagnostics∾↩AtLine ⟨idParsed,idPair.line⟩
      diagnostics∾↩AtLine ⟨accountsParsed,accountsPair.line⟩
      validId ← idParsed.ok ∧ NoWhitespace idParsed.value
      nonemptyAccounts ← accountsParsed.ok ∧ 0<≠accountsParsed.values
      diagnostics∾↩AddIf ⟨¬validId,Diagnostic ⟨"backing_pool_id_invalid",idPair.line,"backing pool id must be nonempty and contain no whitespace"⟩⟩
      diagnostics∾↩AddIf ⟨¬nonemptyAccounts,Diagnostic ⟨"backing_pool_accounts_empty",accountsPair.line,"backing pool requires at least one Asset Account"⟩⟩
      {𝕊:pools∾↩⟨{id⇐idParsed.value,asset_account_keys⇐accountsParsed.values,line⇐block.line}⟩}⍟(validId ∧ nonemptyAccounts) @
    }⍟(poolBlock ∧ blockClean) @
    {𝕊:
      idPair ← PairValue ⟨block,"id"⟩ ⋄ idParsed ← ParseString idPair.text
      labelPair ← PairValue ⟨block,"label"⟩ ⋄ labelParsed ← ParseString labelPair.text
      pacingPair ← PairValue ⟨block,"pacing"⟩ ⋄ pacingParsed ← ParseString pacingPair.text
      poolPair ← PairValue ⟨block,"backing-pool"⟩ ⋄ poolParsed ← ParseString poolPair.text
      parsed ← ⟨idParsed,labelParsed,pacingParsed,poolParsed⟩
      pairLines ← ⟨idPair.line,labelPair.line,pacingPair.line,poolPair.line⟩
      {𝕊 j: diagnostics∾↩AtLine ⟨j⊑parsed,j⊑pairLines⟩}¨↕≠parsed
      validId ← idParsed.ok ∧ NoWhitespace idParsed.value
      validLabel ← labelParsed.ok ∧ (0<≠labelParsed.value) ∧ labelParsed.value≡Trim labelParsed.value
      validPacing ← pacingParsed.ok ∧ Contains ⟨pacingParsed.value,⟨"daily","flex"⟩⟩
      validPool ← poolParsed.ok ∧ NoWhitespace poolParsed.value
      diagnostics∾↩AddIf ⟨¬validId,Diagnostic ⟨"envelope_id_invalid",idPair.line,"envelope id must be nonempty and contain no whitespace"⟩⟩
      diagnostics∾↩AddIf ⟨¬validLabel,Diagnostic ⟨"envelope_label_invalid",labelPair.line,"envelope label must be nonempty without surrounding whitespace"⟩⟩
      diagnostics∾↩AddIf ⟨¬validPacing,Diagnostic ⟨"envelope_pacing_invalid",pacingPair.line,"envelope pacing must be daily or flex"⟩⟩
      diagnostics∾↩AddIf ⟨¬validPool,Diagnostic ⟨"envelope_backing_pool_invalid",poolPair.line,"backing pool reference must be nonempty and contain no whitespace"⟩⟩
      allOk ← ∧´{𝕩.ok}¨parsed
      {𝕊:envelopes∾↩⟨{
        id⇐idParsed.value,label⇐labelParsed.value,pacing⇐pacingParsed.value,
        backing_pool⇐poolParsed.value,line⇐block.line
      }⟩}⍟(allOk ∧ validId ∧ validLabel ∧ validPacing ∧ validPool) @
    }⍟((¬poolBlock) ∧ blockClean) @
  }¨blocks

  diagnostics∾↩AddIf ⟨0=≠pools,Diagnostic ⟨"budget_policy_backing_pools_missing",0,"budget.toml requires at least one backing pool"⟩⟩
  diagnostics∾↩AddIf ⟨0=≠envelopes,Diagnostic ⟨"budget_policy_envelopes_missing",0,"budget.toml requires at least one spendable envelope"⟩⟩
  poolIds ← {𝕩.id}¨pools ⋄ envelopeIds ← {𝕩.id}¨envelopes ⋄ labels ← {𝕩.label}¨envelopes
  diagnostics∾↩AddIf ⟨(≠poolIds)≠≠⍷poolIds,Diagnostic ⟨"backing_pool_id_duplicate",0,"backing pool ids must be unique"⟩⟩
  diagnostics∾↩AddIf ⟨(≠envelopeIds)≠≠⍷envelopeIds,Diagnostic ⟨"envelope_id_duplicate",0,"envelope ids must be unique"⟩⟩
  diagnostics∾↩AddIf ⟨(≠labels)≠≠⍷labels,Diagnostic ⟨"envelope_label_duplicate",0,"envelope labels must be unique"⟩⟩

  envelopePoolKeys ← {𝕩.backing_pool}¨envelopes
  poolCoordinates ← poolIds⊐envelopePoolKeys
  poolKnown ← poolCoordinates<≠poolIds
  diagnostics∾↩{𝕊 envelope:
    Diagnostic ⟨"envelope_backing_pool_unknown",envelope.line,"envelope must reference a declared backing pool"⟩
  }¨(¬poolKnown)/envelopes

  assetLists ← {𝕩.asset_account_keys}¨pools
  assetCounts ← ≠¨assetLists
  assetKeys ← ∾assetLists
  assetLines ← assetCounts/({𝕩.line}¨pools)
  diagnostics∾↩AddIf ⟨(≠assetKeys)≠≠⍷assetKeys,Diagnostic ⟨"asset_account_membership_duplicate",0,"one Asset Account may belong to only one backing pool"⟩⟩

  assetAccountIndices ← accounts.key⊐assetKeys
  assetKnown ← assetAccountIndices<accounts.count
  assetRoles ← assetAccountIndices⊏(accounts.role∾⟨""⟩)
  assetRoleValid ← {𝕩≡"asset"}¨assetRoles
  assetWrongRole ← assetKnown ∧ ¬assetRoleValid
  assetDiagnostics ← ∾⟨empty⟩∾{𝕊 i:
    line ← i⊑assetLines
    known ← i⊑assetKnown
    wrongRole ← i⊑assetWrongRole
    unknownDiagnostic ← AddIf ⟨¬known,Diagnostic ⟨"budget_policy_asset_account_unknown",line,"Backing pool Asset Account must be declared"⟩⟩
    roleDiagnostic ← AddIf ⟨wrongRole,Diagnostic ⟨"budget_policy_asset_account_role_invalid",line,"Backing pool Account must have Asset type"⟩⟩
    unknownDiagnostic∾roleDiagnostic
  }¨↕≠assetKeys
  diagnostics∾↩assetDiagnostics

  ok ← 0=≠diagnostics
  admittedPools ← ok/pools ⋄ admittedEnvelopes ← ok/envelopes
  {
    state⇐ok⊑"error"‿"ok",source_name⇐"budget.toml",
    backing_pools⇐{
      count⇐≠admittedPools,index⇐↕≠admittedPools,id⇐{𝕩.id}¨admittedPools,
      asset_account_keys⇐{𝕩.asset_account_keys}¨admittedPools
    },
    envelopes⇐{
      count⇐≠admittedEnvelopes,index⇐↕≠admittedEnvelopes,id⇐{𝕩.id}¨admittedEnvelopes,
      label⇐{𝕩.label}¨admittedEnvelopes,pacing⇐{𝕩.pacing}¨admittedEnvelopes,
      backing_pool⇐{𝕩.backing_pool}¨admittedEnvelopes
    },
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}