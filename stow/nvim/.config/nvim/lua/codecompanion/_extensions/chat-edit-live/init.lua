--
-- Extension to remove messages from the chat history, while preserving
-- conversation flow.
-- src: https://github.com/olimorris/codecompanion.nvim/discussions/1706
--

-- ── DEBUG (opt-in) ────────────────────────────────────────────────────────────
local DEBUG = false
local function dbg(tag, payload)
  if DEBUG then
    print(("%s: %s"):format(tag, vim.inspect(payload)), vim.log.levels.DEBUG)
  end
end

---@class ChatEditLivePickerItem
---@field idx     integer
---@field text    string
---@field label   string
---@field message table

-- helpers ----------------------------------------------------------------------
local function ends_with_empty_user(msgs)
  local last = msgs[#msgs]
  return last and last.role == "user" and (last.content or "") == ""
end


local function ensure_trailing_empty(orig, kept, current_cycle)
  dbg("ensure_trailing_empty ‑ before", kept)

  -- Only add empty user if we have messages and don't already end with empty user
  if #kept == 0 or ends_with_empty_user(kept) then return end

  -- choose template (last user or fabricated)
  local template
  local last_orig = orig[#orig]
  if last_orig and last_orig.role == "user" then
    template = last_orig
  else
    for i = #orig, 1, -1 do
      if orig[i].role == "user" then
        template = orig[i]; break
      end
    end
  end
  if not template then
    template = { role = "user", content = "", opts = { visible = true } }
  end

  -- blank and wipe identifiers → treated as a *new* message
  local msg = vim.deepcopy(template)
  msg.content = ""
  msg.id = nil
  msg.cycle = current_cycle + 1 -- Increment cycle for the new message
  kept[#kept + 1] = msg
  dbg("ensure_trailing_empty ‑ after", kept)
end

-- Update the apply function to properly set header_line
local function apply(chat, new_msgs)
  dbg("apply ‑ new_msgs", new_msgs)

  -- Clear the chat and rebuild it
  chat.messages = {}
  chat.refs = {}
  chat.cycle = 1
  chat.header_line = 1

  -- Clear buffer
  vim.api.nvim_buf_set_lines(chat.bufnr, 0, -1, false, {})

  -- Reset UI state
  if chat.ui then
    chat.ui.last_role = nil
    chat.ui.intro_message = nil
  end

  -- Now assign the new messages and render
  chat.messages = new_msgs
  if chat.agents then
    chat.agents.messages = new_msgs
  end

  -- Update cycle to the highest cycle in messages
  local max_cycle = 1
  for _, msg in ipairs(new_msgs) do
    if msg.cycle and msg.cycle > max_cycle then
      max_cycle = msg.cycle
    end
  end
  chat.cycle = max_cycle

  -- Add system prompt back if it was removed
  if chat.add_system_prompt then
    chat:add_system_prompt()
  end

  -- Ensure we have a trailing empty user message for input
  local original_messages = vim.deepcopy(chat.messages)
  ensure_trailing_empty(original_messages, chat.messages, chat.cycle)

  -- Render the UI with all messages including the empty one
  if chat.ui then
    chat.ui:render(chat.context, chat.messages, chat.opts)
  end

  -- Wait for render to complete before setting cursor
  vim.schedule(function()
    -- Find and set the header_line to the last User header
    local lines = vim.api.nvim_buf_get_lines(chat.bufnr, 0, -1, false)
    local last_user_header_line = nil

    for i = #lines, 1, -1 do
      local line = lines[i]
      if line:match("^## User") then
        last_user_header_line = i
        break
      end
    end

    if last_user_header_line then
      chat.header_line = last_user_header_line
      dbg("apply - set header_line to", chat.header_line)
    else
      -- Fallback: set to end of buffer minus 2 (account for empty lines)
      chat.header_line = math.max(1, #lines - 2)
      dbg("apply - fallback header_line to", chat.header_line)
    end

    -- Move cursor to the end of the buffer (safely)
    local line_count = vim.api.nvim_buf_line_count(chat.bufnr)
    if line_count > 0 and vim.api.nvim_buf_is_valid(chat.bufnr) then
      -- Ensure we're in the correct window for this buffer
      local win = vim.fn.bufwinid(chat.bufnr)
      if win ~= -1 then
        vim.api.nvim_win_set_cursor(win, { line_count, 0 })
      end
    end

    vim.notify(
      "Chat history updated. Start typing to continue the conversation.",
      vim.log.levels.INFO
    )
  end)
end


-- build list to keep -----------------------------------------------------------
---@param msgs table  original chat.messages
---@param cut  integer index of user message to cut (1-based, inclusive)
---@return table
local function build_kept(msgs, cut)
  dbg("build_kept ‑ input", { cut = cut, total = #msgs })
  local kept = {}

  -- Copy all messages before the cut point
  for i = 1, cut - 1 do
    kept[#kept + 1] = vim.deepcopy(msgs[i])
  end

  -- Ensure we don't end with a trailing user message
  -- Remove any trailing user messages that don't have LLM responses
  while #kept > 0 and kept[#kept].role == "user" do
    table.remove(kept)
  end

  dbg("build_kept ‑ result", kept)
  return kept
end

-- picker variant ---------------------------------------------------------------
local function remove_chat_messages(chat)
  local messages, items = chat.messages or {}, {}

  for i, msg in ipairs(messages) do
    if msg.role == "user" then
      items[#items + 1] = {
        msg_idx = i,
        text    = ("%s:%s"):format(msg.id, msg.cycle or ""),
        label   = ("[user] %s"):format((msg.content or ""):gsub("\n", " "):sub(1, 80)),
        message = msg,
      }
    end
  end

  -- Add debug to show the picker items
  dbg("picker items built", items)

  if #items == 0 then
    vim.notify("No user messages to remove.", vim.log.levels.WARN)
    return
  end

  local function confirm(picker)
    local sel = picker:selected({ fallback = true })
    dbg("confirm ‑ selection raw", sel)
    if #sel == 0 then return end

    local cut = 0
    for _, v in ipairs(sel) do
      local item
      if type(v) == "table" and v._select_key then
        dbg("Looking for _select_key", v._select_key)
        -- Find the original item by matching the _select_key (which is the text field)
        for _, original_item in ipairs(items) do
          dbg("Checking against", original_item.text)
          if original_item.text == v._select_key then
            item = original_item
            dbg("Found matching item", item)
            break
          end
        end
      else
        -- Fallback: treat v as index into items array
        item = type(v) == "table" and v or items[v]
        dbg("Using fallback item", item)
      end

      if item and item.msg_idx and item.msg_idx > cut then cut = item.msg_idx end
    end
    dbg("confirm ‑ cut", cut)
    if cut == 0 then return end

    local kept = build_kept(messages, cut)

    -- Get the current cycle from the chat object
    local current_cycle = chat.cycle or 1
    ensure_trailing_empty(messages, kept, current_cycle)

    apply(chat, kept)
    picker:close()
  end

  require("snacks").picker({
    title   = "Remove Chat Messages",
    items   = items,
    format  = function(it) return { { it.label } } end,
    confirm = confirm,
  })
end

-- quick variant ----------------------------------------------------------------
local function remove_last_user(chat)
  local messages, cut = chat.messages or {}, 0
  for i = #messages, 1, -1 do
    local msg = messages[i]
    if msg.role == "user" and (msg.content or "") ~= "" then
      cut = i; break
    end
  end
  if cut == 0 then
    vim.notify("No user messages to remove.", vim.log.levels.WARN)
    return
  end
  dbg("remove_last_user - cut", cut)
  local kept = build_kept(messages, cut)

  -- Get the current cycle from the chat object
  local current_cycle = chat.cycle or 1
  ensure_trailing_empty(messages, kept, current_cycle)

  apply(chat, kept)
end

-- keymap registration ----------------------------------------------------------
local function register_strategy_keymaps(key_picker, key_quick)
  local chat_keymaps = require("codecompanion.config").strategies.chat.keymaps

  chat_keymaps.remove_messages_picker = {
    modes       = { n = key_picker },
    description = "Remove chat messages (picker)",
    callback    = function()
      local buf  = vim.api.nvim_get_current_buf()
      local chat = require("codecompanion.strategies.chat").buf_get_chat(buf)
      if chat then remove_chat_messages(chat) end
    end,
  }

  chat_keymaps.remove_last_user = {
    modes       = { n = key_quick },
    description = "Remove last user message",
    callback    = function()
      local buf  = vim.api.nvim_get_current_buf()
      local chat = require("codecompanion.strategies.chat").buf_get_chat(buf)
      if chat then remove_last_user(chat) end
    end,
  }
end

-- public API -------------------------------------------------------------------
---@param opts? { keymap_picker?: string, keymap_quick?: string }
local function setup(opts)
  register_strategy_keymaps(opts and opts.keymap_picker or "gE",
    opts and opts.keymap_quick or "gO")
end

return {
  setup   = setup,
  exports = {
    remove_chat_messages = remove_chat_messages,
    remove_last_user     = remove_last_user,
  },
}

