#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
# shellcheck source=../tools/lib/ui-preferences.sh
source tools/lib/ui-preferences.sh
# shellcheck source=../tools/lib/ui-choice.sh
source tools/lib/ui-choice.sh

[[ $(BL_SELECTOR=auto bl_selector_preference) == auto ]]
[[ $(BL_SELECTOR=fzf bl_selector_preference) == fzf ]]
[[ $(BL_SELECTOR=gum bl_selector_preference) == gum ]]
[[ $(BL_SELECTOR=plain bl_selector_preference) == plain ]]
if BL_SELECTOR=other bl_selector_preference >/dev/null 2>&1; then
  echo 'FAIL: invalid selector preference succeeded' >&2; exit 1
fi

[[ $(BL_FZF_PREVIEW_WINDOW=right:75% bl_fzf_preview_window) == right:75% ]]
[[ $(BL_FZF_PREVIEW_WINDOW=up:40% bl_fzf_preview_window) == up:40% ]]
[[ $(env -u BL_FZF_PREVIEW_WINDOW bash -c 'source tools/lib/ui-preferences.sh; bl_fzf_preview_window') == right:60% ]]
for invalid in right:0% right:101% center:50% right:wide 'right: 75%'; do
  if BL_FZF_PREVIEW_WINDOW="$invalid" bl_fzf_preview_window >/dev/null 2>&1; then
    echo "FAIL: invalid preview preference succeeded: $invalid" >&2; exit 1
  fi
done

# The ordinary choice adapter must preserve complete candidate rows and keep
# backend behavior physical. Fake backends make this deterministic in CI.
choice_tmp="$(mktemp -d)"
trap 'rm -rf "$choice_tmp"' EXIT
cat >"$choice_tmp/fzf" <<'EOF'
#!/usr/bin/env bash
sed -n '2p'
EOF
cat >"$choice_tmp/gum" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" == filter ]] || exit 2
sed -n '1p'
EOF
chmod +x "$choice_tmp/fzf" "$choice_tmp/gum"

[[ $(BL_UI_MODE=minimal bl_ui_choice_backend) == plain ]]
[[ $(BL_SELECTOR=plain bl_ui_choice_backend) == plain ]]
choice_out="$(printf 'alpha\tA\nbeta\tB\n' | PATH="$choice_tmp:$PATH" BL_SELECTOR=fzf bl_ui_choose_line 'test choice')"
[[ "$choice_out" == $'beta\tB' ]]
choice_out="$(printf 'alpha\tA\nbeta\tB\n' | PATH="$choice_tmp:$PATH" BL_SELECTOR=gum bl_ui_choose_line 'test choice')"
[[ "$choice_out" == $'alpha\tA' ]]
if printf '' | PATH="$choice_tmp:$PATH" BL_SELECTOR=fzf bl_ui_choose_line 'empty choice' >/dev/null 2>&1; then
  echo 'FAIL: empty ordinary choice unexpectedly succeeded' >&2; exit 1
fi

if rg -n 'fzf_preview_window' tools/main-ui.sh | rg 'config\.tsv|awk'; then
  echo 'FAIL: terminal UI preference leaked into ledger config ownership' >&2; exit 1
fi
if rg -n 'config\.tsv|LEDGER_DATA_DIR|DEFAULT_BASE_DIR' tools/lib/theme.sh; then
  echo 'FAIL: terminal theme still depends on a Household/default data source' >&2; exit 1
fi

# Ordinary one-of-lines choice is now shared by the daily-entry and Plan-finish
# workflows. Keep direct fzf/gum choice execution limited to the two specialized
# menu runtimes that still have distinct contracts (Command Hub and report UI).
expected_choice_backend_owners=$(cat <<'EOF'
tools/bl
tools/main-ui.sh
EOF
)
actual_choice_backend_owners=$(
  rg -l '(^|[[:space:]])fzf([[:space:]]|$)|(^|[[:space:]])gum[[:space:]]+(choose|filter)([[:space:]]|$)' tools \
    --glob '!tools/lib/*' \
    | sort
)
if [[ "$actual_choice_backend_owners" != "$expected_choice_backend_owners" ]]; then
  echo 'FAIL: direct ordinary-choice backend owner set changed' >&2
  echo 'Expected:' >&2
  printf '%s\n' "$expected_choice_backend_owners" >&2
  echo 'Actual:' >&2
  printf '%s\n' "$actual_choice_backend_owners" >&2
  echo 'Route ordinary candidate selection through tools/lib/ui-choice.sh.' >&2
  exit 1
fi

for consumer in tools/add-ui.sh tools/plan-finish-replenish-ui.sh; do
  if ! grep -Fq 'source "$ROOT_DIR/tools/lib/ui-choice.sh"' "$consumer"; then
    echo "FAIL: $consumer does not source the shared ordinary choice adapter" >&2
    exit 1
  fi
done

# Free-text entry is a different physical-input contract. It is intentionally
# not generalized by the choice adapter, so keep its remaining gum ownership
# explicit instead of pretending the whole gum dependency disappeared.
expected_text_input_owners=$(cat <<'EOF'
tools/add-ui.sh
tools/plan-finish-replenish-ui.sh
EOF
)
actual_text_input_owners=$(
  rg -l '(^|[[:space:]])gum[[:space:]]+input([[:space:]]|$)' tools \
    --glob '!tools/lib/*' \
    | sort
)
if [[ "$actual_text_input_owners" != "$expected_text_input_owners" ]]; then
  echo 'FAIL: direct text-input backend owner set changed' >&2
  echo 'Expected:' >&2
  printf '%s\n' "$expected_text_input_owners" >&2
  echo 'Actual:' >&2
  printf '%s\n' "$actual_text_input_owners" >&2
  exit 1
fi

grep -F 'BL_THEME=nord' .env.example >/dev/null
grep -F 'BL_FZF_PREVIEW_WINDOW=right:75%' .env.example >/dev/null
grep -F 'BL_SELECTOR=auto' .env.example >/dev/null
echo 'check-ui-preferences: OK'
