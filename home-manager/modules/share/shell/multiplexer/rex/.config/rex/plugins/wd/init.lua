local terminal = "com.superlogical.terminal"

local script = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("init%.lua$", "wd.zsh")

---Opens a new layer with the wd picker if the current block is a zsh shell.
---@param ctx table The context of the action.
local function open_wd(ctx)
  local process = assert(rex.block.call(terminal, "process", { block_id = ctx.block_id }))
  -- Do not send shell commands to an editor or another running program.
  if not process.foreground or process.foreground.name ~= "zsh" then
    return false
  end

  local description = assert(rex.session.describe_block({
    session_id = ctx.session_id,
    block_id = ctx.block_id,
  }))
  -- Rex can report zsh as the picker foreground process.
  if description.block.label == "wd" then
    return false
  end

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
    bounds = { 0.25, 0, 0.5, 0.5 },
    focus = true,
    layout = rex.layout.block({
      flavor = "com.superlogical.terminal.shell",
      label = "wd",
      options = {
        shell = "none",
        command = {
          "zsh",
          "-i",
          script,
          ctx.session_id,
          ctx.block_id,
          description.block.window_id,
          zoomed_block_id,
        },
      },
    }),
  }))
end

rex.action({ name = "open_wd", title = "Select wd Workspace", run = open_wd })

rex.bind("ctrl+q>alt+e", "open_wd")
