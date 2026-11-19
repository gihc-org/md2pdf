#!/usr/bin/env bash
#
# md2pdf.sh — konverter en Markdown-fil til PDF med pandoc + XeLaTeX.
#
#   brug: md2pdf.sh <fil.md> [ekstra pandoc-flag ...]
#
# Kan tilpasses med miljøvariabler (se defaults nedenfor), fx:
#   MD2PDF_MARGIN=2cm ./md2pdf.sh brev.md
#
set -euo pipefail

: "${MD2PDF_MAINFONT:=DejaVu Sans}"
: "${MD2PDF_MONOFONT:=DejaVu Sans Mono}"
: "${MD2PDF_MARGIN:=2.5cm}"
: "${MD2PDF_LANG:=da}"
: "${MD2PDF_PAPER:=a4}"

die() { printf '%s: %s\n' "${0##*/}" "$1" >&2; exit 1; }

input="${1:-}"
[[ -n "$input" ]] || die "brug: ${0##*/} <fil.md> [ekstra pandoc-flag ...]"
[[ -f "$input" ]] || die "filen findes ikke: $input"
shift

for cmd in pandoc xelatex; do
  command -v "$cmd" >/dev/null || die "$cmd mangler (apt install pandoc texlive-xetex)"
done

pdf="${input%.*}.pdf"
[[ "$pdf" != "$input" ]] || die "input og output ville være samme fil: $input"

# Sæt kun sproget, hvis filen ikke selv deklarerer det i sin YAML-blok.
# Pandoc lader kommandolinjen vinde over YAML, så uden dette tjek ville
# et dokument med 'lang: en' blive orddelt efter danske regler.
lang_args=()
if ! awk '
      NR==1   { if ($0 !~ /^---[[:space:]]*$/) exit 1; next }
      inbody  { next }
      /^(---|\.\.\.)[[:space:]]*$/ { inbody=1; next }
      /^lang:[[:space:]]*[^[:space:]]/ { found=1 }
      END     { exit !found }
    ' "$input"; then
  lang_args=(-V "lang=$MD2PDF_LANG")
fi

# Valgfrit Lua-filter, der oversætter ✅ ❌ ⬜ m.fl. til LaTeX-symboler.
# Lægges ved siden af scriptet som emoji.lua; bruges kun hvis den findes.
filter_args=()
emoji_filter="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/emoji.lua"
if [[ -f "$emoji_filter" ]]; then
  filter_args=(--lua-filter="$emoji_filter" -V header-includes='\usepackage{amssymb}')
fi

pandoc \
  --pdf-engine=xelatex \
  -V mainfont="$MD2PDF_MAINFONT" \
  -V monofont="$MD2PDF_MONOFONT" \
  -V "geometry:margin=$MD2PDF_MARGIN" \
  -V "papersize=$MD2PDF_PAPER" \
  "${lang_args[@]}" \
  "${filter_args[@]}" \
  "$input" -o "$pdf" "$@"

printf '%s\n' "$pdf"

