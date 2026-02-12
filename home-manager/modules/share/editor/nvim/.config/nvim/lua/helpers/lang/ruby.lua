---@type string|nil
local last_command = nil

---@class dotfiles.ruby.RubyExecutionConfig
---@field cmd string the command to run
---@field use_interactive_shell boolean true to run the command in interactive shell
---@field include_line_number boolean true to include the current line number in the command to run

---Execute file on a new tmux pane below.
---@param config dotfiles.ruby.RubyExecutionConfig the configuration to use for executing ruby file
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
    local tmux_cmd = "silent !tmux split-window -v -l 20 '"
      .. "bash "
      .. bash_additional_flags
      .. '-c "'
      .. command_to_run
      .. "; echo; echo Press q to exit...; while true; do read -n 1 key; if [[ \\$key == \"q\" ]]; then exit; fi; done\"'"

    last_command = tmux_cmd
    vim.cmd(tmux_cmd)
  else
    vim.notify("Not a Ruby file.", vim.log.levels.WARN)
  end
end

---Re-run the last executed command.
local function rerun_last()
  if last_command then
    vim.cmd(last_command)
  else
    vim.notify("No previous command to re-run.", vim.log.levels.WARN)
  end
end

local M = {}
M.execute_file = execute_file
M.rerun_last = rerun_last
return M
