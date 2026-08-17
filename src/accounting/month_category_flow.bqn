# Pure calendar-month rollup of presentation-neutral date/category flow evidence.
# Reuses stable Household category identity, historical Expense routing, exact
# scale, and contributor Posting indices.

byDate ← •Import "date_category_flow.bqn"
sparse ← •Import "sparse_group.bqn"
empty ← ⟨⟩

EmptyMonths ← {𝕊: {count⇐0,index⇐empty,label⇐empty} }
EmptyCategories ← {𝕊: {count⇐0,index⇐empty,label⇐empty,kind⇐empty} }
FailureResult ← {𝕊 domainCode‿layerName‿startOrdinal‿endOrdinal‿diagnosticsValue:
  {
    state⇐"error",domain⇐domainCode,layer⇐layerName,
    start_ordinal⇐startOrdinal,end_exclusive_ordinal⇐endOrdinal,scale⇐0,
    months⇐EmptyMonths @,categories⇐EmptyCategories @,
    expense_groups⇐(sparse.Build ⟨empty,0,empty,empty,empty,empty⟩).groups,
    diagnostics⇐diagnosticsValue
  }
}

Kernel ← {𝕊 daily‿domainCode‿layerName‿startOrdinal‿endOrdinal:
  dateMonths ← {7↑𝕩}¨daily.dates.date_text
  monthLabels ← ⍷dateMonths
  sourceMonths ← {𝕩⊑dateMonths}¨daily.expense_groups.row_index
  grouped ← sparse.Build ⟨
    monthLabels,daily.categories.count,
    sourceMonths,daily.expense_groups.column_index,daily.expense_groups.coefficient,
    daily.expense_groups.contributors
  ⟩
  diagnostics ← grouped.diagnostics
  result ← FailureResult ⟨domainCode,layerName,startOrdinal,endOrdinal,diagnostics⟩
  {𝕊: result↩{
    state⇐"ok",domain⇐domainCode,layer⇐layerName,
    start_ordinal⇐startOrdinal,end_exclusive_ordinal⇐endOrdinal,scale⇐daily.scale,
    months⇐{count⇐≠monthLabels,index⇐↕≠monthLabels,label⇐monthLabels},
    categories⇐daily.categories,expense_groups⇐grouped.groups,diagnostics⇐empty
  }}⍟(0=≠diagnostics) @
  result
}

# Input is the same explicit query accepted by date_category_flow.Build.
Build ← {𝕊 factSet‿history‿domainCode‿layerName‿startOrdinal‿endOrdinal:
  daily ← byDate.Build ⟨factSet,history,domainCode,layerName,startOrdinal,endOrdinal⟩
  result ← FailureResult ⟨domainCode,layerName,startOrdinal,endOrdinal,daily.diagnostics⟩
  {𝕊: result↩Kernel ⟨daily,domainCode,layerName,startOrdinal,endOrdinal⟩}⍟(daily.state≡"ok") @
  result
}

{Build⇐Build}