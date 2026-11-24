--
-- Neovim navigation plugin for Rex. This plugin allows you to navigate between Neovim splits and Rex panes using the same keybindings.
--

local nvim_cache_directory = os.getenv("HOME") .. "/.cache/rex/nvim/"

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  -- Ensure ctrl+alt+{h,j,k,l} works in copy mode, even if the pane is running Neovim.
  rex.bind("copy/ctrl+alt+" .. key, "pane.focus." .. direction)

  rex.bind("ctrl+alt+" .. key, function(ctx)
    local process = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
    if not process or not process.foreground then
      return false
    end

    -- Make sure the pane is running Neovim before sending a remote command to it.
    -- Simulate vim-tmux-navigation behavior.
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
