--
-- Opens a new terminal block with fzf-url in the current window, if the current block is not a terminal or fzf-url.
-- Inspired from: https://github.com/wfxr/tmux-fzf-url
--

local terminal = "com.superlogical.terminal"
local script = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("init%.lua$", "fzf-url.zsh")

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
      local command = { "zsh", "-i", script, ctx.session_id, ctx.block_id, window.zoomed_block_id or "" }
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
