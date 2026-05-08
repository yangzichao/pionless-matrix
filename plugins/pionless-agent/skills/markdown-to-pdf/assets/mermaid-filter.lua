-- Pandoc Lua filter: render ```mermaid code blocks as PDF images.
--
-- For each fenced code block tagged `mermaid`, write the source to a temp
-- file, invoke `mmdc` (mermaid-cli) to render it as a tightly-cropped PDF,
-- then replace the block with an Image node so pandoc/xelatex includes it
-- via \includegraphics.
--
-- Fails open: if mmdc is missing or rendering errors out, the original
-- code block is left in place and a single-line warning is printed to
-- stderr. Build_pdf.sh only attaches this filter when mmdc is on PATH,
-- so the missing-binary case should be rare.

local mmdc_bin = os.getenv("PANDOC_MERMAID_BIN") or "mmdc"
local outdir   = os.getenv("PANDOC_MERMAID_OUTDIR")
                 or os.getenv("TMPDIR")
                 or "/tmp"
outdir = outdir:gsub("/+$", "")

local counter = 0

local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close(); return true end
  return false
end

local function render(source)
  counter = counter + 1
  local stem   = string.format("%s/pandoc-mermaid-%d-%d", outdir, os.time(), counter)
  local input  = stem .. ".mmd"
  local output = stem .. ".pdf"
  local f = io.open(input, "w")
  if not f then return nil, "could not open temp file" end
  f:write(source)
  f:close()
  -- -b transparent → no white background panel
  -- --pdfFit       → crop PDF page tightly around the diagram
  local cmd = string.format(
    '%s --quiet -i %q -o %q -b transparent --pdfFit 2>&1',
    mmdc_bin, input, output
  )
  local ok, exit_kind, code = os.execute(cmd)
  -- Lua 5.1 returns just a number; 5.2+ returns (true|nil, "exit"|"signal", n)
  local success = (ok == true) or (ok == 0) or (exit_kind == "exit" and code == 0)
  if success and file_exists(output) then
    return output
  end
  return nil, "mmdc failed (exit " .. tostring(code or ok) .. ")"
end

function CodeBlock(block)
  if not block.classes:includes("mermaid") then return nil end
  local pdf, err = render(block.text)
  if not pdf then
    io.stderr:write("[mermaid-filter] " .. (err or "render failed") .. "; leaving as code.\n")
    return nil
  end
  return pandoc.Para({ pandoc.Image({}, pdf, "") })
end
