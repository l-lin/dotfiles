--
-- Extrakto plugin for Rex, a terminal multiplexer.
-- This plugin allows users to grab a word from the terminal and open it in a new layer for further processing.
-- Inspired from: https://github.com/laktak/extrakto
--

local terminal = "com.superlogical.terminal"
local script = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("init%.lua$", "extrakto.zsh")

local function open_extrakto(ctx)
  local description = assert(rex.session.describe_block({
    session_id = ctx.session_id,
    block_id = ctx.block_id,
  }))
  local block = description.block
  if block.creator_name ~= terminal or block.label == "extrakto" then
    return false
  end

  local view = assert(rex.session.view({ session_id = ctx.session_id }))
  for _, window in ipairs(view.windows or {}) do
    if window.window_id == block.window_id then
      local command = { "zsh", script, ctx.session_id, ctx.block_id, window.zoomed_block_id or "" }
      for _, layer in ipairs(window.layers or {}) do
        if layer.kind == "tiled" then
          for _, pane in ipairs(layer.blocks or {}) do
            if pane.creator_name == terminal and pane.block_id ~= ctx.block_id then
              command[#command + 1] = pane.block_id
            end
          end
        end
      end

      return assert(rex.session.new_layer({
        session_id = ctx.session_id,
        window_id = window.window_id,
        bounds = { 0.25, 0, 0.5, 0.5 },
        focus = true,
        layout = rex.layout.block({
          flavor = "com.superlogical.terminal.shell",
          label = "extrakto",
          options = { shell = "none", command = command },
        }),
      }))
    end
  end
  return false
end

rex.action({ name = "open_extrakto", title = "Grab a Word", run = open_extrakto })
rex.bind("ctrl+q>tab", "open_extrakto")
