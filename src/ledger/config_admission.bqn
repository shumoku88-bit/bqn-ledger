# Pure strict ledger/report configuration admission.
# Parses already-read config.tsv lines; owns no path, repository default, I/O, or fallback.

empty ← ⟨⟩
tab ← @+9
knownKeys ← ⟨
  "DEFAULT_CURRENCY","ACTUAL_JOURNAL_FILE",
  "POLICY_BUDGET_STYLE","POLICY_RISK_STYLE","POLICY_INCOME_CADENCE",
  "HOUSEHOLD_GROUP_LIFE","HOUSEHOLD_GROUP_RESERVE","HOUSEHOLD_GROUP_ORDER",
  "BUDGET_PREFIX","BUDGET_ID_OPENING","BUDGET_ID_UNASSIGNED","BUDGET_ID_SPENT",
  "EXECUTION_PLANNED_PAYMENTS_ENVELOPE"
⟩
listKeys ← ⟨"HOUSEHOLD_GROUP_LIFE","HOUSEHOLD_GROUP_RESERVE","HOUSEHOLD_GROUP_ORDER"⟩

SplitKeepEmpty ← {𝕊 sep‿text:
  groups ← (+`sep=text)⊔text
  {(sep≠𝕩)/𝕩}¨groups
}
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Unique ← {𝕊 items:
  result ← empty
  {𝕊 item: {𝕊: result∾↩⟨item⟩}⍟(¬Contains ⟨item,result⟩) @}¨items
  result
}
Ignored ← {𝕊 line: (0=≠line) ∨ ((0<≠line) ∧ ((⊑line)∊"#\\")) }
Diagnostic ← {𝕊 codeText‿row‿messageText:
  {severity⇐"error",stage⇐"ledger_config_admission",code⇐codeText,source_row⇐row,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
ValueOr ← {𝕊 key‿rows‿fallback:
  matches ← ({𝕩.key≡key}¨rows)/rows
  result ← fallback
  {𝕊: result↩(⊑matches).value}⍟(1=≠matches) @
  result
}
InEnum ← {𝕊 value‿allowed: (0=≠value) ∨ Contains ⟨value,allowed⟩}

Admit ← {𝕊 lines‿registry:
  diagnostics ← empty
  rows ← empty
  {𝕊 i:
    line ← i⊑lines
    {𝕊:
      row ← i+1
      tabs ← +´tab=line
      equals ← +´'='=line
      useTab ← tabs=1
      shapeOk ← useTab ∨ ((tabs=0) ∧ equals=1)
      diagnostics ∾↩ AddIf ⟨¬shapeOk,Diagnostic ⟨"config_row_shape_invalid",row,"config row requires exactly one tab or one equals separator"⟩⟩
      {𝕊:
        separator ← useTab⊑⟨'=',tab⟩
        fields ← SplitKeepEmpty ⟨separator,line⟩
        key ← 0⊑fields ⋄ value ← 1⊑fields
        rowDiagnostics ← empty
        rowDiagnostics ∾↩ AddIf ⟨0=≠key,Diagnostic ⟨"config_key_empty",row,"config key must be nonempty"⟩⟩
        rowDiagnostics ∾↩ AddIf ⟨0=≠value,Diagnostic ⟨"config_value_empty",row,"strict config values must be nonempty"⟩⟩
        rowDiagnostics ∾↩ AddIf ⟨¬Contains ⟨key,knownKeys⟩,Diagnostic ⟨"config_key_unsupported",row,"config key is not admitted"⟩⟩
        diagnostics ∾↩ rowDiagnostics
        {𝕊: rows∾↩⟨{key⇐key,value⇐value,source_row⇐row}⟩}⍟(0=≠rowDiagnostics) @
      }⍟shapeOk @
    }⍟(¬Ignored line) @
  }¨↕≠lines

  keys ← {𝕩.key}¨rows
  diagnostics ∾↩ AddIf ⟨(≠keys)≠≠Unique keys,Diagnostic ⟨"config_key_duplicate",0,"config keys must be unique"⟩⟩
  defaultCurrency ← ValueOr ⟨"DEFAULT_CURRENCY",rows,""⟩
  diagnostics ∾↩ AddIf ⟨0=≠defaultCurrency,Diagnostic ⟨"default_currency_missing",0,"DEFAULT_CURRENCY must be explicit"⟩⟩
  diagnostics ∾↩ AddIf ⟨(0<≠defaultCurrency) ∧ (registry.Policy defaultCurrency).state≢"ok",Diagnostic ⟨"default_currency_unsupported",0,"DEFAULT_CURRENCY must be registry-supported"⟩⟩

  budgetStyle ← ValueOr ⟨"POLICY_BUDGET_STYLE",rows,""⟩
  riskStyle ← ValueOr ⟨"POLICY_RISK_STYLE",rows,""⟩
  cadence ← ValueOr ⟨"POLICY_INCOME_CADENCE",rows,""⟩
  groupLife ← ValueOr ⟨"HOUSEHOLD_GROUP_LIFE",rows,""⟩
  groupReserve ← ValueOr ⟨"HOUSEHOLD_GROUP_RESERVE",rows,""⟩
  groupOrder ← ValueOr ⟨"HOUSEHOLD_GROUP_ORDER",rows,""⟩
  diagnostics ∾↩ AddIf ⟨¬InEnum ⟨budgetStyle,⟨"envelope","none"⟩⟩,Diagnostic ⟨"budget_style_invalid",0,"POLICY_BUDGET_STYLE is unsupported"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬InEnum ⟨riskStyle,⟨"conservative","simple"⟩⟩,Diagnostic ⟨"risk_style_invalid",0,"POLICY_RISK_STYLE is unsupported"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬InEnum ⟨cadence,⟨"bimonthly","monthly","weekly","irregular"⟩⟩,Diagnostic ⟨"income_cadence_invalid",0,"POLICY_INCOME_CADENCE is unsupported"⟩⟩

  {𝕊 key:
    value ← ValueOr ⟨key,rows,""⟩
    {𝕊:
      items ← SplitKeepEmpty ⟨',',value⟩
      diagnostics ∾↩ AddIf ⟨∨´0∾{0=≠𝕩}¨items,Diagnostic ⟨"config_list_item_empty",0,key∾" must not contain empty list items"⟩⟩
      diagnostics ∾↩ AddIf ⟨(≠items)≠≠Unique items,Diagnostic ⟨"config_list_item_duplicate",0,key∾" must not contain duplicate items"⟩⟩
    }⍟(0<≠value) @
  }¨listKeys

  actualFile ← ValueOr ⟨"ACTUAL_JOURNAL_FILE",rows,""⟩
  {𝕊:
    hasSeparator ← ∨´('/'=actualFile) ∨ ((@+92)=actualFile)
    validSuffix ← (8≤≠actualFile) ∧ ".journal"≡¯8↑actualFile
    diagnostics ∾↩ AddIf ⟨hasSeparator ∨ ¬validSuffix,Diagnostic ⟨"actual_journal_file_invalid",0,"ACTUAL_JOURNAL_FILE must be a safe .journal basename"⟩⟩
  }⍟(0<≠actualFile) @

  hasError ← 0<≠diagnostics
  admittedRows ← hasError⊑rows‿empty
  {
    state⇐hasError⊑"ok"‿"error",
    table⇐{
      count⇐≠admittedRows,index⇐↕≠admittedRows,
      key⇐{𝕩.key}¨admittedRows,value⇐{𝕩.value}¨admittedRows,source_row⇐{𝕩.source_row}¨admittedRows
    },
    source⇐{
      default_currency⇐hasError⊑defaultCurrency‿"",
      actual_journal_file⇐hasError⊑actualFile‿""
    },
    report_policy⇐{
      budget_style⇐hasError⊑budgetStyle‿"",risk_style⇐hasError⊑riskStyle‿"",
      income_cadence⇐hasError⊑cadence‿"",
      household_group_life⇐hasError⊑groupLife‿"",
      household_group_reserve⇐hasError⊑groupReserve‿"",
      household_group_order⇐hasError⊑groupOrder‿""
    },
    diagnostics⇐diagnostics
  }
}

{Admit⇐Admit}
