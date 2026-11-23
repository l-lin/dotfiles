local terminal = "com.superlogical.terminal"

local script = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("init%.lua$", "fzf.zsh")

---Opens a new layer with the fzf picker if the current block is not a full-screen program.
---@param ctx table The context of the action.
local function open_fzf(ctx)
  local description = assert(rex.session.describe_block({
    session_id = ctx.session_id,
    block_id = ctx.block_id,
  }))
  -- Let fzf receive Ctrl-G instead of opening another picker.
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
        command = { "zsh", "-i", script, ctx.session_id, ctx.block_id, zoomed_block_id },
      },
    }),
  }))
end

rex.action({ name = "open_fzf", title = "Find Files", run = open_fzf })
rex.bind("ctrl+q>ctrl+g", "open_fzf")
