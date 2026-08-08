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
grep -F 'BL_THEME=nord' .env.example >/dev/null
grep -F 'BL_FZF_PREVIEW_WINDOW=right:75%' .env.example >/dev/null
grep -F 'BL_SELECTOR=auto' .env.example >/dev/null
echo 'check-ui-preferences: OK'
