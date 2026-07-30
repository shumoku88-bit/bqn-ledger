# Pure static retained destination catalog. Listing reads no household source.

empty ← ⟨⟩

Entry ← {𝕊 keyValue‿labelValue‿categoryValue‿ownerValue‿shapeValue‿humanValue‿compactValue‿jsonValue:
  {
    key⇐keyValue,label⇐labelValue,category⇐categoryValue,owner⇐ownerValue,shape⇐shapeValue,
    human⇐humanValue,compact⇐compactValue,json⇐jsonValue
  }
}
entries ← ⟨
  Entry ⟨"envelopes","Envelope & Backing","household","src/sections/envelope_backing.bqn","statement",1,1,1⟩,
  Entry ⟨"balances","Account Balances","accounting","src/sections/account_balances.bqn","matrix",1,1,1⟩,
  Entry ⟨"balance-sheet","Balance Sheet","accounting","src/sections/balance_sheet.bqn","statement",1,0,0⟩,
  Entry ⟨"profit-and-loss","Profit and Loss","accounting","src/sections/profit_and_loss.bqn","statement",1,0,0⟩,
  Entry ⟨"recent","Recent Journal","operations","src/sections/recent_journal.bqn","list",1,1,0⟩,
  Entry ⟨"planned","Planned Payments","operations","src/sections/planned_payments.bqn","list_card",1,1,1⟩,
  Entry ⟨"cycle-accounts","Current-cycle Accounts","accounting","src/sections/cycle_accounts.bqn","matrix",1,0,0⟩,
  Entry ⟨"cycle-comparison","Cycle Comparison","accounting","src/sections/cycle_comparison.bqn","matrix",1,0,0⟩,
  Entry ⟨"monthly-accounts","Monthly Accounts","accounting","src/sections/monthly_accounts.bqn","matrix",1,0,0⟩,
  Entry ⟨"daily-flow","Daily Flow","accounting","src/sections/daily_flow.bqn","matrix",1,0,0⟩,
  Entry ⟨"daily-target","Daily Target","household","src/sections/daily_target.bqn","card_projection",1,1,0⟩,
  Entry ⟨"issues","Issues","operations","src/sections/issues.bqn","list",1,0,0⟩
⟩

Table ← {𝕊:
  {
    count⇐≠entries,index⇐↕≠entries,key⇐{𝕩.key}¨entries,label⇐{𝕩.label}¨entries,
    category⇐{𝕩.category}¨entries,owner⇐{𝕩.owner}¨entries,shape⇐{𝕩.shape}¨entries,
    human⇐{𝕩.human}¨entries,
    compact⇐{𝕩.compact}¨entries,json⇐{𝕩.json}¨entries
  }
}
Find ← {𝕊 keyValue:
  matches ← keyValue⊸≡¨{𝕩.key}¨entries
  result ← {state⇐"unknown",entry⇐empty}
  {𝕊:result↩{state⇐"ok",entry⇐(⊑matches/↕≠entries)⊑entries}}⍟(1=+´matches) @
  result
}

{Table⇐Table,Find⇐Find}
