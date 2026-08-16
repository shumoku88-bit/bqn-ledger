# Pure source-independent Household UI surface relation.
#
# The surface is not a Widget tree and owns no writer/report implementation.
# It only states which logical operation coordinates exist for each Household
# subject. Physical keys, terminal geometry, and command dispatch stay outside.

empty ← ⟨⟩
tab ← @+9 ⋄ lf ← @+10

domainKeys ← ⟨"actual","plan","envelope","account","issue","household"⟩
domainLabels ← ⟨"Actual","Plan","Envelope","Account","Issue","Household"⟩
operationKeys ← ⟨"observe","add","change","resolve"⟩
operationLabels ← ⟨"Observe","Add","Change","Resolve"⟩

# Row-major Domain × Operation coordinates. Disabled coordinates are retained
# explicitly so every frontend sees the same rectangular surface.
domainIndex ← ⟨0,0,0,0, 1,1,1,1, 2,2,2,2, 3,3,3,3, 4,4,4,4, 5,5,5,5⟩
operationIndex ← ⟨0,1,2,3, 0,1,2,3, 0,1,2,3, 0,1,2,3, 0,1,2,3, 0,1,2,3⟩
enabled ← ⟨1,1,0,1, 1,1,1,1, 1,1,0,0, 1,1,0,0, 1,1,0,1, 1,0,0,0⟩
cellLabels ← ⟨
  "Journal","Record","","Reverse",
  "Plans","Add","Edit","Finish",
  "Backing","Move","","",
  "Accounts","Add","","",
  "Issues","Add","","Close",
  "Reports","","",""
⟩

count ← ≠enabled
index ← ↕count
relation ← {
  count⇐count,index⇐index,
  domain_index⇐domainIndex,
  domain_key⇐{𝕩⊑domainKeys}¨domainIndex,
  domain_label⇐{𝕩⊑domainLabels}¨domainIndex,
  operation_index⇐operationIndex,
  operation_key⇐{𝕩⊑operationKeys}¨operationIndex,
  operation_label⇐{𝕩⊑operationLabels}¨operationIndex,
  enabled⇐enabled,cell_label⇐cellLabels
}

Table ← {𝕊: relation}
Domains ← {𝕊:{count⇐≠domainKeys,index⇐↕≠domainKeys,key⇐domainKeys,label⇐domainLabels}}
Operations ← {𝕊:{count⇐≠operationKeys,index⇐↕≠operationKeys,key⇐operationKeys,label⇐operationLabels}}
Find ← {𝕊 domainValue‿operationValue:
  matches ← (domainValue⊸≡¨relation.domain_key) ∧ operationValue⊸≡¨relation.operation_key
  indices ← matches/relation.index
  result ← {state⇐"unknown",index⇐empty,enabled⇐0,cell_label⇐""}
  {𝕊:
    i ← ⊑indices
    result↩{state⇐"ok",index⇐i,enabled⇐i⊑relation.enabled,cell_label⇐i⊑relation.cell_label}
  }⍟(1=≠indices) @
  result
}

FormatTsv ← {𝕊:
  header ← ∾⟨"domain_index",tab,"domain_key",tab,"domain_label",tab,"operation_index",tab,"operation_key",tab,"operation_label",tab,"enabled",tab,"cell_label",lf⟩
  rows ← {𝕊 i:
    ∾⟨
      •Fmt i⊑relation.domain_index,tab,i⊑relation.domain_key,tab,i⊑relation.domain_label,tab,
      •Fmt i⊑relation.operation_index,tab,i⊑relation.operation_key,tab,i⊑relation.operation_label,tab,
      •Fmt i⊑relation.enabled,tab,i⊑relation.cell_label,lf
    ⟩
  }¨relation.index
  ∾⟨header,∾rows⟩
}

{Table⇐Table,Domains⇐Domains,Operations⇐Operations,Find⇐Find,FormatTsv⇐FormatTsv}
