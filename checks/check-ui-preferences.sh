#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
# shellcheck source=../tools/lib/ui-preferences.sh
source tools/lib/ui-preferences.sh

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

if rg -n 'fzf_preview_window' tools/main-ui.sh | rg 'config\.tsv|awk'; then
  echo 'FAIL: terminal UI preference leaked into ledger config ownership' >&2; exit 1
fi
if rg -n 'config\.tsv|LEDGER_DATA_DIR|DEFAULT_BASE_DIR' tools/lib/theme.sh; then
  echo 'FAIL: terminal theme still depends on a Household/default data source' >&2; exit 1
fi

# Direct optional-selector backend execution is migration debt, not a pattern for
# new workflow owners. Keep the current owner set explicit while ordinary choice
# selection is moved behind a physical UI adapter. Specialized report preview may
# remain distinct until another real consumer demonstrates the same contract.
expected_backend_owners=$(cat <<'EOF'
tools/add-ui.sh
tools/bl
tools/main-ui.sh
tools/plan-finish-replenish-ui.sh
EOF
)
actual_backend_owners=$(
  rg -l 'command -v (fzf|gum)|(^|[[:space:]])(fzf|gum) (choose|filter|input)' tools \
    --glob '!tools/lib/*' \
    | sort
)
if [[ "$actual_backend_owners" != "$expected_backend_owners" ]]; then
  echo 'FAIL: direct selector backend owner set changed' >&2
  echo 'Expected:' >&2
  printf '%s\n' "$expected_backend_owners" >&2
  echo 'Actual:' >&2
  printf '%s\n' "$actual_backend_owners" >&2
  echo 'Add new selector behavior through the UI boundary instead of copying backend switches.' >&2
  exit 1
fi

grep -F 'BL_THEME=nord' .env.example >/dev/null
grep -F 'BL_FZF_PREVIEW_WINDOW=right:75%' .env.example >/dev/null
grep -F 'BL_SELECTOR=auto' .env.example >/dev/null
echo 'check-ui-preferences: OK'
