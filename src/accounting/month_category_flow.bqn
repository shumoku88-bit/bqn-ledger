# Pure calendar-month rollup of presentation-neutral date/category flow evidence.
# Reuses the admitted category axis, exact scale, and contributor Posting indices.

byDate ← •Import "date_category_flow.bqn"
sparse ← •Import "sparse_group.bqn"
empty ← ⟨⟩

Unique ← {𝕊 items:
  result ← empty
  {𝕊 item: {𝕊: result∾↩⟨item⟩}⍟(¬∨´0∾item⊸≡¨result) @}¨items
  result
}
EmptyMonths ← {𝕊: {count⇐0,index⇐empty,label⇐empty} }
EmptyCategories ← {𝕊: {count⇐0,index⇐empty,label⇐empty,kind⇐empty,envelope_account_index⇐empty} }
EmptyGroups ← {𝕊: {count⇐0,index⇐empty,month_index⇐empty,category_index⇐empty,coefficient⇐empty,contributors⇐empty} }

# Input is the same explicit query accepted by date_category_flow.Build.
Build ← {𝕊 factSet‿domainCode‿layerName‿startOrdinal‿endOrdinal:
  daily ← byDate.Build ⟨factSet,domainCode,layerName,startOrdinal,endOrdinal⟩
  diagnostics ← daily.diagnostics
  monthTable ← EmptyMonths @
  groupTable ← EmptyGroups @
  categories ← daily.categories
  amountScale ← daily.scale

  {𝕊:
    dateMonths ← {7↑𝕩}¨daily.dates.date_text
    monthLabels ← Unique dateMonths
    sourceMonths ← {𝕩⊑dateMonths}¨daily.expense_groups.date_index
    grouped ← sparse.Build ⟨
      monthLabels,daily.categories.count,
      sourceMonths,daily.expense_groups.category_index,daily.expense_groups.coefficient,
      daily.expense_groups.contributors
    ⟩
    diagnostics ∾↩ grouped.diagnostics

    {𝕊:
      monthTable↩{count⇐≠monthLabels,index⇐↕≠monthLabels,label⇐monthLabels}
      groupTable↩{
        count⇐grouped.groups.count,index⇐grouped.groups.index,
        month_index⇐grouped.groups.row_index,category_index⇐grouped.groups.column_index,
        coefficient⇐grouped.groups.coefficient,contributors⇐grouped.groups.contributors
      }
    }⍟(0=≠diagnostics) @
  }⍟(daily.state≡"ok") @

  {𝕊: monthTable↩EmptyMonths @ ⋄ categories↩EmptyCategories @ ⋄ groupTable↩EmptyGroups @ ⋄ amountScale↩0}⍟(0<≠diagnostics) @
  state ← (0=≠diagnostics)⊑"error"‿"ok"
  {
    state⇐state,domain⇐domainCode,layer⇐layerName,
    start_ordinal⇐startOrdinal,end_exclusive_ordinal⇐endOrdinal,scale⇐amountScale,
    months⇐monthTable,categories⇐categories,expense_groups⇐groupTable,
    diagnostics⇐diagnostics
  }
}

{Build⇐Build}
