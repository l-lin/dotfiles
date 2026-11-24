--
-- Prefix and configuration
--
rex.bind("ctrl+q>r", "client.config.reload")

--
-- Font size
--
rex.bind("ctrl+shift+=", "client.font.increase")
rex.bind("ctrl+shift+-", "client.font.decrease")
rex.bind("ctrl+shift+0", "client.font.reset")

--
-- Sidebar
--
rex.bind("cmd+s", "client.sidebar.toggle")

--
-- Copy mode
--
---Yank the selected text/line and unselect immediately, without exiting copy mode.
local function yank_and_unselect()
  rex.client.queue("pane.copy")
  -- Different modes ensure a selection exists before the final toggle clears it.
  rex.client.queue("pane.copy_mode.select", { mode = "char" })
  rex.client.queue("pane.copy_mode.select", { mode = "line" })
  rex.client.queue("pane.copy_mode.select", { mode = "line" })
end
rex.action({
  name = "copy_and_unselect",
  title = "Copy and clear selection",
  run = yank_and_unselect,
})
rex.bind("ctrl+q>b", "pane.copy_mode.enter")
rex.bind("copy/y", "copy_and_unselect")
rex.bind("ctrl+shift+c", "pane.copy")
rex.bind("ctrl+shift+v", "pane.paste")

--
-- Panes
--
local nvim_cache_directory = os.getenv("HOME") .. "/.cache/rex/nvim/"
local function add_pane_navigation()
  -- Simulate vim-tmux-navigation behavior.
  for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
    rex.bind("ctrl+alt+" .. key, function(ctx)
      local process = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
      if not process or not process.foreground then
        return false
      end

      local foreground = process.foreground
      if foreground.name == "nvim" or foreground.name == ".nvim-wrapped" then
        if not foreground.pid then
          return false
        end

        local block = ctx.block_id:gsub("^block:", "")
        local socket = ("%s%s-%d.sock"):format(nvim_cache_directory, block, foreground.pid)
        -- The editor must finish its split change before Rex can select another pane.
        local expression = 'luaeval("(function() local window = vim.api.nvim_get_current_win(); '
          .. "vim.cmd.wincmd('"
          .. key
          .. "'); "
          .. 'return vim.api.nvim_get_current_win() ~= window and 1 or 0 end)()")'
        local result = rex.exec({
          foreground.invoked_path or foreground.path or "nvim",
          "--server",
          socket,
          "--remote-expr",
          expression,
        }, { timeout = 1 })
        if not result or result.code ~= 0 then
          rex.log("warn", "Neovim navigation failed. Restart Neovim to load the Rex integration.")
          return false
        end
        if result.stdout:match("^%s*1%s*$") then
          return true
        end
        if not result.stdout:match("^%s*0%s*$") then
          return false
        end
      end

      return rex.session.focus_direction({ session_id = ctx.session_id, direction = direction, wrap = false }) ~= nil
    end)
  end
end

-- Pane layout
rex.bind("ctrl+q>v", "pane.split", { direction = "right" })
rex.bind("ctrl+q>s", "pane.split", { direction = "down" })
rex.bind("ctrl+q>shift+5", "pane.split", { direction = "right" })
rex.bind("ctrl+q>shift+'", "pane.split", { direction = "down" })
rex.bind("ctrl+q>shift+1", "pane.move_to_new_tab")
rex.bind("ctrl+q>x", "pane.close")
rex.bind("ctrl+q>z", "pane.zoom")
rex.bind("ctrl+q>ctrl+left", "pane.resize", { direction = "left" })
rex.bind("ctrl+q>ctrl+down", "pane.resize", { direction = "down" })
rex.bind("ctrl+q>ctrl+up", "pane.resize", { direction = "up" })
rex.bind("ctrl+q>ctrl+right", "pane.resize", { direction = "right" })
rex.bind("ctrl+q>shift+[", "pane.move.left")
rex.bind("ctrl+q>shift+]", "pane.move.right")
rex.bind("ctrl+q>alt+1", "pane.balance")

-- Pane focus
rex.bind("ctrl+q>left", "pane.focus.left")
rex.bind("ctrl+q>down", "pane.focus.down")
rex.bind("ctrl+q>up", "pane.focus.up")
rex.bind("ctrl+q>right", "pane.focus.right")
rex.bind("ctrl+q>o", "pane.focus_next")
rex.bind("ctrl+q>;", "pane.focus_back.in_tab") -- ko
rex.bind("ctrl+q>w", "pane.go_to")
add_pane_navigation()

--
-- Sessions
--
rex.bind("ctrl+q>shift+9", "session.previous")
rex.bind("ctrl+q>shift+0", "session.next")
rex.bind("ctrl+q>shift+l", "session.back") -- ko
rex.bind("ctrl+q>shift+4", "session.rename") -- c-$

--
-- Tabs
--
rex.bind("ctrl+q>c", "client.tab.new")
rex.bind("ctrl+q>n", "client.tab.next")
rex.bind("ctrl+q>p", "client.tab.previous")
rex.bind("ctrl+q>l", "client.tab.back.in_session") -- ko
rex.bind("ctrl+q>,", "client.tab.rename")
rex.bind("ctrl+q>1", "client.tab.goto", { index = 1 })
rex.bind("ctrl+q>2", "client.tab.goto", { index = 2 })
rex.bind("ctrl+q>3", "client.tab.goto", { index = 3 })
rex.bind("ctrl+q>4", "client.tab.goto", { index = 4 })
rex.bind("ctrl+q>5", "client.tab.goto", { index = 5 })
rex.bind("ctrl+q>6", "client.tab.goto", { index = 6 })
rex.bind("ctrl+q>7", "client.tab.goto", { index = 7 })
rex.bind("ctrl+q>8", "client.tab.goto", { index = 8 })
rex.bind("ctrl+q>9", "client.tab.goto", { index = 9 })
