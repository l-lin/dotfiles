local parser = require("functions.lang.mermaid.parser")
local sequence = require("functions.lang.mermaid.sequence")
local flowchart_renderer = require("functions.lang.mermaid.flowchart.renderer")
local state_renderer = require("functions.lang.mermaid.state.renderer")

local state = {
  setup_done = false,
  popup = nil,
  source_activity_namespace = nil,
}

local function find_mermaid_blocks(markdown_lines)
  return parser.find_mermaid_blocks(markdown_lines)
end

local function render(source)
  local kind = parser.diagram_kind(source)
  if kind == "flowchart" then
    return flowchart_renderer.render(source)
  end
  if kind == "sequence" then
    return sequence.render(source)
  end
  if kind == "state" then
    return state_renderer.render(source)
  end

  return nil, "unsupported diagram kind: " .. tostring(kind or "unknown")
end

local function find_mermaid_block_at_row(markdown_lines, cursor_row)
  for _, block in ipairs(find_mermaid_blocks(markdown_lines)) do
    if cursor_row >= block.start_row and cursor_row <= block.end_row then
      return block
    end
  end

  return nil, "cursor is not inside a Mermaid block"
end

local function preview_lines_at_row(markdown_lines, cursor_row)
  local block, reason = find_mermaid_block_at_row(markdown_lines, cursor_row)
  if not block then
    return nil, reason
  end

  return render(block.source)
end

local function build_popup_request_at_row(markdown_lines, cursor_row, source_bufnr, source_winid)
  local block, reason = find_mermaid_block_at_row(markdown_lines, cursor_row)
  if not block then
    return nil, reason
  end

  local preview_lines, render_reason = render(block.source)
  if not preview_lines or #preview_lines == 0 then
    return nil, render_reason or "nothing to render"
  end

  return {
    source_bufnr = source_bufnr,
    source_winid = source_winid,
    source_row = cursor_row,
    block_start_row = block.start_row,
    block_end_row = block.end_row,
    preview_lines = preview_lines,
    preview_text = table.concat(preview_lines, "\n"),
  }
end

local function determine_popup_action(active_popup, request)
  if not request then
    return "none"
  end
  if not active_popup then
    return "open"
  end
  if active_popup.source_bufnr ~= request.source_bufnr then
    return "replace"
  end
  if active_popup.block_start_row ~= request.block_start_row or active_popup.block_end_row ~= request.block_end_row then
    return "replace"
  end
  if active_popup.preview_text ~= request.preview_text then
    return "replace"
  end

  return "focus"
end

local function determine_markdown_k_action(active_popup, request, reason)
  if not request then
    if reason == "cursor is not inside a Mermaid block" then
      return "fallback"
    end

    return "warn"
  end

  return determine_popup_action(active_popup, request)
end

local function popup_is_valid(popup)
  return popup
    and popup.bufnr
    and popup.winid
    and vim.api.nvim_buf_is_valid(popup.bufnr)
    and vim.api.nvim_win_is_valid(popup.winid)
end

local function ensure_source_activity_namespace()
  if not state.source_activity_namespace then
    state.source_activity_namespace = vim.api.nvim_create_namespace("MermaidAsciiPopupSourceActivity")
  end

  return state.source_activity_namespace
end

local function resolve_source_key(key, typed_key)
  return typed_key or key
end

local function should_close_popup_for_source_key(key)
  return key ~= "K"
end

local function should_close_popup_for_source_context(active_popup, context)
  if not active_popup then
    return false
  end
  if context.current_winid == active_popup.winid then
    return false
  end
  if context.current_winid ~= active_popup.source_winid then
    return true
  end
  if context.current_bufnr and context.current_bufnr ~= active_popup.source_bufnr then
    return true
  end
  if context.current_mode and context.current_mode ~= "n" then
    return true
  end
  if context.cursor_row and context.cursor_row ~= active_popup.source_row then
    return true
  end

  return false
end

local function note_source_to_popup_focus_check(active_popup)
  if not active_popup or not active_popup.allow_source_to_popup_focus then
    return 0
  end

  active_popup.pending_source_to_popup_checks = (active_popup.pending_source_to_popup_checks or 0) + 1
  return active_popup.pending_source_to_popup_checks
end

local function consume_source_to_popup_focus_check(active_popup)
  if not active_popup then
    return 0
  end

  local pending_checks = active_popup.pending_source_to_popup_checks or 0
  if pending_checks <= 0 then
    active_popup.pending_source_to_popup_checks = 0
    active_popup.allow_source_to_popup_focus = false
    return 0
  end

  active_popup.pending_source_to_popup_checks = pending_checks - 1
  if active_popup.pending_source_to_popup_checks == 0 then
    active_popup.allow_source_to_popup_focus = false
  end

  return active_popup.pending_source_to_popup_checks
end

local function should_close_popup_for_source_window_change(active_popup, current_winid)
  if not active_popup or current_winid ~= active_popup.winid then
    return false
  end

  return (active_popup.pending_source_to_popup_checks or 0) == 0
end

local function teardown_source_activity_tracking(popup)
  if not popup then
    return
  end

  if popup.source_activity_group_id then
    pcall(vim.api.nvim_del_augroup_by_id, popup.source_activity_group_id)
  end

  vim.on_key(nil, ensure_source_activity_namespace())
end

local function clear_popup_state()
  teardown_source_activity_tracking(state.popup)
  state.popup = nil
end

local function close_popup(options)
  local popup = state.popup
  if not popup then
    return
  end

  local source_winid = popup.source_winid
  if popup.winid and vim.api.nvim_win_is_valid(popup.winid) then
    pcall(vim.api.nvim_win_close, popup.winid, true)
  elseif popup.bufnr and vim.api.nvim_buf_is_valid(popup.bufnr) then
    pcall(vim.api.nvim_buf_delete, popup.bufnr, { force = true })
  end

  clear_popup_state()

  if options and options.focus_source and source_winid and vim.api.nvim_win_is_valid(source_winid) then
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(source_winid) then
        vim.api.nvim_set_current_win(source_winid)
      end
    end)
  end
end

local function close_popup_and_focus_source()
  close_popup({ focus_source = true })
end

local function focus_source_window()
  local popup = state.popup
  if popup and popup.source_winid and vim.api.nvim_win_is_valid(popup.source_winid) then
    vim.api.nvim_set_current_win(popup.source_winid)
    return
  end

  vim.notify("Mermaid ASCII source window is no longer available", vim.log.levels.WARN)
end

local function maybe_close_popup_for_source_context(extra_context)
  local popup = state.popup
  if not popup then
    return
  end
  if not popup_is_valid(popup) then
    clear_popup_state()
    return
  end
  if not popup.source_bufnr or not vim.api.nvim_buf_is_valid(popup.source_bufnr) then
    close_popup()
    return
  end
  if not popup.source_winid or not vim.api.nvim_win_is_valid(popup.source_winid) then
    close_popup()
    return
  end

  local context = {
    current_winid = vim.api.nvim_get_current_win(),
    current_bufnr = vim.api.nvim_get_current_buf(),
  }

  if extra_context then
    for key, value in pairs(extra_context) do
      context[key] = value
    end
  end

  if should_close_popup_for_source_context(popup, context) then
    close_popup()
  end
end

local function schedule_source_context_check()
  vim.schedule(function()
    local popup = state.popup
    if not popup then
      return
    end
    if not popup_is_valid(popup) then
      clear_popup_state()
      return
    end

    local current_winid = vim.api.nvim_get_current_win()
    if current_winid == popup.winid then
      if should_close_popup_for_source_window_change(popup, current_winid) then
        close_popup()
        return
      end

      consume_source_to_popup_focus_check(popup)
      return
    end

    maybe_close_popup_for_source_context()
  end)
end

local function register_source_activity_tracking()
  local popup = state.popup
  if not popup then
    return
  end

  local group_id = vim.api.nvim_create_augroup("MermaidAsciiPopupSourceActivity" .. popup.bufnr, { clear = true })
  popup.source_activity_group_id = group_id

  vim.on_key(function(key, typed_key)
    local active_popup = state.popup
    if not active_popup then
      return
    end
    if not popup_is_valid(active_popup) then
      clear_popup_state()
      return
    end
    if not active_popup.source_winid or not vim.api.nvim_win_is_valid(active_popup.source_winid) then
      close_popup()
      return
    end
    if vim.api.nvim_get_current_win() ~= active_popup.source_winid then
      return
    end

    local actual_key = resolve_source_key(key, typed_key)
    if not should_close_popup_for_source_key(actual_key) then
      return
    end

    close_popup()
  end, ensure_source_activity_namespace())

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group_id,
    buffer = popup.source_bufnr,
    callback = function()
      local active_popup = state.popup
      if not active_popup or vim.api.nvim_get_current_win() ~= active_popup.source_winid then
        return
      end

      maybe_close_popup_for_source_context({
        current_mode = vim.api.nvim_get_mode().mode:sub(1, 1),
        cursor_row = vim.api.nvim_win_get_cursor(active_popup.source_winid)[1] - 1,
      })
    end,
  })

  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group_id,
    callback = function()
      local active_popup = state.popup
      if not active_popup or vim.api.nvim_get_current_win() ~= active_popup.source_winid then
        return
      end

      maybe_close_popup_for_source_context({
        current_mode = vim.api.nvim_get_mode().mode:sub(1, 1),
      })
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = group_id,
    buffer = popup.source_bufnr,
    callback = function()
      local active_popup = state.popup
      if not active_popup or vim.api.nvim_get_current_win() ~= active_popup.source_winid then
        return
      end

      note_source_to_popup_focus_check(active_popup)
      schedule_source_context_check()
    end,
  })

  vim.api.nvim_create_autocmd("WinLeave", {
    group = group_id,
    callback = function()
      local active_popup = state.popup
      if not active_popup or vim.api.nvim_get_current_win() ~= active_popup.source_winid then
        return
      end

      note_source_to_popup_focus_check(active_popup)
      schedule_source_context_check()
    end,
  })

  vim.api.nvim_create_autocmd("TabLeave", {
    group = group_id,
    callback = function()
      local active_popup = state.popup
      if not active_popup or vim.api.nvim_get_current_win() ~= active_popup.source_winid then
        return
      end

      note_source_to_popup_focus_check(active_popup)
      schedule_source_context_check()
    end,
  })

  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = group_id,
    buffer = popup.source_bufnr,
    callback = close_popup,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = group_id,
    callback = function(args)
      local active_popup = state.popup
      if not active_popup then
        return
      end
      if tonumber(args.match) ~= active_popup.source_winid then
        return
      end

      close_popup()
    end,
  })
end

local function popup_dimensions(preview_lines)
  local ui = vim.api.nvim_list_uis()[1] or { width = vim.o.columns, height = vim.o.lines }
  local width = 1
  for _, line in ipairs(preview_lines) do
    width = math.max(width, vim.api.nvim_strwidth(line))
  end

  local max_width = math.max(20, ui.width - 6)
  local max_height = math.max(4, ui.height - 6)
  local clamped_width = math.min(width, max_width)
  local clamped_height = math.min(math.max(#preview_lines, 1), max_height)

  return {
    width = clamped_width,
    height = clamped_height,
    row = math.max(1, math.floor((ui.height - clamped_height) / 2) - 1),
    col = math.max(1, math.floor((ui.width - clamped_width) / 2)),
  }
end

local function open_popup(request)
  local dimensions = popup_dimensions(request.preview_lines)
  local bufnr = vim.api.nvim_create_buf(false, true)

  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].modifiable = true
  vim.bo[bufnr].filetype = "text"

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, request.preview_lines)
  vim.bo[bufnr].modifiable = false

  local winid = vim.api.nvim_open_win(bufnr, false, {
    relative = "editor",
    width = dimensions.width,
    height = dimensions.height,
    row = dimensions.row,
    col = dimensions.col,
    style = "minimal",
    border = "rounded",
    focusable = true,
    zindex = 150,
  })

  vim.wo[winid].wrap = false
  vim.wo[winid].number = false
  vim.wo[winid].relativenumber = false
  vim.wo[winid].signcolumn = "no"

  state.popup = {
    bufnr = bufnr,
    winid = winid,
    source_bufnr = request.source_bufnr,
    source_winid = request.source_winid,
    source_row = request.source_row,
    allow_source_to_popup_focus = false,
    pending_source_to_popup_checks = 0,
    block_start_row = request.block_start_row,
    block_end_row = request.block_end_row,
    preview_text = request.preview_text,
  }

  register_source_activity_tracking()

  local popup_keymap_opts = { buffer = bufnr, silent = true, noremap = true }
  vim.keymap.set("n", "q", close_popup_and_focus_source, popup_keymap_opts)

  local captured_winid = winid
  vim.api.nvim_create_autocmd("WinClosed", {
    once = true,
    callback = function(args)
      if tonumber(args.match) ~= captured_winid then
        return
      end
      if state.popup and state.popup.winid == captured_winid then
        clear_popup_state()
      end
    end,
  })
end

local function active_popup_for_action()
  if not popup_is_valid(state.popup) then
    clear_popup_state()
    return nil
  end

  return {
    source_bufnr = state.popup.source_bufnr,
    block_start_row = state.popup.block_start_row,
    block_end_row = state.popup.block_end_row,
    preview_text = state.popup.preview_text,
  }
end

local function show_popup_for_request(request)
  local action = determine_popup_action(active_popup_for_action(), request)
  if action == "focus" then
    state.popup.source_winid = request.source_winid
    state.popup.source_row = request.source_row
    state.popup.allow_source_to_popup_focus = true

    local popup_winid = state.popup.winid
    vim.schedule(function()
      if not state.popup or state.popup.winid ~= popup_winid or not popup_is_valid(state.popup) then
        return
      end

      vim.api.nvim_set_current_win(popup_winid)
    end)
    return
  end

  if action == "replace" then
    close_popup()
  end

  open_popup(request)
end

local function toggle_popup()
  if popup_is_valid(state.popup) and vim.api.nvim_get_current_win() == state.popup.winid then
    focus_source_window()
    return
  end

  local source_bufnr = vim.api.nvim_get_current_buf()
  local source_winid = vim.api.nvim_get_current_win()
  local markdown_lines = vim.api.nvim_buf_get_lines(source_bufnr, 0, -1, false)
  local cursor_row = vim.api.nvim_win_get_cursor(source_winid)[1] - 1
  local request, reason = build_popup_request_at_row(markdown_lines, cursor_row, source_bufnr, source_winid)
  if not request then
    vim.notify("Mermaid ASCII preview unavailable: " .. (reason or "nothing to render"), vim.log.levels.WARN)
    return
  end

  show_popup_for_request(request)
end

local function handle_markdown_k()
  local source_bufnr = vim.api.nvim_get_current_buf()
  local source_winid = vim.api.nvim_get_current_win()
  local markdown_lines = vim.api.nvim_buf_get_lines(source_bufnr, 0, -1, false)
  local cursor_row = vim.api.nvim_win_get_cursor(source_winid)[1] - 1
  local request, reason = build_popup_request_at_row(markdown_lines, cursor_row, source_bufnr, source_winid)
  local action = determine_markdown_k_action(active_popup_for_action(), request, reason)

  if action == "fallback" then
    vim.cmd.normal({ args = { "K" }, bang = true })
    return
  end
  if action == "warn" then
    vim.notify("Mermaid ASCII preview unavailable: " .. (reason or "nothing to render"), vim.log.levels.WARN)
    return
  end

  show_popup_for_request(request)
end

local function setup()
  if state.setup_done then
    return
  end

  state.setup_done = true
  vim.api.nvim_create_user_command("MermaidAsciiPreview", toggle_popup, {
    desc = "Open or focus a Mermaid ASCII popup for the current block",
  })
end

local M = {}
M.find_mermaid_blocks = find_mermaid_blocks
M.render = render
M.preview_lines_at_row = preview_lines_at_row
M.build_popup_request_at_row = build_popup_request_at_row
M.determine_popup_action = determine_popup_action
M.determine_markdown_k_action = determine_markdown_k_action
M.resolve_source_key = resolve_source_key
M.should_close_popup_for_source_key = should_close_popup_for_source_key
M.should_close_popup_for_source_context = should_close_popup_for_source_context
M.note_source_to_popup_focus_check = note_source_to_popup_focus_check
M.consume_source_to_popup_focus_check = consume_source_to_popup_focus_check
M.should_close_popup_for_source_window_change = should_close_popup_for_source_window_change
M.handle_markdown_k = handle_markdown_k
M.toggle_popup = toggle_popup
M.close_popup = close_popup
M.setup = setup
return M
