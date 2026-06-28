# issues.bqn — format issues log
#

fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
L ← labels.Text

# Build text report for open issues
# Args: ctx (context namespace)
FormatHuman ← {𝕊 ctx:
  issues ← ctx.issues
  
  # Filter only 'open' issues (guard with namespace check to avoid prototype resolution crash)
  IsOpen ← { (6 = •Type 𝕩) ? ("open" ≡ 𝕩.status) ; 0 }
  open_issues ← (IsOpen ¨ issues) / issues

  hdr ← fmt.Section (L "report.issues_title")
  
  # Format each open issue (guard with namespace check)
  FormatItem ← {
    issue ← 𝕩
    (6 = •Type issue) ? ("• " ∾ issue.date ∾ " " ∾ issue.title ∾ ((0 < ≠ issue.amount) ◶ ⟨ { "" }, { ("0" ≡ issue.amount) ◶ ⟨ { " (" ∾ issue.amount ∾ ")" }, { "" } ⟩ @ } ⟩ @) ∾ " — " ∾ issue.memo) ; ""
  }
  
  (0 = ≠ open_issues) ◶ ⟨ {
    items ← FormatItem ¨ open_issues
    hdr ∾ (@+10) ∾ ∾ { 𝕩 ∾ (@+10) } ¨ items
  }, {
    hdr ∾ (@+10) ∾ "(No open issues)" ∾ (@+10)
  } ⟩ @
}

{ FormatHuman ⇐ FormatHuman }
