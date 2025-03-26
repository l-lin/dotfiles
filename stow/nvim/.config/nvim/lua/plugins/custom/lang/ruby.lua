---@class custom.RubyExecutionConfig
---@field cmd string the command to run
---@field use_interactive_shell boolean true to run the command in interactive shell
---@field include_line_number boolean true to include the current line number in the command to run

---Execute file on a new tmux pane below.
---@param config custom.RubyExecutionConfig the configuration to use for executing ruby file
local function execute_file(config)
  local filename = vim.fn.expand("%:.")
  if string.match(filename, "%.rb$") then
    local command_to_run = config.cmd .. " " .. filename

    if config.include_line_number then
      command_to_run = command_to_run .. ":" .. vim.fn.line(".")
    end

    local bash_additional_flags = ""
    if config.use_interactive_shell then
      bash_additional_flags = "-i "
    end

    -- `-l 20` specifies the size of the tmux pane, in this case 20 rows
    vim.cmd(
      "silent !tmux split-window -v -l 20 '"
        .. "bash "
        .. bash_additional_flags
        .. '-c "'
        .. command_to_run
        .. "; echo; echo Press q to exit...; while true; do read -n 1 key; if [[ \\$key == \"q\" ]]; then exit; fi; done\"'"
    )
  else
    vim.notify("Not a Ruby file.", vim.log.levels.WARN)
  end
end

local M = {}
M.execute_file = execute_file
return M
