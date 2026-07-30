#!/usr/bin/env bqn

catalog ← •Import "add_ui_action_catalog.bqn"
validation ← catalog.Validate catalog.catalog
{𝕊: •Out¨catalog.Rows catalog.catalog}⍟(validation.state≡"ok") @
{𝕊: •Exit 1}⍟(validation.state≢"ok") @
