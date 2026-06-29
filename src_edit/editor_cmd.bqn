# src_edit/editor_cmd.bqn
# Unified BQN editor command processor.

lib ← •Import "../src_next/util.bqn"
loader ← •Import "../src_next/loader.bqn"
validate ← •Import "validate.bqn"
render ← •Import "render.bqn"
plan_id ← •Import "plan_id.bqn"
config ← •Import "../src_next/config.bqn"

# Load system defaults
sys ← config.LoadSystemDefaults @

# Main dispatcher
args ← •args
{𝕊: •Out "ERROR: base directory, command, and subcommand are required" ⋄ •Exit 2 }⍟(3 > ≠ args) @

baseDir ← 0 ⊑ args
cmd ← 1 ⊑ args
subcmd ← 2 ⊑ args

# Resolve path helper
ResolvePath ← { baseDir ∾ "/" ∾ 𝕩 }

# Read accounts list
LoadAccountsList ← { 𝕩 ⋄
  path ← ResolvePath (sys.DefaultAccountsFile @)
  lines ← loader.ReadLinesOptional path
  { ⊑ loader.SplitTsvKeepEmpty 𝕩 }¨ lines
}

# ── helper: exit with error message ─────────────────────────────
Fail ← {𝕊 msg:
  •Out "ERROR" ∾ (@+9) ∾ msg
  •Exit 0
}

# Load plans list with full row info
LoadPlansList ← { 𝕩 ⋄
  planPath ← ResolvePath (sys.DefaultPlanFile @)
  journalPath ← ResolvePath (sys.DefaultJournalFile @)
  
  planLines ← loader.ReadLinesOptional planPath
  journalLines ← loader.ReadLinesOptional journalPath
  
  completedIDs ← plan_id.ExtractPlanId¨ journalLines
  nonEmptyCompleted ← (0 < ≠¨ completedIDs) / completedIDs
  
  rawPlanLines ← loader.ReadRaw planPath
  cleanPlanLines ← ((@+13) ≠ rawPlanLines) / rawPlanLines
  allLines ← (@+10) loader.SplitKeepEmpty cleanPlanLines
  
  IsDataLine ← { (0 < ≠ 𝕩) ? ((⊑ 𝕩 ≠ '#') ∧ (⊑ 𝕩 ≠ ⊑"\\")) ; 0 }
  lineNums ← 1 + ↕ ≠ allLines
  
  dataMask ← IsDataLine¨ allLines
  dataLines ← dataMask / allLines
  dataLineNums ← dataMask / lineNums
  
  ParsePlanRow ← {𝕊 index:
    line ← index ⊑ dataLines
    lineNum ← index ⊑ dataLineNums
    flds ← loader.SplitTsvKeepEmpty line
    
    pid ← plan_id.ExtractPlanId line
    missingID ← 0 = ≠ pid
    invalidID ← (¬ missingID) ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ ¬ (0 ⊑ plan_id.ValidatePlanIDFormat pid) } ⟩ @
    closed ← (¬ missingID) ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ ∨´ pid ⊸ ≡¨ nonEmptyCompleted } ⟩ @
    
    {
      lineNum ⇐ lineNum ⋄
      fields ⇐ flds ⋄
      closed ⇐ closed ⋄
      planID ⇐ pid ⋄
      missingID ⇐ missingID ⋄
      invalidID ⇐ invalidID
    }
  }
  
  ParsePlanRow¨ ↕ ≠ dataLines
}

# ── Dispatch journal/budget/plan add ───────────────────────────
RunAdd ← { 𝕩 ⋄
  { 𝕊 ⋄ Fail "missing add arguments" }⍟(11 > ≠ args) @
  
  dateVal ← 3 ⊑ args
  memoVal ← 4 ⊑ args
  fromVal ← 5 ⊑ args
  toVal ← 6 ⊑ args
  amountVal ← 7 ⊑ args
  metaStr ← 8 ⊑ args
  postCheck ← 9 ⊑ args
  planIdArg ← 10 ⊑ args
  
  metaTokens ← ' ' loader.Split metaStr
  { 𝕊 ⋄ Fail "missing --date" }⍟(0 = ≠ dateVal) @
  accounts ← LoadAccountsList @
  isPlan ← cmd ≡ "plan"
  
  hasPlanIdInMeta ← ∨´ { "plan_id=" plan_id.StartsWith 𝕩 }¨ metaTokens
  { 𝕊 ⋄ Fail "--meta plan_id=... is not allowed; use --id or let plan add generate plan_id" }⍟hasPlanIdInMeta @
  
  finalMeta ← metaTokens
  
  # If it is plan, we validate/generate plan_id
  { 𝕩 ⋄
    planPath ← ResolvePath (sys.DefaultPlanFile @)
    journalPath ← ResolvePath (sys.DefaultJournalFile @)
    existingIds ← plan_id.LoadExistingPlanIDs { plan_path ⇐ planPath ⋄ journal_path ⇐ journalPath }
    
    generatedId ← ""
    # If planIdArg was provided
    (0 < ≠ planIdArg) ◶ ⟨
      { 𝕊 ⋄
        # Generate plan_id
        generatedId ↩ plan_id.GeneratePlanID {
          date ⇐ dateVal ⋄
          memo ⇐ memoVal ⋄
          meta ⇐ metaTokens ⋄
          existing_ids ⇐ existingIds
        }
      },
      { 𝕊 ⋄
        # Validate format and check duplicates
        checkFormat ← plan_id.ValidatePlanIDFormat planIdArg
        { 𝕊 ⋄ Fail (1 ⊑ checkFormat) }⍟(¬ 0 ⊑ checkFormat) @
        { 𝕊 ⋄ Fail ("plan_id already exists: " ∾ planIdArg) }⍟(∨´ planIdArg ⊸ ≡¨ existingIds) @
        generatedId ↩ planIdArg
      }
    ⟩ @
    finalMeta ↩ finalMeta ∾ ⟨ "plan_id=" ∾ generatedId ⟩
  }⍟isPlan @
  
  valCheck ← validate.ValidateJournalLikeAdd {
    date ⇐ dateVal ⋄
    memo ⇐ memoVal ⋄
    from ⇐ fromVal ⋄
    to ⇐ toVal ⋄
    amount ⇐ amountVal ⋄
    meta ⇐ finalMeta ⋄
    accounts ⇐ accounts
  }
  
  { 𝕊 ⋄ Fail (1 ⊑ valCheck) }⍟(¬ 0 ⊑ valCheck) @
  
  rendered ← render.RenderJournalRow {
    date ⇐ dateVal ⋄
    memo ⇐ memoVal ⋄
    from ⇐ fromVal ⋄
    to ⇐ toVal ⋄
    amount ⇐ amountVal ⋄
    meta ⇐ finalMeta
  }
  
  •Out "OK" ∾ (@+9) ∾ rendered
}

# ── Dispatch journal reverse ────────────────────────────────────
RunReverse ← { 𝕩 ⋄
  { 𝕊 ⋄ Fail "missing reverse arguments" }⍟(7 > ≠ args) @
  idVal ← 3 ⊑ args
  indexVal ← lib.ToNum (4 ⊑ args)
  reverseDate ← 5 ⊑ args
  yes ← 6 ⊑ args
  
  journalPath ← ResolvePath (sys.DefaultJournalFile @)
  journalLines ← loader.ReadLinesOptional journalPath
  
  targetLine ← ""
  targetIdx ← 0
  
  (indexVal > 0) ◶ ⟨
    { 𝕊 ⋄
      # Search by memo
      matches ← { flds ← loader.SplitTsvKeepEmpty 𝕩 ⋄ (2 ≤ ≠ flds) ◶ ⟨ {0}, { (1 ⊑ flds) ≡ idVal } ⟩ @ }¨ journalLines
      matchIndices ← matches / 1 + ↕ ≠ journalLines
      { 𝕊 ⋄ Fail ("no journal row found with id: " ∾ idVal) }⍟(0 = ≠ matchIndices) @
      { 𝕊 ⋄ Fail ("multiple journal rows match id " ∾ idVal ∾ " (indices: " ∾ (•Fmt matchIndices) ∾ "). Use --index to specify") }⍟(1 < ≠ matchIndices) @
      targetIdx ↩ ⊑ matchIndices
      targetLine ↩ (targetIdx - 1) ⊑ journalLines
    },
    { 𝕊 ⋄
      { 𝕊 ⋄ Fail ("invalid index " ∾ (•Fmt indexVal) ∾ " (journal has " ∾ (•Fmt ≠ journalLines) ∾ " data rows)") }⍟((indexVal < 1) ∨ (indexVal > ≠ journalLines)) @
      targetLine ↩ (indexVal - 1) ⊑ journalLines
      targetIdx ↩ indexVal
    }
  ⟩ @
  
  fields ← loader.SplitTsvKeepEmpty targetLine
  { 𝕊 ⋄ Fail ("journal row " ∾ (•Fmt targetIdx) ∾ " has fewer than 5 fields") }⍟(5 > ≠ fields) @
  
  originalDate ← 0 ⊑ fields
  originalMemo ← 1 ⊑ fields
  originalFrom ← 2 ⊑ fields
  originalTo ← 3 ⊑ fields
  originalAmount ← 4 ⊑ fields
  originalMeta ← 5 ↓ fields
  
  { 𝕊 ⋄ Fail ("cannot reverse row " ∾ (•Fmt targetIdx) ∾ ": from and to accounts are the same") }⍟(originalFrom ≡ originalTo) @
  
  reversedMemo ← "[reverse]" ∾ originalMemo
  
  renderedReverse ← render.RenderJournalRow {
    date ⇐ reverseDate ⋄
    memo ⇐ reversedMemo ⋄
    from ⇐ originalTo ⋄
    to ⇐ originalFrom ⋄
    amount ⇐ originalAmount ⋄
    meta ⇐ originalMeta
  }
  
  •Out "REVERSE" ∾ (@+9) ∾ (•Fmt targetIdx) ∾ (@+9) ∾ originalDate ∾ (@+9) ∾ originalMemo ∾ (@+9) ∾ originalFrom ∾ (@+9) ∾ originalTo ∾ (@+9) ∾ originalAmount ∾ (@+9) ∾ renderedReverse
}

# ── Dispatch issue add ─────────────────────────────────────────
RunIssueAdd ← { 𝕩 ⋄
  { 𝕊 ⋄ Fail "missing issue arguments" }⍟(8 > ≠ args) @
  dateVal ← 3 ⊑ args
  statusVal ← 4 ⊑ args
  titleVal ← 5 ⊑ args
  amountVal ← 6 ⊑ args
  memoVal ← 7 ⊑ args
  
  valDate ← validate.ValidateDate dateVal
  { 𝕊 ⋄ Fail (1 ⊑ valDate) }⍟(¬ 0 ⊑ valDate) @
  
  validStatus ← ∨´ statusVal ⊸ ≡¨ "open"‿"resolved"‿"dropped"
  { 𝕊 ⋄ Fail ("invalid status: " ∾ statusVal ∾ " (expected 'open', 'resolved', or 'dropped')") }⍟(¬ validStatus) @
  
  { 𝕊 ⋄ Fail "title is required" }⍟(0 = ≠ titleVal) @
  valTitle ← validate.ValidateNoTabNewline "title"‿titleVal
  { 𝕊 ⋄ Fail (1 ⊑ valTitle) }⍟(¬ 0 ⊑ valTitle) @
  
  valAmount ← validate.ValidateAmount amountVal
  { 𝕊 ⋄ Fail (1 ⊑ valAmount) }⍟(¬ 0 ⊑ valAmount) @
  
  valMemo ← validate.ValidateNoTabNewline "memo"‿memoVal
  { 𝕊 ⋄ Fail (1 ⊑ valMemo) }⍟(¬ 0 ⊑ valMemo) @
  
  rendered ← render.RenderIssueRow {
    date ⇐ dateVal ⋄
    status ⇐ statusVal ⋄
    title ⇐ titleVal ⋄
    amount ⇐ amountVal ⋄
    memo ⇐ memoVal
  }
  
  •Out "OK" ∾ (@+9) ∾ rendered
}

# ── Dispatch plan list ─────────────────────────────────────────
RunList ← { 𝕩 ⋄
  { 𝕊 ⋄ Fail "missing list arguments" }⍟(5 > ≠ args) @
  showAll ← "1" ≡ 3 ⊑ args
  format ← 4 ⊑ args
  
  plans ← LoadPlansList @
  selectedPlans ← showAll ◶ ⟨ { 𝕊 ⋄ (¬ {𝕩.closed}¨ plans) / plans }, { 𝕊 ⋄ plans } ⟩ @
  
  tab ← @+9
  
  PrintRowText ← {𝕊 index:
    r ← index ⊑ selectedPlans
    num ← index + 1
    status ← r.closed ◶ ⟨ { 𝕊 ⋄ r.missingID ◶ ⟨ { 𝕊 ⋄ r.invalidID ◶ ⟨ {""}, {" [INVALID-ID]"} ⟩ @ }, {" [MISSING-ID]"} ⟩ @ }, {" [CLOSED]"} ⟩ @
    f ← r.fields
    (•Fmt num) ∾ ": " ∾ (0⊑f) ∾ tab ∾ (1⊑f) ∾ tab ∾ (2⊑f) ∾ " -> " ∾ (3⊑f) ∾ tab ∾ (4⊑f) ∾ status
  }
  
  PrintRowTsv ← {𝕊 index:
    r ← index ⊑ selectedPlans
    num ← index + 1
    statusTsv ← r.closed ◶ ⟨ { 𝕊 ⋄ r.missingID ◶ ⟨ { 𝕊 ⋄ r.invalidID ◶ ⟨ {""}, {"INVALID-ID"} ⟩ @ }, {"MISSING-ID"} ⟩ @ }, {"CLOSED"} ⟩ @
    statusDisplay ← r.closed ◶ ⟨ { 𝕊 ⋄ r.missingID ◶ ⟨ { 𝕊 ⋄ r.invalidID ◶ ⟨ {""}, {" [INVALID-ID]"} ⟩ @ }, {" [MISSING-ID]"} ⟩ @ }, {" [CLOSED]"} ⟩ @
    f ← r.fields
    display ← (•Fmt num) ∾ ": " ∾ (0⊑f) ∾ "  " ∾ (1⊑f) ∾ "  " ∾ (2⊑f) ∾ " -> " ∾ (3⊑f) ∾ "  " ∾ (4⊑f) ∾ statusDisplay
    # Format: num planID date memo from to amount statusTsv display
    (•Fmt num) ∾ tab ∾ r.planID ∾ tab ∾ (0⊑f) ∾ tab ∾ (1⊑f) ∾ tab ∾ (2⊑f) ∾ tab ∾ (3⊑f) ∾ tab ∾ (4⊑f) ∾ tab ∾ statusTsv ∾ tab ∾ display
  }
  
  isTsv ← format ≡ "tsv"
  isTsv ◶ ⟨
    { 𝕊 ⋄
      •Out "Plan rows:"
      lines ← PrintRowText¨ ↕ ≠ selectedPlans
      { •Out 𝕩 }¨ lines
    },
    { 𝕊 ⋄
      lines ← PrintRowTsv¨ ↕ ≠ selectedPlans
      { •Out 𝕩 }¨ lines
    }
  ⟩ @
}

# ── Dispatch plan finish ───────────────────────────────────────
RunFinish ← { 𝕩 ⋄
  { 𝕊 ⋄ Fail "missing finish arguments" }⍟(8 > ≠ args) @
  indexVal ← lib.ToNum (3 ⊑ args)
  idVal ← 4 ⊑ args
  actualDate ← 5 ⊑ args
  showAll ← "1" ≡ 6 ⊑ args
  apply ← "1" ≡ 7 ⊑ args
  
  plans ← LoadPlansList @
  selectedPlans ← showAll ◶ ⟨ { 𝕊 ⋄ (¬ {𝕩.closed}¨ plans) / plans }, { 𝕊 ⋄ plans } ⟩ @
  
  selIdx ← 0
  hasSelected ← 0
  
  (indexVal > 0) ◶ ⟨
    { 𝕊 ⋄
      matches ← { 𝕩.planID ≡ idVal }¨ selectedPlans
      (∨´ matches) ◶ ⟨
        { 𝕊 ⋄ Fail (showAll ◶ ⟨ {"plan_id not found or already closed: " ∾ idVal}, {"plan_id not found: " ∾ idVal} ⟩ @) },
        { 𝕊 ⋄
          selIdx ↩ ⊑ (matches / ↕ ≠ selectedPlans)
          hasSelected ↩ 1
        }
      ⟩ @
    },
    { 𝕊 ⋄
      { 𝕊 ⋄ Fail ("invalid plan index: " ∾ (•Fmt indexVal) ∾ " (available: 1-" ∾ (•Fmt ≠ selectedPlans) ∾ ")") }⍟((indexVal < 1) ∨ (indexVal > ≠ selectedPlans)) @
      selIdx ↩ indexVal - 1
      hasSelected ↩ 1
    }
  ⟩ @
  
  selected ← selIdx ⊑ selectedPlans
  { 𝕊 ⋄ Fail "plan is already closed" }⍟selected.closed @
  { 𝕊 ⋄ Fail "cannot finish plan without plan_id" }⍟selected.missingID @
  { 𝕊 ⋄ Fail ("cannot finish plan with invalid plan_id: " ∾ selected.planID) }⍟selected.invalidID @
  
  planOnlyKeys ← ⟨ "recur", "months", "anchor", "offset" ⟩
  flds ← selected.fields
  meta ← 5 ↓ flds
  
  CleanMeta ← {𝕊 token:
    hasEq ← ∨´ '=' = token
    eqPos ← hasEq ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ ⊑ / '=' = token } ⟩ @
    key ← hasEq ◶ ⟨ { 𝕊 ⋄ "" }, { 𝕊 ⋄ eqPos ↑ token } ⟩ @
    isPlanOnly ← ∨´ key ⊸ ≡¨ planOnlyKeys
    (¬ isPlanOnly) ◶ ⟨ {⟨⟩}, {⟨token⟩} ⟩ @
  }
  cleanMetaList ← ∾ CleanMeta¨ meta
  
  candidateFields ← ⟨ actualDate, 1⊑flds, 2⊑flds, 3⊑flds, 4⊑flds ⟩ ∾ cleanMetaList
  
  renderedCandidate ← render.RenderJournalRow {
    date ⇐ 0⊑candidateFields ⋄
    memo ⇐ 1⊑candidateFields ⋄
    from ⇐ 2⊑candidateFields ⋄
    to ⇐ 3⊑candidateFields ⋄
    amount ⇐ 4⊑candidateFields ⋄
    meta ⇐ 5↓candidateFields
  }
  
  •Out "CANDIDATE" ∾ (@+9) ∾ renderedCandidate
}

# ── Dispatch plan edit ─────────────────────────────────────────
RunEdit ← { 𝕩 ⋄
  { 𝕊 ⋄ Fail "missing edit arguments" }⍟(11 > ≠ args) @
  indexVal ← lib.ToNum (3 ⊑ args)
  idVal ← 4 ⊑ args
  dateVal ← 5 ⊑ args
  amountVal ← 6 ⊑ args
  showAll ← "1" ≡ 7 ⊑ args
  dryRun ← "1" ≡ 8 ⊑ args
  yes ← "1" ≡ 9 ⊑ args
  postCheck ← 10 ⊑ args
  
  plans ← LoadPlansList @
  selectedPlans ← showAll ◶ ⟨ { 𝕊 ⋄ (¬ {𝕩.closed}¨ plans) / plans }, { 𝕊 ⋄ plans } ⟩ @
  
  selIdx ← 0
  (indexVal > 0) ◶ ⟨
    { 𝕊 ⋄
      matches ← { 𝕩.planID ≡ idVal }¨ selectedPlans
      (∨´ matches) ◶ ⟨
        { 𝕊 ⋄ Fail (showAll ◶ ⟨ {"plan_id not found or already closed: " ∾ idVal}, {"plan_id not found: " ∾ idVal} ⟩ @) },
        { 𝕊 ⋄ selIdx ↩ ⊑ (matches / ↕ ≠ selectedPlans) }
      ⟩ @
    },
    { 𝕊 ⋄
      { 𝕊 ⋄ Fail ("invalid plan index: " ∾ (•Fmt indexVal) ∾ " (available: 1-" ∾ (•Fmt ≠ selectedPlans) ∾ ")") }⍟((indexVal < 1) ∨ (indexVal > ≠ selectedPlans)) @
      selIdx ↩ indexVal - 1
    }
  ⟩ @
  
  selected ← selIdx ⊑ selectedPlans
  { 𝕊 ⋄ Fail "cannot edit closed plan" }⍟selected.closed @
  { 𝕊 ⋄ Fail "cannot edit plan without plan_id" }⍟selected.missingID @
  { 𝕊 ⋄ Fail ("cannot edit plan with invalid plan_id: " ∾ selected.planID) }⍟selected.invalidID @
  
  oldFields ← selected.fields
  newFields ← oldFields
  
  { newFields ↩ ⟨dateVal⟩ ∾ 1↓newFields }⍟(0 < ≠ dateVal) @
  { newFields ↩ (4↑newFields) ∾ ⟨amountVal⟩ ∾ 5↓newFields }⍟(0 < ≠ amountVal) @
  
  tab ← @+9
  oldLine ← tab plan_id.Join oldFields
  newLine ← tab plan_id.Join newFields
  
  { 𝕊 ⋄ Fail "edit would not change the selected plan row" }⍟(oldLine ≡ newLine) @
  
  •Out "REPLACE" ∾ tab ∾ (•Fmt selected.lineNum) ∾ tab ∾ oldLine ∾ tab ∾ newLine ∾ tab ∾ selected.planID
}

# ── Main router ─────────────────────────────────────────────────
(cmd ≡ "journal") ◶ ⟨
  { 𝕊 ⋄
    (cmd ≡ "budget") ◶ ⟨
      { 𝕊 ⋄
        (cmd ≡ "issue") ◶ ⟨
          { 𝕊 ⋄
            (cmd ≡ "plan") ◶ ⟨
              { 𝕊 ⋄ Fail ("unknown command: " ∾ cmd) },
              { 𝕊 ⋄
                (subcmd ≡ "add") ◶ ⟨
                  { 𝕊 ⋄
                    (subcmd ≡ "list") ◶ ⟨
                      { 𝕊 ⋄
                        (subcmd ≡ "finish") ◶ ⟨
                          { 𝕊 ⋄ RunEdit @ },
                          { 𝕊 ⋄ RunFinish @ }
                        ⟩ @
                      },
                      { 𝕊 ⋄ RunList @ }
                    ⟩ @
                  },
                  { 𝕊 ⋄ RunAdd @ }
                ⟩ @
              }
            ⟩ @
          },
          { 𝕊 ⋄ RunIssueAdd @ }
        ⟩ @
      },
      { 𝕊 ⋄ RunAdd @ }
    ⟩ @
  },
  { 𝕊 ⋄
    (subcmd ≡ "add") ◶ ⟨ { 𝕊 ⋄ RunReverse @ }, { 𝕊 ⋄ RunAdd @ } ⟩ @
  }
⟩ @
