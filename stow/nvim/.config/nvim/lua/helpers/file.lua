---Toggle file executable permission.
local function toggle_executable_permission()
  local file = vim.fn.expand("%")
  local perms = vim.fn.getfperm(file)
  local is_executable = string.match(perms, "x", -1) ~= nil
  local escaped_file = vim.fn.shellescape(file)
  if is_executable then
    vim.cmd("silent !chmod -x " .. escaped_file)
    vim.notify("Removed executable permission", vim.log.levels.INFO)
  else
    vim.cmd("silent !chmod +x " .. escaped_file)
    vim.notify("Added executable permission", vim.log.levels.INFO)
  end
end

---Execute the buffer as bash script in tmux split-window.
local function execute_bash_script()
  local filename = vim.fn.expand("%")
  local first_line = vim.fn.getline(1)
  -- Check if the bash script is valid by checking if it contains a shebang.
  if string.match(first_line, "^#!/") then
    -- Properly escape the file name for shell commands
    local escaped_file = vim.fn.shellescape(filename)
    -- Make the file executable
    vim.cmd("silent !chmod +x " .. escaped_file)

    -- Execute the script on a new tmux pane below.
    vim.cmd(
      "silent !tmux split-window -v -l 20 'bash -c \"./"
        .. escaped_file
        .. "; echo; echo Press q to exit...; while true; do read -n 1 key; if [[ \\$key == \"q\" ]]; then exit; fi; done\"'"
    )
  else
    vim.cmd("echo 'Not a script. Shebang line not found.'")
  end
end


local M = {}
M.toggle_executable_permission = toggle_executable_permission
M.execute_bash_script = execute_bash_script
return M
