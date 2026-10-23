#!/bin/bash
# Pinned P0 inputs are the independent source for these rejection expectations.
set -euo pipefail
runner=$1
cohort=$2
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
checks=0

reject() {
  local name=$1 expected=$2 limit=$3 selection=$4
  printf '%s\n' "$selection" > "$scratch/selection.json"
  rm -f "$scratch/result.json"
  if "$runner" p1 "$cohort" "$scratch/selection.json" "$scratch/result.json" "$limit" > "$scratch/log" 2>&1; then
    echo "FAIL $name: invalid pinned input was accepted" >&2
    exit 1
  fi
  grep -Fq "$expected" "$scratch/log"
  test ! -e "$scratch/result.json"
  checks=$((checks + 1))
  echo "PASS $name"
}

reject wrong-hero 'P1 selection metadata' 1 '[{"game":"b7-Warrior-Mage","turn":8,"ply":9,"hero":"Priest","reason":"first-advanced-legal-ordinary-two-soldiers"}]'
reject wrong-ply 'P1 selection metadata' 1 '[{"game":"b7-Warrior-Mage","turn":8,"ply":8,"hero":"Warrior","reason":"first-advanced-legal-ordinary-two-soldiers"}]'
reject unknown-reason 'P1 selection reason' 1 '[{"game":"b7-Warrior-Mage","turn":8,"ply":9,"hero":"Warrior","reason":"invented"}]'
reject wrong-selection-category 'P1 selection reason' 1 '[{"game":"b7-Warrior-Mage","turn":8,"ply":9,"hero":"Warrior","reason":"first-observed-skill-soldier"}]'
reject missing-requested-position 'P1 selection count' 2 '[{"game":"b7-Warrior-Mage","turn":8,"ply":9,"hero":"Warrior","reason":"first-advanced-legal-ordinary-two-soldiers"}]'
reject zero-limit 'P1 maxPositions 1...16' 0 '[]'
echo "P1_CONTRACT_CHECKS=$checks"
