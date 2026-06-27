#!/usr/bin/env bash

# Resolve system defaults from config/system_defaults.tsv

get_default_base_dir() {
  local defaults_file="config/system_defaults.tsv"
  local fallback="data"
  if [[ -f "$defaults_file" ]]; then
    local val
    val=$(awk -F'\t' '$1 == "DEFAULT_BASE_DIR" { print $2 }' "$defaults_file")
    if [[ -n "$val" ]]; then
      printf '%s\n' "$val"
      return 0
    fi
  fi
  printf '%s\n' "$fallback"
}

get_system_default_file() {
  local key="$1"
  local fallback="$2"
  local defaults_file="config/system_defaults.tsv"
  if [[ -f "$defaults_file" ]]; then
    local val
    val=$(awk -F'\t' -v k="$key" '$1 == k { print $2 }' "$defaults_file")
    if [[ -n "$val" ]]; then
      printf '%s\n' "$val"
      return 0
    fi
  fi
  printf '%s\n' "$fallback"
}
