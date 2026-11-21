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
  local output = stem .. ".svg"
  local f = io.open(input, "w")
  if not f then return nil, "could not open temp file" end
  f:write(source)
  f:close()
  -- -b transparent → no white background panel
  local cmd = string.format(
    '%s --quiet -i %q -o %q -b transparent 2>&1',
    mmdc_bin, input, output
  )
  local ok, exit_kind, code = os.execute(cmd)
  local success = (ok == true) or (ok == 0) or (exit_kind == "exit" and code == 0)
  if success and file_exists(output) then
    return output
  end
  return nil, "mmdc failed (exit " .. tostring(code or ok) .. ")"
end

function CodeBlock(block)
  if not block.classes:includes("mermaid") then return nil end
  local svg, err = render(block.text)
  if not svg then
    io.stderr:write("[mermaid-filter] " .. (err or "render failed") .. "; leaving as code.\n")
    return nil
  end
  return pandoc.Para({ pandoc.Image({}, svg, "", pandoc.Attr("", { "mermaid-diagram" })) })
end
