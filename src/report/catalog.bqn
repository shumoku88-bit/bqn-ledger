# Pure static retained destination catalog. Listing reads no household source.

empty ← ⟨⟩

Entry ← {𝕊 keyValue‿labelValue‿shapeValue‿humanValue‿compactValue‿jsonValue:
  {
    key⇐keyValue,label⇐labelValue,shape⇐shapeValue,
    human⇐humanValue,compact⇐compactValue,json⇐jsonValue
  }
}
entries ← ⟨
  Entry ⟨"envelopes","Envelope & Backing","statement",1,1,1⟩,
  Entry ⟨"balances","Account Balances","matrix",1,1,1⟩,
  Entry ⟨"recent","Recent Journal","list",1,1,0⟩,
  Entry ⟨"planned","Planned Payments","list_card",1,1,1⟩,
  Entry ⟨"cycle-accounts","Current-cycle Accounts","matrix",1,0,0⟩,
  Entry ⟨"cycle-comparison","Cycle Comparison","matrix",1,0,0⟩,
  Entry ⟨"monthly-accounts","Monthly Accounts","matrix",1,0,0⟩,
  Entry ⟨"daily-target","Daily Target","card_projection",1,1,0⟩,
  Entry ⟨"issues","Issues","list",1,0,0⟩
⟩

Table ← {𝕊:
  {
    count⇐≠entries,index⇐↕≠entries,key⇐{𝕩.key}¨entries,label⇐{𝕩.label}¨entries,
    shape⇐{𝕩.shape}¨entries,human⇐{𝕩.human}¨entries,
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
