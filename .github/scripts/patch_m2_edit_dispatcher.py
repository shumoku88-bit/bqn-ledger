#!/usr/bin/env python3
from pathlib import Path

path = Path("tools/edit-bqn")
text = path.read_text(encoding="utf-8")

replacements = [
    (
        "  tools/edit-bqn [--base DIR] journal add --date YYYY-MM-DD --memo MEMO --from ACCOUNT --to ACCOUNT --amount INT [--meta key=value ...] [--dry-run] [--yes] [--post-check none|lint|full]",
        "  tools/edit-bqn [--base DIR] journal add --date YYYY-MM-DD --memo MEMO --from ACCOUNT --to ACCOUNT --amount DECIMAL [--currency JPY|ILS] [--meta key=value ...] [--dry-run] [--yes] [--post-check none|lint|full]",
    ),
    (
        "  tools/edit-bqn [--base DIR] account add --name ACCOUNT --role asset|liability|income|expense [--type liquid|savings|invest] [--dry-run] [--yes] [--post-check none|lint|full]",
        "  tools/edit-bqn [--base DIR] account add --name ACCOUNT --role asset|liability|income|expense [--type liquid|savings|invest] [--currency JPY|ILS] [--dry-run] [--yes] [--post-check none|lint|full]",
    ),
    (
        "  tools/edit-bqn [--base DIR] account list [--role ROLE]",
        "  tools/edit-bqn [--base DIR] account list [--role ROLE] [--currency JPY|ILS]",
    ),
    (
        "  TYPE=\"\"\n  DRY_RUN=0",
        "  TYPE=\"\"\n  CURRENCY=\"\"\n  DRY_RUN=0",
    ),
    (
        "      --type) TYPE=\"$(get_opt_val \"$1\" \"${2-}\")\"; shift 2 ;;\n      --dry-run)",
        "      --type) TYPE=\"$(get_opt_val \"$1\" \"${2-}\")\"; shift 2 ;;\n      --currency) CURRENCY=\"$(get_opt_val \"$1\" \"${2-}\")\"; shift 2 ;;\n      --dry-run)",
    ),
    (
        "bqn src_edit/account_add_cmd.bqn \"$BASE_DIR\" \"$NAME\" \"$ROLE\" \"$TYPE\" 2>",
        "bqn src_edit/account_add_cmd.bqn \"$BASE_DIR\" \"$NAME\" \"$ROLE\" \"$TYPE\" \"$CURRENCY\" 2>",
    ),
    (
        "  ROLE=\"\"\n  while [[ $# -gt 0 ]]; do\n    case \"$1\" in\n      --role) ROLE=\"$(get_opt_val \"$1\" \"${2-}\")\"; shift 2 ;;\n      *) echo \"ERROR: unknown account list argument: $1\" >&2; exit 2 ;;\n    esac\n  done\n  cd \"$ROOT_DIR\" && bqn src_edit/account_list_cmd.bqn \"$BASE_DIR\" \"$ROLE\"",
        "  ROLE=\"\"\n  CURRENCY=\"\"\n  while [[ $# -gt 0 ]]; do\n    case \"$1\" in\n      --role) ROLE=\"$(get_opt_val \"$1\" \"${2-}\")\"; shift 2 ;;\n      --currency) CURRENCY=\"$(get_opt_val \"$1\" \"${2-}\")\"; shift 2 ;;\n      *) echo \"ERROR: unknown account list argument: $1\" >&2; exit 2 ;;\n    esac\n  done\n  cd \"$ROOT_DIR\" && bqn src_edit/account_list_cmd.bqn \"$BASE_DIR\" \"$ROLE\" \"$CURRENCY\"",
    ),
    (
        "AMOUNT=\"\"\nMETA=()",
        "AMOUNT=\"\"\nCURRENCY=\"\"\nMETA=()",
    ),
    (
        "    --amount) AMOUNT=\"$(get_opt_val \"$1\" \"${2-}\")\"; shift 2 ;;\n    --meta)",
        "    --amount) AMOUNT=\"$(get_opt_val \"$1\" \"${2-}\")\"; shift 2 ;;\n    --currency) CURRENCY=\"$(get_opt_val \"$1\" \"${2-}\")\"; shift 2 ;;\n    --meta)",
    ),
    (
        "edit_bqn_validate_post_check \"$POST_CHECK\"\n\nTARGET_PATH=",
        "if [[ \"$COMMAND\" != \"journal\" && -n \"$CURRENCY\" ]]; then\n  echo \"ERROR: --currency is currently supported only for journal add\" >&2\n  exit 2\nfi\nedit_bqn_validate_post_check \"$POST_CHECK\"\n\nTARGET_PATH=",
    ),
    (
        "bqn src_edit/journal_add_cmd.bqn \"$BASE_DIR\" \"$COMMAND\" \"$DATE\" \"$MEMO\" \"$FROM\" \"$TO\" \"$AMOUNT\" \"${META[@]}\" 2>",
        "bqn src_edit/journal_add_cmd.bqn \"$BASE_DIR\" \"$COMMAND\" \"$DATE\" \"$MEMO\" \"$FROM\" \"$TO\" \"$AMOUNT\" \"$CURRENCY\" \"${META[@]}\" 2>",
    ),
]

for old, new in replacements:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"expected exactly one match, got {count}: {old[:120]!r}")
    text = text.replace(old, new, 1)

path.write_text(text, encoding="utf-8")
