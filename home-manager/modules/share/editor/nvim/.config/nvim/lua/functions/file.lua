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

---Run the buffer as an executable script in a new pane below.
local function execute_bash_script()
  local filename = vim.fn.expand("%:p")
  local first_line = vim.fn.getline(1)
  if string.match(first_line, "^#!/") then
    local output = vim.fn.system({ "chmod", "+x", filename })
    if vim.v.shell_error ~= 0 then
      vim.notify(vim.trim(output), vim.log.levels.ERROR)
      return
    end
    require("functions.pane").run(vim.fn.shellescape(filename))
  else
    vim.cmd("echo 'Not a script. Shebang line not found.'")
  end
end

---Check if the current working directory is a git repository.
---@return boolean
local function is_git_repo()
  local git_dir = vim.fn.finddir(".git", vim.fn.getcwd() .. ";")
  return git_dir ~= ""
end

local M = {}
M.toggle_executable_permission = toggle_executable_permission
M.execute_bash_script = execute_bash_script
M.is_git_repo = is_git_repo
return M
