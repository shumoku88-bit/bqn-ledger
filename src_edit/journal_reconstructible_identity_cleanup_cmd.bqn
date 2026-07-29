# src_edit/journal_reconstructible_identity_cleanup_cmd.bqn
# Command adapter for reconstructible Journal identity cleanup.
#
# Modes:
#   inspect [INPUT]
#   candidate INPUT OUTPUT [EXPECTED_REMOVAL_COUNT]
#   apply INPUT EXPECTED_SHA256 EXPECTED_REMOVAL_COUNT

loader ← •Import "../src_next/loader.bqn"
actual_source ← •Import "../src_next/actual_source.bqn"
cleanup ← •Import "journal_reconstructible_identity_cleanup.bqn"
util ← •Import "../src/text/parse.bqn"

args ← •args
tab ← @+9

Fail ← { 𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}

ComputeSha256 ← { 𝕊 filePath:
  shRes ← •SH ⟨"shasum", "-a", "256", filePath⟩
  (0 = 0 ⊑ shRes) ◶ ⟨
    { 𝕊: "" },
    { 𝕊: 64 ↑ > 1 ⊑ shRes }
  ⟩ @
}

ResolveJournalFile ← { 𝕊 inputPath:
  isDir ← (•file.Exists (inputPath ∾ "/config.tsv")) ∨ (•file.Exists (inputPath ∾ "/accounts.tsv"))
  isDir ◶ ⟨
    { 𝕊: inputPath },
    { 𝕊:
      route ← actual_source.Resolve inputPath
      inputPath ∾ "/" ∾ route.file
    }
  ⟩ @
}

RunInspect ← { 𝕊 cmdArgs:
  rawInput ← (1 < ≠ cmdArgs) ◶ ⟨ { 𝕊: "." }, { 𝕊: 1 ⊑ cmdArgs } ⟩ @
  inputPath ← ResolveJournalFile rawInput
  (•file.Exists inputPath) ◶ ⟨
    { 𝕊: Fail "input_file_not_found" },
    { 𝕊:
      raw ← loader.ReadRaw inputPath
      an ← cleanup.Analyze ⟨raw, "historical_external_plan"⟩
      (an.state ≡ "ok") ◶ ⟨
        { 𝕊: Fail ("inspect_analysis_failed " ∾ an.code) },
        { 𝕊:
          •Out "Journal Reconstructible Identity Cleanup Inspect"
          •Out "total_transactions=" ∾ •Fmt an.total_transactions
          •Out "explicit_event_id=" ∾ •Fmt an.explicit_event_id
          •Out "identity_free=" ∾ •Fmt an.identity_free
          •Out "removable_count=" ∾ •Fmt an.removable_count
          •Out "preserved_functional=" ∾ •Fmt an.preserved_functional
          •Out "preserved_purchase=" ∾ •Fmt an.preserved_purchase
          •Out "rejected_unknown=" ∾ •Fmt an.rejected_unknown
          •Exit 0
        }
      ⟩ @
    }
  ⟩ @
}

RunCandidate ← { 𝕊 cmdArgs:
  (2 < ≠ cmdArgs) ◶ ⟨
    { 𝕊: Fail "candidate_requires_input_and_output" },
    { 𝕊:
      rawInput ← 1 ⊑ cmdArgs
      outputPath ← 2 ⊑ cmdArgs
      expectedCount ← (3 < ≠ cmdArgs) ◶ ⟨ { 𝕊: 390 }, { 𝕊: util.ToNum 3 ⊑ cmdArgs } ⟩ @
      inputPath ← ResolveJournalFile rawInput

      (•file.Exists inputPath) ◶ ⟨
        { 𝕊: Fail "input_file_not_found" },
        { 𝕊:
          (¬ •file.Exists outputPath) ◶ ⟨
            { 𝕊: Fail "output_file_already_exists" },
            { 𝕊:
              raw ← loader.ReadRaw inputPath
              candRes ← cleanup.BuildCandidate ⟨raw, "historical_external_plan", expectedCount⟩

              (candRes.state ≡ "ok") ◶ ⟨
                { 𝕊: Fail ("candidate_validation_failed " ∾ candRes.code) },
                { 𝕊:
                  candTempPath ← outputPath ∾ ".tmp." ∾ •Fmt •UnixTime @
                  writeRes ← candTempPath •file.Chars candRes.candidate_raw

                  candMvRes ← •SH ⟨"mv", candTempPath, outputPath⟩
                  (0 = 0 ⊑ candMvRes) ◶ ⟨
                    { 𝕊:
                      rmRes ← •SH ⟨"rm", "-f", candTempPath⟩
                      Fail "atomic_rename_failed"
                    },
                    { 𝕊:
                      •Out "OK" ∾ tab ∾ "CANDIDATE_PUBLISHED" ∾ tab ∾ •Fmt expectedCount ∾ tab ∾ outputPath
                      •Exit 0
                    }
                  ⟩ @
                }
              ⟩ @
            }
          ⟩ @
        }
      ⟩ @
    }
  ⟩ @
}

RunApply ← { 𝕊 cmdArgs:
  (3 < ≠ cmdArgs) ◶ ⟨
    { 𝕊: Fail "apply_requires_input_sha_and_removal_count" },
    { 𝕊:
      rawInput ← 1 ⊑ cmdArgs
      expectedSha ← 2 ⊑ cmdArgs
      expectedCount ← util.ToNum 3 ⊑ cmdArgs
      inputPath ← ResolveJournalFile rawInput

      (•file.Exists inputPath) ◶ ⟨
        { 𝕊: Fail "input_file_not_found" },
        { 𝕊:
          currentSha ← ComputeSha256 inputPath
          (currentSha ≡ expectedSha) ◶ ⟨
            { 𝕊: Fail ("input_sha_mismatch expected:" ∾ expectedSha ∾ " actual:" ∾ currentSha) },
            { 𝕊:
              raw ← loader.ReadRaw inputPath
              applyRes ← cleanup.BuildCandidate ⟨raw, "historical_external_plan", expectedCount⟩

              (applyRes.state ≡ "ok") ◶ ⟨
                { 𝕊: Fail ("candidate_validation_failed " ∾ applyRes.code) },
                { 𝕊:
                  applyTempPath ← inputPath ∾ ".tmp." ∾ •Fmt •UnixTime @
                  writeRes ← applyTempPath •file.Chars applyRes.candidate_raw

                  preRenameSha ← ComputeSha256 inputPath
                  (preRenameSha ≡ expectedSha) ◶ ⟨
                    { 𝕊:
                      rmRes ← •SH ⟨"rm", "-f", applyTempPath⟩
                      Fail "input_file_changed_before_apply"
                    },
                    { 𝕊:
                      applyMvRes ← •SH ⟨"mv", applyTempPath, inputPath⟩
                      (0 = 0 ⊑ applyMvRes) ◶ ⟨
                        { 𝕊:
                          rmRes ← •SH ⟨"rm", "-f", applyTempPath⟩
                          Fail "atomic_rename_failed"
                        },
                        { 𝕊:
                          •Out "OK" ∾ tab ∾ "APPLIED" ∾ tab ∾ •Fmt expectedCount ∾ tab ∾ preRenameSha
                          •Exit 0
                        }
                      ⟩ @
                    }
                  ⟩ @
                }
              ⟩ @
            }
          ⟩ @
        }
      ⟩ @
    }
  ⟩ @
}

(0 < ≠ args) ◶ ⟨
  { 𝕊: Fail "usage: inspect|candidate|apply" },
  { 𝕊:
    mode ← 0 ⊑ args
    (mode ≡ "inspect") ◶ ⟨
      { 𝕊:
        (mode ≡ "candidate") ◶ ⟨
          { 𝕊:
            (mode ≡ "apply") ◶ ⟨
              { 𝕊: Fail ("unrecognized_command_mode " ∾ mode) },
              { 𝕊: RunApply args }
            ⟩ @
          },
          { 𝕊: RunCandidate args }
        ⟩ @
      },
      { 𝕊: RunInspect args }
    ⟩ @
  }
⟩ @
