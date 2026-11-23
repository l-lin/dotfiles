local directory = os.getenv("HOME") .. "/.cache/rex/nvim/"

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
              -- The editor must finish its split change before Rex can select another pane.
              local expression = 'luaeval("(function() local window = vim.api.nvim_get_current_win(); '
                  .. "vim.cmd.wincmd('" .. key .. "'); "
                  .. 'return vim.api.nvim_get_current_win() ~= window and 1 or 0 end)()")'
              local result = rex.exec({
                  foreground.invoked_path or foreground.path or "nvim",
                  "--server", directory .. ctx.block_id:gsub("^block:", "") .. ".sock",
                  "--remote-expr", expression,
              }, { timeout = 1 })
              if not result or result.code ~= 0 then
                  rex.log("warn", "Neovim navigation failed. Restart Neovim to load config.rex.")
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
