# Pure source-independent Household UI surface relation.
#
# The surface is not a Widget tree and owns no writer/report implementation.
# It states which logical operation coordinates and leaf actions exist for each
# Household subject. Physical keys, terminal geometry, and command dispatch stay
# outside. Retained report leaves are projected from the existing report catalog.

reports ← •Import "../report/catalog.bqn"
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

# Non-report action keys are logical UI vocabulary. Their concrete command
# invocation remains a frontend/application-shell concern.
commandKeys ← ⟨
  "journal-list","expense","income","move","multi","reverse",
  "plan-list","plan-upcoming","plan-overdue","plan-related","plan-add","plan-edit","plan-finish",
  "budget-move","account-list","account-add","issue-list","issue-add","issue-close"
⟩
commandLabels ← ⟨
  "Journal history","Expense","Income","Transfer / move","Multi-posting transaction","Reverse with a compensating transaction",
  "Open Plans","Upcoming Plans","Overdue Plans","Related Plan evidence","Add Plan","Edit Plan date / amount","Finish / actualize / replenish Plan",
  "Add / move Budget","Account inventory","Add Account","Open Issues","Add Issue","Close Issue"
⟩
commandDomains ← ⟨
  "actual","actual","actual","actual","actual","actual",
  "plan","plan","plan","plan","plan","plan","plan",
  "envelope","account","account","issue","issue","issue"
⟩
commandOperations ← ⟨
  "observe","add","add","add","add","resolve",
  "observe","observe","observe","observe","add","change","resolve",
  "add","observe","add","observe","add","resolve"
⟩
commandScopes ← ⟨
  "all","selected-date","selected-date","selected-date","selected-date","selected-date",
  "current","upcoming","overdue","selected","selected-date","selected","selected",
  "selected-date","current","none","current","selected-date","selected"
⟩

Actions ← {𝕊:
  reportTable ← reports.Table @
  actionDomain ← commandDomains∾reportTable.surface_domain
  actionOperation ← commandOperations∾reportTable.count⥊⟨"observe"⟩
  actionScope ← commandScopes∾reportTable.surface_scope
  actionKey ← commandKeys∾reportTable.key
  actionLabel ← commandLabels∾reportTable.label
  actionKind ← (≠commandKeys)⥊⟨"command"⟩ ∾ reportTable.count⥊⟨"report"⟩
  {
    count⇐≠actionKey,index⇐↕≠actionKey,
    domain_key⇐actionDomain,operation_key⇐actionOperation,scope⇐actionScope,
    action_key⇐actionKey,action_label⇐actionLabel,action_kind⇐actionKind
  }
}
ActionsFor ← {𝕊 domainValue‿operationValue:
  source ← Actions @
  selected ← ((domainValue⊸≡¨source.domain_key) ∧ operationValue⊸≡¨source.operation_key)/source.index
  {
    count⇐≠selected,index⇐↕≠selected,
    domain_key⇐selected⊏source.domain_key,
    operation_key⇐selected⊏source.operation_key,
    scope⇐selected⊏source.scope,
    action_key⇐selected⊏source.action_key,
    action_label⇐selected⊏source.action_label,
    action_kind⇐selected⊏source.action_kind
  }
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
FormatActionsTsv ← {𝕊 domainValue‿operationValue:
  table ← ActionsFor ⟨domainValue,operationValue⟩
  header ← ∾⟨"action_index",tab,"domain_key",tab,"operation_key",tab,"scope",tab,"action_key",tab,"action_label",tab,"action_kind",lf⟩
  rows ← {𝕊 i:
    ∾⟨
      •Fmt i,tab,i⊑table.domain_key,tab,i⊑table.operation_key,tab,i⊑table.scope,tab,
      i⊑table.action_key,tab,i⊑table.action_label,tab,i⊑table.action_kind,lf
    ⟩
  }¨table.index
  ∾⟨header,∾rows⟩
}

{
  Table⇐Table,Domains⇐Domains,Operations⇐Operations,Find⇐Find,
  Actions⇐Actions,ActionsFor⇐ActionsFor,
  FormatTsv⇐FormatTsv,FormatActionsTsv⇐FormatActionsTsv
}
