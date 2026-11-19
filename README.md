# md2pdf

Konverterer en Markdown-fil til PDF med pandoc og XeLaTeX, med en opsætning
der er valgt til almindelige dokumenter — breve, dokumentation, referater —
frem for pandocs default, som er tunet til videnskabelige artikler.

## Afhængigheder

```bash
sudo apt install pandoc texlive-xetex fonts-dejavu
```

`texlive-xetex` giver `xelatex`. XeLaTeX er valgt frem for standard-pdflatex,
fordi pdflatex fejler hårdt på Unicode-tegn som `≥`, `─` og `→`, og frem for
`lualatex`, fordi XeLaTeX er mærkbart hurtigere (LuaTeX indlejrer en fuld
Lua-fortolker og bygger en fontdatabase via `luaotfload`).

## Installation

Læg `md2pdf.sh` et sted i din `PATH`, fx:

```bash
install -m 755 md2pdf.sh ~/.local/bin/md2pdf
```

Vil du bruge emoji-filteret, skal `emoji.lua` ligge **samme sted som scriptet**
— det findes via scriptets egen sti, ikke via arbejdsmappen.

## Brug

```bash
md2pdf.sh dokument.md              # skriver dokument.pdf samme sted
md2pdf.sh dokument.md --toc        # ekstra pandoc-flag sendes videre
```

Output-filen får samme navn og placering som input, blot med `.pdf`.
Filnavne med mellemrum og `æøå` virker.

## Indstillinger

Sættes som miljøvariabler:

| Variabel | Default | Bemærkning |
|---|---|---|
| `MD2PDF_MAINFONT` | `DejaVu Sans` | Dækker latin, box-drawing og matematiske symboler |
| `MD2PDF_MONOFONT` | `DejaVu Sans Mono` | Nødvendig for tree-tegn (`├ ─ │ └`) i kodeblokke |
| `MD2PDF_MARGIN`   | `2.5cm` | Pandocs default er `article`-klassens smalle tekstkolonne |
| `MD2PDF_PAPER`    | `a4` | Pandoc default'er til amerikansk Letter |
| `MD2PDF_LANG`     | `da` | Kun fallback — se nedenfor |

```bash
MD2PDF_MARGIN=2cm MD2PDF_PAPER=a5 md2pdf.sh dokument.md
```

Indstillingerne kan **ikke** overskrives ved at sende et ekstra `-V`-flag med
på kommandolinjen. Pandoc slår gentagne `-V` af samme navn sammen til en liste
i stedet for at lade den sidste vinde — `-V lang=da -V lang=fr` giver
`pdflang={dafr}`. Brug miljøvariablerne.

## Sprog og orddeling

Uden en sprogindstilling orddeler LaTeX efter engelske regler, hvilket bliver
synligt i dansk tekst med lange sammensatte ord.

Scriptet læser filens YAML-blok og sætter `-V lang=$MD2PDF_LANG` **kun** hvis
filen ikke selv deklarerer et sprog. Det er med vilje: pandoc lader
kommandolinjen vinde over YAML — og det gør `--metadata` og en defaults-fil
også — så uden tjekket ville et dokument med `lang: en` blive sat med danske
orddelingsregler.

Deklarer derfor sproget i filen, når det ikke er dansk:

```yaml
---
lang: en
---
```

## Nyttig YAML-front matter

```yaml
---
title-meta: Dokumentets titel
author-meta: Kristian Nygaard Jensen
lang: da
---
```

`title-meta` sætter kun PDF-metadata. Bruger du `title:` i stedet, printer
pandoc også et centreret titelblok via `\maketitle`, hvilket bliver dobbelt op,
hvis dokumentet allerede har sin egen overskrift eller emnelinje. Tjek
resultatet med `pdfinfo fil.pdf`.

## Hårde linjeskift

Pandoc behandler et enkelt linjeskift som et mellemrum, så fx navn og adresse i
et brevhoved smelter sammen til én linje. Afslut linjen med en backslash:

```markdown
**Kristian Nygaard Jensen**\
Krudttårnsvej 121, 2791 Dragør
```

Backslash frem for to afsluttende mellemrum: begge er CommonMark, men trailing
whitespace overlever ikke en editor eller et git-hook, der trimmer linjeender.

## Emoji

DejaVu Sans indeholder ingen emoji-glyffer, så ✅, ❌, ⬜ og enhver farve-emoji
giver `Missing character`-warnings. PDF'en bliver stadig genereret — tegnet mangler
bare. Tre veje, i rækkefølge efter hvor godt de virker:

**1. Markdowns task lists**, hvis emojierne bruges som afkrydsningsfelter:

```markdown
- [x] Færdig
- [ ] Ikke færdig
```

Pandoc oversætter dem selv til `\boxtimes` og `\square`. Ingen fontafhængighed.

**2. `emoji.lua`**, hvis emojierne skal blive i kilden, fordi filen også vises
på GitHub. Læg filen ved siden af scriptet, så bruges den automatisk, og
`\usepackage{amssymb}` tilføjes. Dækker ✅ ✔ ❌ ✖ ⬜ ☑ ⚠ ➡ og fjerner
variation selector-16. Udvid `map`-tabellen efter behov.

Filteret rører ikke emoji inde i kodespans eller kodeblokke — der ville LaTeX
blive sat som rå tekst. Står de i verbatim, må de erstattes i kilden.

**3. En font med glyfferne.** Besværligt: XeLaTeX har ingen automatisk
font-fallback, så du skal skifte hele dokumentets font. Den monokrome
`fonts-noto-emoji` er desuden droppet fra Ubuntu/Mint-repos — kun
`fonts-noto-color-emoji` er pakket, og farve-emoji-fonte (COLR/bitmap)
rendrer ikke korrekt med XeLaTeX eller LuaLaTeX. Vil du ad den vej, skal
`.ttf`-filen hentes manuelt fra `googlefonts/noto-emoji` og lægges i
`~/.local/share/fonts/`.

Skal farve-emoji med for alvor, er HTML-vejen det rigtige valg i stedet:
`--pdf-engine=weasyprint` bruger systemets emoji-fonte direkte.

## Fejlsøgning

**`Unicode character X not set up for use with LaTeX`**
Du kører pdflatex. Scriptet bruger xelatex, så fejlen betyder at `xelatex`
mangler: `sudo apt install texlive-xetex`.

**`There is no ─ (U+2500) in font [lmmono10-regular]`**
Monofonten er ikke sat. Tjek at `MD2PDF_MONOFONT` ikke er overskrevet med en
font uden box-drawing-tegn.

**`lmodern.sty not found`**
`sudo apt install texlive-fonts-recommended`.

**Tjek hvilke fonte du har:**

```bash
fc-list | grep -i dejavu
fc-list | grep -iE 'symbol|emoji'
```

