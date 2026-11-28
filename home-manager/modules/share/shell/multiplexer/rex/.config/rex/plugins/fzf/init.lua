local terminal = "com.superlogical.terminal"

local script = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("init%.lua$", "fzf.zsh")

---@param ctx table The context of the action.
---@param mode 'files' | 'grep' | 'cd'
local function open_fzf(ctx, mode)
  local description = assert(rex.session.describe_block({
    session_id = ctx.session_id,
    block_id = ctx.block_id,
  }))
  -- Do not open a picker inside another picker.
  if description.block.label == "fzf" then
    return false
  end

  local process = assert(rex.block.call(terminal, "process", { block_id = ctx.block_id }))
  local cwd = process.foreground and process.foreground.cwd
    or process.ancestors and process.ancestors[1] and process.ancestors[1].cwd
    or process.child and process.child.cwd
    or process.home

  local view = assert(rex.session.view({ session_id = ctx.session_id }))
  local zoomed_block_id = ""
  for _, window in ipairs(view.windows or {}) do
    if window.window_id == description.block.window_id then
      zoomed_block_id = window.zoomed_block_id or ""
      break
    end
  end

  return assert(rex.session.new_layer({
    session_id = ctx.session_id,
    window_id = description.block.window_id,
    bounds = { 0.05, 0.05, 0.9, 0.9 },
    focus = true,
    layout = rex.layout.block({
      flavor = "com.superlogical.terminal.shell",
      label = "fzf",
      options = {
        cwd = cwd,
        shell = "none",
        command = { "zsh", script, ctx.session_id, ctx.block_id, zoomed_block_id, mode },
      },
    }),
  }))
end

rex.action({
  name = "open_fzf",
  title = "Find Files",
  run = function(ctx)
    return open_fzf(ctx, "files")
  end,
})
rex.action({
  name = "open_fzf_grep",
  title = "Search File Contents",
  run = function(ctx)
    return open_fzf(ctx, "grep")
  end,
})
rex.action({
  name = "open_fzf_cd",
  title = "cd into the selected directory",
  run = function(ctx)
    return open_fzf(ctx, "cd")
  end
})
rex.bind("ctrl+q>ctrl+g", "open_fzf")
rex.bind("ctrl+q>alt+g", "open_fzf_grep")
rex.bind("ctrl+q>alt+c", "open_fzf_cd")
