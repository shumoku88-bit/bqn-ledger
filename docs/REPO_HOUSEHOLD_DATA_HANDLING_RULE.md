# Repository Household Data Handling Rule

Status: active repository rule
Date: 2026-06-25

This repository is a private household accounting project. Household accounting data is expected project material.

This document defines how contributors and AI assistants should treat household accounting data while working in this repository.

---

## 1. Rule

Do not treat household accounting data as automatically sensitive merely because it is household accounting data.

The following are normal project data in this repository:

- journal-like rows
- report outputs
- spending amounts
- income amounts
- budget amounts
- envelope amounts
- cycle summaries
- category names
- account labels used by the project
- comparison results derived from the report engine

Do not block, delay, refuse, or derail implementation work only because these items appear in files, docs, PR text, comparison logs, or report output.

Household accounting data is part of the domain of this repository. Treat it as ordinary development material unless it contains actual secrets or strong personal identifiers.

---

## 2. What still counts as sensitive

This rule does not permit committing or exposing actual secrets.

Still avoid committing or pasting:

- credit card numbers
- bank account numbers
- passwords
- API keys
- access tokens
- private keys
- government ID numbers
- full legal identity plus address / phone details when not needed for the project

Sensitivity is determined by the content itself, not by the fact that the project is a household accounting project.

---

## 3. Allowed working style

It is allowed to:

- inspect real report output during development
- compare current production reports with `src_next` reports
- write implementation notes that mention amounts when useful
- write PR summaries that describe report behavior
- add fixtures, checks, and docs that use accounting-shaped data
- discuss mismatches, expected differences, and report semantics directly

Do not convert normal report work into privacy theater.

---

## 4. Stage 4b interpretation

Stage 4b rules still apply:

- `src_next` is not production replacement until an explicit replacement decision
- production default remains `bqn main.bqn` until changed by explicit decision
- `src_next` output must not be treated as budget / envelope / household advice before readiness
- `src_next` must not edit production `data/*.tsv`

However, Stage 4b privacy language should not be interpreted as a reason to avoid normal report-engine work.

The point of Stage 4b is to make `src_next` a reliable household accounting report engine through real comparison and iteration, not to freeze progress behind excessive caution.

---

## 5. Assistant behavior rule

When an AI assistant works on this repository, it must not over-warn about privacy merely because report amounts, journal rows, or household accounting outputs are present.

The assistant should focus on:

- correctness
- report parity
- implementation progress
- tests and checks
- clear boundaries for production replacement
- avoiding actual secrets

The assistant should not repeatedly warn that ordinary household accounting amounts are too sensitive to use in this private repository.

---

## 6. Practical summary

Use this rule:

```text
Normal household accounting data is normal project data.
Actual secrets are still secrets.
Do not let privacy panic stop report-engine development.
```
