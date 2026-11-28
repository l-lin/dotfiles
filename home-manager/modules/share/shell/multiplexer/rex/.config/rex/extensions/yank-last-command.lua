--
-- Yank the last executed command and its output from the focused terminal pane.
--

local terminal = "com.superlogical.terminal"

---Read the full plain-text scrollback of a terminal block.
---@param block_id string
---@return string|nil
local function read_terminal_text(block_id)
  local result, err = rex.block.call(terminal, "format", {
    block_id = block_id,
    format = "text",
    trim = true,
    unwrap = true,
    max_bytes = 983040,
  })
  if not result then
    rex.log("warn", "Failed to read terminal content: " .. tostring(err))
    return nil
  end
  if not result.id or result.eof then
    return result.content
  end

  local chunks = { result.content }
  local offset = #result.content
  while true do
    local part, read_err = rex.block.call(terminal, "blob_read", {
      block_id = block_id,
      id = result.id,
      offset = offset,
      max_bytes = 983040,
    })
    if not part then
      rex.log("warn", "Failed to read terminal scrollback chunk: " .. tostring(read_err))
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

---Copy text to the system clipboard.
---@param text string
local function copy_to_clipboard(text)
  local clipboard_commands = {
    { "pbcopy" },
    { "wl-copy" },
    { "xclip", "-selection", "clipboard" },
    { "xsel", "--clipboard", "--input" },
  }
  for _, command in ipairs(clipboard_commands) do
    -- Set LC_CTYPE=UTF-8 so macOS pbcopy treats stdin as UTF-8 instead of MacRoman.
    local result = rex.exec(command, { stdin = text, env = { LC_CTYPE = "UTF-8" }, timeout = 2 })
    if result and result.ok then
      return true
    end
  end
  rex.log("warn", "No clipboard command succeeded.")
  return false
end

---Check whether a line starts with the Powerlevel10k prompt symbol.
---@param line string
---@return boolean
local function is_prompt_line(line)
  -- Match the configured p10k prompt symbols (viins, vicmd, vivis, viowr).
  return line:match("^❯") ~= nil or line:match("^❮") ~= nil or line:match("^V ") ~= nil or line:match("^▶") ~= nil
end

---Extract the last executed command and its output from plain-text scrollback.
---Rex does not expose OSC 133 prompt markers in copy mode or format output,
---so this locates prompts using the configured p10k two-line prompt layout:
---  header line (dir / ruler)
---  ❯ <command>
---  <output...>
---  header line (next prompt)
---  ❯
---@param content string
---@return string|nil
local function extract_last_command_and_output(content)
  local lines = {}
  for line in (content .. "\n"):gmatch("(.-)\n") do
    lines[#lines + 1] = line
  end
  -- Drop trailing blank lines from the empty bottom of the terminal viewport.
  while #lines > 0 and lines[#lines] == "" do
    lines[#lines] = nil
  end

  local prompt_indices = {}
  for i, line in ipairs(lines) do
    if is_prompt_line(line) then
      prompt_indices[#prompt_indices + 1] = i
    end
  end

  if #prompt_indices < 2 then
    return nil
  end

  local start_index = prompt_indices[#prompt_indices - 1]
  local next_prompt_index = prompt_indices[#prompt_indices]
  -- Exclude the p10k header line directly above the next prompt when present.
  local end_index = next_prompt_index - 1
  if end_index > start_index and lines[end_index]:find("───", 1, true) then
    end_index = end_index - 1
  end
  if end_index < start_index then
    return nil
  end

  return table.concat(lines, "\n", start_index, end_index)
end

---Yank the last executed command and its output from the focused terminal pane.
---@param ctx rex.action_context
local function yank_last_command_and_output(ctx)
  local content = read_terminal_text(ctx.block_id)
  if not content then
    return false
  end

  local snippet = extract_last_command_and_output(content)
  if not snippet then
    return false
  end

  return copy_to_clipboard(snippet)
end

rex.action({
  name = "yank_last_command_and_output",
  title = "Yank Last Command and Output",
  run = yank_last_command_and_output,
})
rex.bind("ctrl+q>y", "yank_last_command_and_output")
