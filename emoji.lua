-- emoji.lua — oversætter almindelige status-emoji til LaTeX-symboler,
-- så XeLaTeX ikke brokker sig over manglende glyffer i DejaVu Sans.
-- Kræver \usepackage{amssymb} (md2pdf.sh tilføjer den selv).

local map = {
  ["✅"] = "$\\checkmark$",
  ["✔"]  = "$\\checkmark$",
  ["❌"] = "$\\times$",
  ["✖"]  = "$\\times$",
  ["⬜"] = "$\\square$",
  ["☑"]  = "$\\boxtimes$",
  ["⚠"]  = "$\\triangle$",
  ["➡"]  = "$\\rightarrow$",
  ["\u{FE0F}"] = "",  -- variation selector-16, usynlig men tæller som tegn
}

function Str(el)
  local out, buf = {}, {}

  local function flush()
    if #buf > 0 then
      table.insert(out, pandoc.Str(table.concat(buf)))
      buf = {}
    end
  end

  local hit = false
  for _, cp in utf8.codes(el.text) do
    local ch = utf8.char(cp)
    local sub = map[ch]
    if sub then
      hit = true
      flush()
      if sub ~= "" then
        table.insert(out, pandoc.RawInline("latex", sub))
      end
    else
      table.insert(buf, ch)
    end
  end

  if not hit then return nil end  -- lad noden være urørt
  flush()
  return out
end
