---Execute file on a tmux pane on the right.
---@param config custom.RubyExecutionConfig the configuration to use for executing ruby file
local function execute_file(config)
  local filename = vim.fn.expand("%:.")
  if string.match(filename, "%.rb$") then
    local command_to_run = config.cmd .. " " .. filename

    if config.include_line_number then
      command_to_run = command_to_run .. ":" .. vim.fn.line(".")
    end

    local bash_additional_flags = ""
    if config.is_interactive then
      bash_additional_flags = "-i "
    end

    -- `-l 20` specifies the size of the tmux pane, in this case 20 rows
    vim.cmd(
      "silent !tmux split-window -v -l 20 '"
        .. "bash "
        .. bash_additional_flags
        .. '-c "'
        .. command_to_run
        .. "; echo; echo Press any key to exit...; read -n 1; exit\"'"
    )
  else
    vim.notify("Not a Ruby file.", vim.log.levels.WARN)
  end
end

local M = {}
M.execute_file = execute_file
return M
