#!/usr/bin/env bash
# extract_orca_props.sh
# Usage: ./extract_orca_props.sh log1.orl [log2.orl …]

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <orca_log_file> [more_files…]"
  exit 1
fi

for file in "$@"; do
  if [ ! -r "$file" ]; then
    echo "Cannot read file: $file"
    continue
  fi

  echo "=== $file ==="

  # 1) Total Enthalpy (Eh)
  enthalpy=$(grep -m1 "Total Enthalpy" "$file" | awk '{print $(NF-1)}')
  echo "Total enthalpy (Eh): ${enthalpy:-<not found>}"

  # 2) Final Gibbs Free Energy (Eh)
  gibbs=$(grep -m1 "Final Gibbs free energy" "$file" | awk '{print $(NF-1)}')
  echo "Final Gibbs free energy (Eh): ${gibbs:-<not found>}"

  # 3) Vibrational Frequencies (cm^-1)
  #
  #    - Any line with "cm**-1" (table entries) → take 2nd field
  #    - Any line with "Frequencies" followed by digits   → strip the label, split out all numbers
  #
  freqs=$(\
    grep -E 'cm\*\*-1|[Ff]requencies.*[0-9]' "$file" | \
    while read -r line; do
      if [[ "$line" =~ cm\*\*-1 ]]; then
        # table style:    12:    531.18 cm**-1
        awk '{print $2}' <<< "$line"
      else
        # summary style: Frequencies --   3142.03 3230.23  …
        sed -E 's/.*[Ff]requencies[^0-9]*//' <<< "$line" \
          | tr -s ' ' '\n'
      fi
    done | paste -sd, - \
  )

  if [ -z "$freqs" ]; then
    freqs="<none found>"
  fi

  echo "Vibrational frequencies (cm^-1): $freqs"
  echo
done
