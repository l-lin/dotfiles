---@type string|nil
local last_command = nil

---Execute file on a new tmux pane below.
---@param cmd string the command to run
local function execute_file(cmd)
  local filename = vim.fn.expand("%:.")
  if string.match(filename, "%.zig$") then
    local command_to_run = cmd .. " " .. filename

    -- `-l 20` specifies the size of the tmux pane, in this case 20 rows
    local tmux_cmd = "silent !tmux split-window -v -l 20 '"
      .. 'bash -c "'
      .. command_to_run
      .. "; echo; echo Press q to exit...; while true; do read -n 1 key; if [[ \\$key == \"q\" ]]; then exit; fi; done\"'"

    last_command = tmux_cmd
    vim.cmd(tmux_cmd)
  else
    vim.notify("Not a Zig file.", vim.log.levels.WARN)
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
