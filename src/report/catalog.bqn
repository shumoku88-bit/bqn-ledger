# Pure static retained destination catalog. Listing reads no household source.

empty ← ⟨⟩

keys ← ⟨
  "envelopes","balances","balance-sheet","profit-and-loss","recent","planned",
  "cycle-accounts","cycle-comparison","monthly-accounts","daily-flow","daily-target","issues"
⟩
labels ← ⟨
  "Envelope & Backing","Account Balances","Balance Sheet","Profit and Loss","Recent Journal","Planned Payments",
  "Current-cycle Accounts","Cycle Comparison","Monthly Accounts","Daily Flow","Daily Target","Issues"
⟩
categories ← ⟨
  "household","accounting","accounting","accounting","operations","operations",
  "accounting","accounting","accounting","accounting","household","operations"
⟩
owners ← ⟨
  "src/sections/envelope_backing.bqn","src/sections/account_balances.bqn","src/sections/balance_sheet.bqn",
  "src/sections/profit_and_loss.bqn","src/sections/recent_journal.bqn","src/sections/planned_payments.bqn",
  "src/sections/cycle_accounts.bqn","src/sections/cycle_comparison.bqn","src/sections/monthly_accounts.bqn",
  "src/sections/daily_flow.bqn","src/sections/daily_target.bqn","src/sections/issues.bqn"
⟩
shapes ← ⟨"statement","matrix","statement","statement","list","list_card","matrix","matrix","matrix","matrix","card_projection","list"⟩
human ← 12⥊1
compact ← ⟨1,1,0,0,1,1,0,0,0,0,1,0⟩
json ← ⟨1,1,0,0,0,1,0,0,0,0,0,0⟩

relation ← {
  count⇐≠keys,index⇐↕≠keys,key⇐keys,label⇐labels,category⇐categories,owner⇐owners,shape⇐shapes,
  human⇐human,compact⇐compact,json⇐json
}
Row ← {𝕊 i:
  {
    key⇐i⊑relation.key,label⇐i⊑relation.label,category⇐i⊑relation.category,owner⇐i⊑relation.owner,shape⇐i⊑relation.shape,
    human⇐i⊑relation.human,compact⇐i⊑relation.compact,json⇐i⊑relation.json
  }
}
Table ← {𝕊: relation}
Find ← {𝕊 keyValue:
  indices ← (keyValue⊸≡¨relation.key)/relation.index
  result ← {state⇐"unknown",index⇐empty,entry⇐empty}
  {𝕊:
    i ← ⊑indices
    result↩{state⇐"ok",index⇐i,entry⇐Row i}
  }⍟(1=≠indices) @
  result
}

{Table⇐Table,Find⇐Find}
