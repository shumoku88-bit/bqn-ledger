# Strict BQN-native admission for the retained budget.toml policy subset.
#
# Canonical policy syntax is the deterministic shape shared with h-kernel:
# [[backing-pools]] with id + asset-accounts, and [[envelopes]] with
# id + label + pacing + backing-pool + expense-accounts. This module owns no
# path, writer, fallback, or Household allocation-account policy.

lf ← @+10
cr ← @+13
space ← @+32
tab ← @+9
quote ← @+34
slash ← @+92
hash ← ⊑"#"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IndexOf ← {𝕊 item‿items: ⊑items⊐⟨item⟩}
IsWhitespace ← {𝕊 c: (c=space) ∨ c=tab}
TrimLeft ← {𝕊 xs: prefix ← ∧`IsWhitespace¨xs ⋄ (+´prefix)↓xs}
TrimRight ← {𝕊 xs: ⌽TrimLeft⌽xs}
Trim ← {TrimRight TrimLeft 𝕩}
SplitKeepEmpty ← {𝕊 sep‿text: groups ← (+`sep=text)⊔text ⋄ {(sep≠𝕩)/𝕩}¨groups}
StartsWith ← {𝕊 prefix‿text: prefix≡(≠prefix)↑text}
NoWhitespace ← {𝕊 value: (0<≠value) ∧ ¬∨´0∾IsWhitespace¨value}

Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {severity⇐"error",stage⇐"ledger_budget_policy_admission",code⇐codeText,line⇐lineNumber,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}

ParseString ← {𝕊 text:
  value ← "" ⋄ diagnostics ← empty
  t ← Trim text
  enclosed ← (2≤≠t) ∧ (quote=⊑(t∾" ")) ∧ quote=⊑⌽(t∾" ")
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
  parts ← empty ⋄ current ← "" ⋄ inQuote ← 0 ⋄ escaped ← 0 ⋄ invalid ← 0
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
  {𝕊:parts∾↩⟨Trim current⟩}⍟(0<≠Trim current) @
  invalid↩inQuote ∨ escaped
  {parts⇐parts,invalid⇐invalid}
}

ParseStringArray ← {𝕊 text:
  values ← empty ⋄ diagnostics ← empty
  t ← Trim text
  enclosed ← (2≤≠t) ∧ ('['=⊑(t∾" ")) ∧ ']'=⊑⌽(t∾" ")
  diagnostics∾↩AddIf ⟨¬enclosed,Diagnostic ⟨"budget_policy_array_invalid",0,"policy Account list must use a TOML array"⟩⟩
  {𝕊:
    inner ← Trim (¯1↓1↓t)
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

Admit ← {𝕊 raw‿accounts:
  normalized ← (cr≠raw)/raw
  lines ← SplitKeepEmpty ⟨lf,normalized⟩
  diagnostics ← empty ⋄ blocks ← empty
  active ← 0 ⋄ activeKind ← "" ⋄ activeLine ← 0 ⋄ activePairs ← empty
  Finalize ← {𝕊:
    {𝕊:blocks∾↩⟨{kind⇐activeKind,line⇐activeLine,pairs⇐activePairs}⟩}⍟active @
    active↩0 ⋄ activeKind↩"" ⋄ activeLine↩0 ⋄ activePairs↩empty
  }
  {𝕊 i:
    line ← Trim i⊑lines ⋄ row ← i+1
    ignored ← (0=≠line) ∨ ((0<≠line) ∧ hash=⊑line)
    {𝕊:
      poolHeader ← line≡"[[backing-pools]]"
      envelopeHeader ← line≡"[[envelopes]]"
      header ← poolHeader ∨ envelopeHeader
      {𝕊:
        Finalize @
        active↩1 ⋄ activeLine↩row
        activeKind↩poolHeader⊑⟨"envelope","backing-pool"⟩
      }⍟header @
      {𝕊:
        diagnostics∾↩AddIf ⟨¬active,Diagnostic ⟨"budget_policy_key_outside_table",row,"policy key must occur inside a canonical array-of-tables block"⟩⟩
        {𝕊:
          equals ← '='=line
          diagnostics∾↩AddIf ⟨1≠+´equals,Diagnostic ⟨"budget_policy_key_shape_invalid",row,"policy row requires exactly one equals separator"⟩⟩
          {𝕊:
            p ← ⊑equals/↕≠line
            key ← Trim p↑line ⋄ value ← Trim (p+1)↓line
            diagnostics∾↩AddIf ⟨(0=≠key) ∨ 0=≠value,Diagnostic ⟨"budget_policy_key_shape_invalid",row,"policy key and value must be nonempty"⟩⟩
            {𝕊:activePairs∾↩⟨{key⇐key,text⇐value,line⇐row}⟩}⍟((0<≠key) ∧ 0<≠value) @
          }⍟(1=+´equals) @
        }⍟active @
      }⍟(¬header) @
    }⍟(¬ignored) @
  }¨↕≠lines
  Finalize @

  pools ← empty ⋄ envelopes ← empty
  {𝕊 block:
    allowed ← (block.kind≡"backing-pool")⊑⟨⟨"id","label","pacing","backing-pool","expense-accounts"⟩,⟨"id","asset-accounts"⟩⟩
    keys ← {𝕩.key}¨block.pairs
    diagnostics∾↩AddIf ⟨(≠keys)≠≠⍷keys,Diagnostic ⟨"budget_policy_key_duplicate",block.line,"policy table keys must be unique"⟩⟩
    diagnostics∾↩AddIf ⟨∨´0∾{¬Contains ⟨𝕩,allowed⟩}¨keys,Diagnostic ⟨"budget_policy_key_unsupported",block.line,"policy table contains an unsupported key"⟩⟩
    required ← allowed
    diagnostics∾↩AddIf ⟨∨´0∾{¬Contains ⟨𝕩,keys⟩}¨required,Diagnostic ⟨"budget_policy_key_missing",block.line,"policy table is missing a required key"⟩⟩
    {𝕊:
      idPair ← PairValue ⟨block,"id"⟩ ⋄ idParsed ← ParseString idPair.text
      diagnostics∾↩{𝕊 d:{severity⇐d.severity,stage⇐d.stage,code⇐d.code,line⇐idPair.line,message⇐d.message}}¨idParsed.diagnostics
      accountsPair ← PairValue ⟨block,"asset-accounts"⟩ ⋄ accountsParsed ← ParseStringArray accountsPair.text
      diagnostics∾↩{𝕊 d:{severity⇐d.severity,stage⇐d.stage,code⇐d.code,line⇐accountsPair.line,message⇐d.message}}¨accountsParsed.diagnostics
      diagnostics∾↩AddIf ⟨idParsed.ok ∧ ¬NoWhitespace idParsed.value,Diagnostic ⟨"backing_pool_id_invalid",idPair.line,"backing pool id must be nonempty and contain no whitespace"⟩⟩
      diagnostics∾↩AddIf ⟨accountsParsed.ok ∧ 0=≠accountsParsed.values,Diagnostic ⟨"backing_pool_accounts_empty",accountsPair.line,"backing pool requires at least one Asset Account"⟩⟩
      {𝕊:pools∾↩⟨{id⇐idParsed.value,asset_account_keys⇐accountsParsed.values,line⇐block.line}⟩}⍟(idParsed.ok ∧ accountsParsed.ok ∧ NoWhitespace idParsed.value ∧ 0<≠accountsParsed.values) @
    }⍟((block.kind≡"backing-pool") ∧ 0=≠diagnostics) @
    {𝕊:
      idPair ← PairValue ⟨block,"id"⟩ ⋄ idParsed ← ParseString idPair.text
      labelPair ← PairValue ⟨block,"label"⟩ ⋄ labelParsed ← ParseString labelPair.text
      pacingPair ← PairValue ⟨block,"pacing"⟩ ⋄ pacingParsed ← ParseString pacingPair.text
      poolPair ← PairValue ⟨block,"backing-pool"⟩ ⋄ poolParsed ← ParseString poolPair.text
      expensePair ← PairValue ⟨block,"expense-accounts"⟩ ⋄ expenseParsed ← ParseStringArray expensePair.text
      parsed ← ⟨idParsed,labelParsed,pacingParsed,poolParsed,expenseParsed⟩
      pairLines ← ⟨idPair.line,labelPair.line,pacingPair.line,poolPair.line,expensePair.line⟩
      {𝕊 j:
        diagnostics∾↩{𝕊 d:{severity⇐d.severity,stage⇐d.stage,code⇐d.code,line⇐j⊑pairLines,message⇐d.message}}¨(j⊑parsed).diagnostics
      }¨↕≠parsed
      diagnostics∾↩AddIf ⟨idParsed.ok ∧ ¬NoWhitespace idParsed.value,Diagnostic ⟨"envelope_id_invalid",idPair.line,"envelope id must be nonempty and contain no whitespace"⟩⟩
      diagnostics∾↩AddIf ⟨labelParsed.ok ∧ (0=≠labelParsed.value ∨ labelParsed.value≢Trim labelParsed.value),Diagnostic ⟨"envelope_label_invalid",labelPair.line,"envelope label must be nonempty without surrounding whitespace"⟩⟩
      diagnostics∾↩AddIf ⟨pacingParsed.ok ∧ ¬Contains ⟨pacingParsed.value,⟨"daily","flex"⟩⟩,Diagnostic ⟨"envelope_pacing_invalid",pacingPair.line,"envelope pacing must be daily or flex"⟩⟩
      diagnostics∾↩AddIf ⟨poolParsed.ok ∧ ¬NoWhitespace poolParsed.value,Diagnostic ⟨"envelope_backing_pool_invalid",poolPair.line,"backing pool reference must be nonempty and contain no whitespace"⟩⟩
      allOk ← ∧´{𝕩.ok}¨parsed
      {𝕊:envelopes∾↩⟨{
        id⇐idParsed.value,label⇐labelParsed.value,pacing⇐pacingParsed.value,
        backing_pool⇐poolParsed.value,expense_account_keys⇐expenseParsed.values,line⇐block.line
      }⟩}⍟(allOk ∧ NoWhitespace idParsed.value ∧ NoWhitespace poolParsed.value ∧ Contains ⟨pacingParsed.value,⟨"daily","flex"⟩⟩) @
    }⍟((block.kind≡"envelope") ∧ 0=≠diagnostics) @
  }¨blocks

  diagnostics∾↩AddIf ⟨0=≠pools,Diagnostic ⟨"budget_policy_backing_pools_missing",0,"budget.toml requires at least one backing pool"⟩⟩
  diagnostics∾↩AddIf ⟨0=≠envelopes,Diagnostic ⟨"budget_policy_envelopes_missing",0,"budget.toml requires at least one spendable envelope"⟩⟩
  poolIds ← {𝕩.id}¨pools ⋄ envelopeIds ← {𝕩.id}¨envelopes ⋄ labels ← {𝕩.label}¨envelopes
  diagnostics∾↩AddIf ⟨(≠poolIds)≠≠⍷poolIds,Diagnostic ⟨"backing_pool_id_duplicate",0,"backing pool ids must be unique"⟩⟩
  diagnostics∾↩AddIf ⟨(≠envelopeIds)≠≠⍷envelopeIds,Diagnostic ⟨"envelope_id_duplicate",0,"envelope ids must be unique"⟩⟩
  diagnostics∾↩AddIf ⟨(≠labels)≠≠⍷labels,Diagnostic ⟨"envelope_label_duplicate",0,"envelope labels must be unique"⟩⟩
  {𝕊 envelope:
    diagnostics∾↩AddIf ⟨¬Contains ⟨envelope.backing_pool,poolIds⟩,Diagnostic ⟨"envelope_backing_pool_unknown",envelope.line,"envelope must reference a declared backing pool"⟩⟩
  }¨envelopes

  expenseKeys ← ∾{𝕩.expense_account_keys}¨envelopes
  assetKeys ← ∾{𝕩.asset_account_keys}¨pools
  diagnostics∾↩AddIf ⟨(≠expenseKeys)≠≠⍷expenseKeys,Diagnostic ⟨"expense_account_assignment_duplicate",0,"one Expense Account may belong to only one envelope"⟩⟩
  diagnostics∾↩AddIf ⟨(≠assetKeys)≠≠⍷assetKeys,Diagnostic ⟨"asset_account_membership_duplicate",0,"one Asset Account may belong to only one backing pool"⟩⟩

  expenseIndices ← empty ⋄ expenseEnvelope ← empty
  {𝕊 envelope:
    {𝕊 key:
      i ← IndexOf ⟨key,accounts.key⟩ ⋄ known ← i<accounts.count
      diagnostics∾↩AddIf ⟨¬known,Diagnostic ⟨"budget_policy_expense_account_unknown",envelope.line,"Envelope Expense Account must be declared"⟩⟩
      diagnostics∾↩AddIf ⟨known ∧ (i⊑accounts.role)≢"expense",Diagnostic ⟨"budget_policy_expense_account_role_invalid",envelope.line,"Envelope Expense Account must have Expense type"⟩⟩
      {𝕊:expenseIndices∾↩⟨i⟩ ⋄ expenseEnvelope∾↩⟨envelope.id⟩}⍟(known ∧ (i⊑accounts.role)≡"expense") @
    }¨envelope.expense_account_keys
  }¨envelopes
  assetIndices ← empty ⋄ assetPool ← empty
  {𝕊 pool:
    {𝕊 key:
      i ← IndexOf ⟨key,accounts.key⟩ ⋄ known ← i<accounts.count
      diagnostics∾↩AddIf ⟨¬known,Diagnostic ⟨"budget_policy_asset_account_unknown",pool.line,"Backing pool Asset Account must be declared"⟩⟩
      diagnostics∾↩AddIf ⟨known ∧ (i⊑accounts.role)≢"asset",Diagnostic ⟨"budget_policy_asset_account_role_invalid",pool.line,"Backing pool Account must have Asset type"⟩⟩
      {𝕊:assetIndices∾↩⟨i⟩ ⋄ assetPool∾↩⟨pool.id⟩}⍟(known ∧ (i⊑accounts.role)≡"asset") @
    }¨pool.asset_account_keys
  }¨pools

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
      backing_pool⇐{𝕩.backing_pool}¨admittedEnvelopes,
      expense_account_keys⇐{𝕩.expense_account_keys}¨admittedEnvelopes
    },
    expense_account_index⇐ok/expenseIndices,expense_envelope_id⇐ok/expenseEnvelope,
    asset_account_index⇐ok/assetIndices,asset_backing_pool_id⇐ok/assetPool,
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}
