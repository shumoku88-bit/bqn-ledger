# Wide report pager plan

Status: planned / docs-only
Date: 2026-06-30

## Problem

Some report sections are too wide for the current gum/fzf-oriented browsing flow.

The immediate example is `daily-flow`: it is useful as a horizontal table, but wide rows are hard to read when they are printed through the normal command hub / section selector path.

The goal is not to redesign the report yet. The goal is to add a safe viewing path for wide report sections.

## Current boundary

- `tools/bl` is the day-to-day command hub.
- `tools/main-ui.sh` is the lower-level report section UI.
- `tools/report` / `src_next/report.bqn` remain the canonical report output path.
- Wide viewing must not change source TSV, report calculation, Cube shape, or section semantics.
- Plain stdout must remain available for grep, diff, tests, and redirection.

## Proposed direction

Add an explicit pager route for sections:

```bash
tools/bl view <section>
tools/bl wide <section>
```

Initial behavior:

```bash
tools/bl wide daily-flow
```

should be equivalent to:

```bash
tools/bl section daily-flow | less -R -S
```

The command name can be decided during implementation. `wide` is clearer for horizontal tables. `view` is more general.

## Default pager recommendation

Use `less -R -S` as the default wide report viewer.

Reasons:

- `-S` keeps long lines from wrapping and allows horizontal movement with RIGHT/LEFT.
- `-R` preserves ANSI SGR color safely enough for colored terminal output.
- `less` is commonly available and stable.
- It does not add a new project dependency.
- It keeps report generation separate from report viewing.

Suggested default:

```bash
LEDGER_WIDE_PAGER=${LEDGER_WIDE_PAGER:-less -R -S}
```

Implementation should avoid fragile string eval where possible. If a shell command string is supported, document the risk and keep the default simple.

## Candidate tools

| Tool | Fit | Notes |
|---|---|---|
| `less -R -S` | default | Best initial fit for horizontal report tables. |
| `gum pager --no-soft-wrap` | optional | Nice visual pager, but should remain optional because gum behavior can vary by version and it is not as battle-tested as less for wide plain-text tables. |
| `fzf --preview` | selector preview | Good for choosing sections, not ideal as the final wide report viewer. Keep it for navigation. |
| `bat` | optional formatter | Good for syntax-colored files, not necessary for generated report sections. |
| `moar` | optional external pager | Interesting modern pager, but adding another dependency is not justified yet. |
| `ov` | optional external pager | Powerful pager for logs/structured viewing, but too much dependency weight for the first pass. |
| terminal scrollback | fallback | Works for short reports only; poor fit for wide daily tables. |

## Non-goals

Do not do these in the first implementation:

- redesign `daily-flow` into a narrower report
- add table virtualization
- add terminal width detection to the report engine
- add a new required pager dependency
- change `tools/bl section <key>` behavior
- remove plain stdout output
- change source TSV or report calculation

## Implementation sketch

### Phase 1: command hub pager route

Add direct subcommands to `tools/bl`:

```bash
tools/bl view <section>
tools/bl wide <section>
```

Both should:

1. resolve `--base` exactly like existing commands
2. call the existing section route
3. pipe the selected section to the configured pager
4. return the section command status if report generation fails

Possible implementation shape:

```bash
run_section() {
  local section_key="$1"
  "$ROOT_DIR/tools/main-ui.sh" --base "$base_dir" "$section_key"
}

run_wide() {
  local section_key="$1"
  if [[ -z "$section_key" ]]; then
    echo "Error: wide requires a section key" >&2
    usage >&2
    exit 1
  fi
  run_section "$section_key" | ${LEDGER_WIDE_PAGER:-less -R -S}
}
```

This sketch is illustrative only. The implementation must handle shell quoting carefully.

### Phase 2: safer pager command handling

Prefer either:

```bash
pager_cmd=(less -R -S)
run_section "$section_key" | "${pager_cmd[@]}"
```

or a small allowlist:

```text
less
less-wide
gum-pager
cat
```

Avoid making arbitrary pager strings too magical unless the risk is intentionally accepted.

### Phase 3: optional gum pager fallback

If `less` is missing but `gum` exists, the implementation may try:

```bash
gum pager --no-soft-wrap
```

This should be optional, not required.

### Phase 4: documentation and examples

Document examples:

```bash
tools/bl section daily-flow

tools/bl wide daily-flow

LEDGER_WIDE_PAGER="less -R -S" tools/bl wide daily-flow
```

## Acceptance criteria

- `tools/bl section daily-flow` still prints plain output.
- `tools/bl wide daily-flow` opens only the selected section in a pager.
- The default pager does not wrap wide rows.
- Color output remains readable when color is enabled.
- Unknown section keys fail closed with the same underlying section error.
- Non-TTY usage still has a plain-output route.
- No source TSV files are edited.
- No report calculation logic is changed.

## Test ideas

- `tools/bl section daily-flow >/tmp/daily-flow.txt`
- `tools/bl wide daily-flow` manually checked in a TTY
- `LEDGER_WIDE_PAGER=cat tools/bl wide daily-flow` for non-interactive smoke behavior
- invalid section key returns non-zero
- `tools/check.sh` after implementation

## Relationship to report mocks

The mock report files under `mocks/reports/` define the visible surface.

Wide pager support is a viewing route for those report surfaces. It should not become a second report format.

If a mock is too wide to read comfortably in the default selector preview, that is a signal to use the pager route, not necessarily a signal to shrink the report.
