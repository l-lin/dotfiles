--
-- Opens a new terminal block with fzf-url in the current window, if the current block is not a terminal or fzf-url.
-- Inspired from: https://github.com/wfxr/tmux-fzf-url
--

local terminal = "com.superlogical.terminal"
local script = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("init%.lua$", "fzf-url.zsh")

local function read_terminal_text(block_id)
  local result = rex.block.call(terminal, "format", {
    block_id = block_id,
    format = "text",
    trim = true,
    unwrap = true,
    max_bytes = 983040,
  })
  if not result then
    return nil
  end
  if not result.id or result.eof then
    return result.content
  end

  local chunks = { result.content }
  local offset = #result.content
  while true do
    local part = rex.block.call(terminal, "blob_read", {
      block_id = block_id,
      id = result.id,
      offset = offset,
      max_bytes = 983040,
    })
    if not part then
      return nil
    end
    chunks[#chunks + 1] = part.data
    offset = offset + #part.data
    if part.eof or #part.data == 0 then
      break
    end
  end
  return table.concat(chunks)
end

local function extra_close(url, left, right)
  local _, closes = url:gsub(right, "")
  local _, opens = url:gsub(left, "")
  return closes > opens
end

-- Keep balanced delimiters, such as parentheses in a Wikipedia URL.
local function trim_url(url)
  while true do
    local trimmed = url:gsub("[.,;:!?']+$", "")
    if trimmed ~= url then
      url = trimmed
    elseif url:sub(-1) == ")" and extra_close(url, "%(", "%)") then
      url = url:sub(1, -2)
    elseif url:sub(-1) == "]" and extra_close(url, "%[", "%]") then
      url = url:sub(1, -2)
    elseif url:sub(-1) == "}" and extra_close(url, "%{", "%}") then
      url = url:sub(1, -2)
    else
      return url
    end
  end
end

-- Extract unique HTTP(S) URLs from the last 100 lines per block, newest lines first.
local function collect_urls(block_ids)
  local urls = {}
  local seen = {}
  for _, block_id in ipairs(block_ids) do
    local content = read_terminal_text(block_id)
    if content then
      local lines = {}
      for line in (content .. "\n"):gmatch("(.-)\n") do
        lines[#lines + 1] = line
      end
      local first = math.max(1, #lines - 99)
      for i = #lines, first, -1 do
        for raw in lines[i]:gmatch('[Hh][Tt][Tt][Pp][Ss]?://[^%s%c<>"`]+') do
          local url = trim_url(raw)
          if url:match("://[^/?#]") and not seen[url] then
            seen[url] = true
            urls[#urls + 1] = url
          end
        end
      end
    end
  end
  return urls
end

local function open_fzf_url(ctx)
  local description = assert(rex.session.describe_block({
    session_id = ctx.session_id,
    block_id = ctx.block_id,
  }))
  local block = description.block
  if block.creator_name ~= terminal or block.label == "fzf-url" then
    return false
  end

  local view = assert(rex.session.view({ session_id = ctx.session_id }))
  for _, window in ipairs(view.windows or {}) do
    if window.window_id == block.window_id then
      local block_ids = { ctx.block_id }
      for _, layer in ipairs(window.layers or {}) do
        if layer.kind == "tiled" then
          for _, pane in ipairs(layer.blocks or {}) do
            if pane.creator_name == terminal and pane.block_id ~= ctx.block_id then
              block_ids[#block_ids + 1] = pane.block_id
            end
          end
        end
      end

      local urls = collect_urls(block_ids)
      if #urls == 0 then
        -- Rex displays an action error as a floating notice in the app.
        error("No URLs found.", 0)
      end

      local command = { "zsh", script, ctx.session_id, ctx.block_id, window.zoomed_block_id or "" }
      for _, url in ipairs(urls) do
        command[#command + 1] = url
      end

      return assert(rex.session.new_layer({
        session_id = ctx.session_id,
        window_id = window.window_id,
        -- Match Extrakto: top center, half the width and height.
        bounds = { 0.25, 0, 0.5, 0.5 },
        focus = true,
        layout = rex.layout.block({
          flavor = "com.superlogical.terminal.shell",
          label = "fzf-url",
          options = { shell = "none", command = command },
        }),
      }))
    end
  end
  return false
end

rex.action({ name = "open_fzf_url", title = "Open a URL", run = open_fzf_url })
rex.bind("ctrl+q>u", "open_fzf_url")
