local script = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("init%.lua$", "navi.zsh")

local function open_navi(ctx)
  local session_id, block_id = ctx.session_id, ctx.block_id
  local description = rex.session.describe_block({ session_id = session_id, block_id = block_id })
  if not description or description.block.label == "navi" then
    return false
  end

  local process = rex.block.call("com.superlogical.terminal", "process", { block_id = block_id })
  if not process then
    return false
  end
  local cwd = process.foreground and process.foreground.cwd
    or process.ancestors and process.ancestors[1] and process.ancestors[1].cwd
    or process.child and process.child.cwd
    or process.home

  local window_id = description.block.window_id
  local zoomed_block_id = ""
  local view = assert(rex.session.view({ session_id = session_id }))
  for _, window in ipairs(view.windows or {}) do
    if window.window_id == window_id then
      zoomed_block_id = window.zoomed_block_id or ""
      break
    end
  end

  return assert(rex.session.new_layer({
    session_id = session_id,
    window_id = window_id,
    bounds = { 0.05, 0.05, 0.9, 0.9 },
    focus = true,
    layout = rex.layout.block({
      flavor = "com.superlogical.terminal.shell",
      label = "navi",
      options = {
        cwd = cwd,
        shell = "none",
        command = { "zsh", "-i", script, session_id, block_id, zoomed_block_id },
      },
    }),
  }))
end

rex.action({ name = "open_navi", title = "Select Navi Snippet", run = open_navi })
rex.bind("ctrl+q>ctrl+f", "open_navi")
