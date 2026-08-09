local parser = require("functions.lang.mermaid.parser")
local flowchart = require("functions.lang.mermaid.flowchart")
local sequence = require("functions.lang.mermaid.sequence")
local state_renderer = require("functions.lang.mermaid.state")

local state = {
  preview_enabled = true,
  debug_enabled = false,
  setup_done = false,
  notified_failures = {},
}

local function find_mermaid_blocks(markdown_lines)
  return parser.find_mermaid_blocks(markdown_lines)
end

local function render(source)
  local kind = parser.diagram_kind(source)
  if kind == "flowchart" then
    return flowchart.render(source)
  end
  if kind == "sequence" then
    return sequence.render(source)
  end
  if kind == "state" then
    return state_renderer.render(source)
  end

  return nil, "unsupported diagram kind: " .. tostring(kind or "unknown")
end

local function preview_text(block, line)
  return {
    { block.indent .. line, "Normal" },
  }
end

local function preview_virt_lines(block, preview_lines)
  local virt_lines = {}
  for _, line in ipairs(preview_lines) do
    virt_lines[#virt_lines + 1] = preview_text(block, line)
  end
  return virt_lines
end

local function maybe_notify_failure(bufnr, block, reason)
  if not state.debug_enabled then
    return
  end

  local failure_key = table.concat({ block.start_row, block.end_row, block.source, reason }, ":")
  local block_key = table.concat({ bufnr, block.start_row, block.end_row }, ":")
  if state.notified_failures[block_key] == failure_key then
    return
  end

  state.notified_failures[block_key] = failure_key
  vim.notify(
    string.format("Mermaid ASCII preview fallback at lines %d-%d: %s", block.start_row + 1, block.end_row + 1, reason),
    vim.log.levels.WARN
  )
end

local function build_marks(markdown_lines, options)
  local marks = {}
  local on_error = options and options.on_error or nil
  local last_row = #markdown_lines - 1

  for _, block in ipairs(find_mermaid_blocks(markdown_lines)) do
    local preview_lines, reason = render(block.source)
    if preview_lines and #preview_lines > 0 then
      local mark = {
        conceal = false,
        start_row = block.end_row,
        start_col = 0,
        opts = {
          virt_lines = preview_virt_lines(block, preview_lines),
        },
      }

      if block.end_row < last_row then
        mark.start_row = block.end_row + 1
        mark.opts.virt_lines_above = true
      end

      marks[#marks + 1] = mark
    elseif on_error then
      on_error(block, reason or "unknown render failure")
    end
  end

  return marks
end

local function parse(ctx)
  if not state.preview_enabled or not ctx.last then
    return {}
  end

  local markdown_lines = vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)
  return build_marks(markdown_lines, {
    on_error = function(block, reason)
      maybe_notify_failure(ctx.buf, block, reason)
    end,
  })
end

local function refresh_markdown_buffers(event_name)
  local ok_render_markdown, render_markdown = pcall(require, "render-markdown")
  local ok_state, render_state = pcall(require, "render-markdown.state")
  if not (ok_render_markdown and ok_state) then
    return
  end

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == "markdown" then
      local config = render_state.get(bufnr)
      if config.enabled then
        render_markdown.render({ buf = bufnr, event = event_name })
      end
    end
  end
end

local function toggle()
  state.preview_enabled = not state.preview_enabled
  refresh_markdown_buffers("MermaidAsciiToggle")
  vim.notify("Mermaid ASCII preview " .. (state.preview_enabled and "enabled" or "disabled"))
end

local function toggle_debug()
  state.debug_enabled = not state.debug_enabled
  state.notified_failures = {}
  refresh_markdown_buffers("MermaidAsciiDebugToggle")
  vim.notify("Mermaid ASCII debug " .. (state.debug_enabled and "enabled" or "disabled"))
end

local function setup()
  if state.setup_done then
    return
  end

  state.setup_done = true
  local group = vim.api.nvim_create_augroup("MermaidAscii", { clear = true })

  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    callback = function()
      vim.schedule(function()
        refresh_markdown_buffers("MermaidAsciiModeChanged")
      end)
    end,
  })

  vim.api.nvim_create_user_command("MermaidAsciiToggle", toggle, { desc = "Toggle Mermaid ASCII preview" })
  vim.api.nvim_create_user_command("MermaidAsciiDebugToggle", toggle_debug, { desc = "Toggle Mermaid ASCII debug notifications" })
end

local M = {}
M.find_mermaid_blocks = find_mermaid_blocks
M.render = render
M.build_marks = build_marks
M.parse = parse
M.toggle = toggle
M.toggle_debug = toggle_debug
M.setup = setup
return M
