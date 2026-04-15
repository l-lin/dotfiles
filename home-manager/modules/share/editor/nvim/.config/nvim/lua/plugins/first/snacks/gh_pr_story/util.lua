local M = {}

local function notify_highlight(level)
  local levels = vim.log and vim.log.levels or {}
  if level == levels.ERROR then
    return "ErrorMsg"
  end
  if level == levels.WARN then
    return "WarningMsg"
  end
  return "None"
end

---@param value string
---@return string
function M.trim(value)
  if vim.trim then
    return vim.trim(value)
  end

  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

---@param path string
---@param child string
---@return string
function M.join_path(path, child)
  if path:sub(-1) == "/" then
    return path .. child
  end

  return path .. "/" .. child
end

---@param item table
---@return table
function M.shallow_copy(item)
  local copy = {}
  for key, value in pairs(item) do
    copy[key] = value
  end
  return copy
end

---@param args string[]
---@return string[]
local function command_args(args)
  local result = {}
  for index = 2, #args do
    table.insert(result, tostring(args[index]))
  end
  return result
end

---@param command string
---@param code number|nil
---@param stdout string|nil
---@param stderr string|nil
---@return string|nil
local function command_error(command, code, stdout, stderr)
  local trimmed_stderr = M.trim(stderr or "")
  if trimmed_stderr ~= "" then
    return trimmed_stderr
  end

  local trimmed_stdout = M.trim(stdout or "")
  if trimmed_stdout ~= "" then
    return trimmed_stdout
  end

  if code ~= nil then
    return ("%s exited with code %d"):format(command, code)
  end
end

---@param env table<string, string|number|boolean>|string[]|nil
---@return string[]|nil
local function spawn_env(env)
  if env == nil then
    return nil
  end

  if #env > 0 then
    local entries = {}
    for _, value in ipairs(env) do
      table.insert(entries, tostring(value))
    end
    return entries
  end

  local merged = {}
  local current_env = vim.fn and vim.fn.environ and vim.fn.environ() or vim.env or {}
  for key, value in pairs(current_env) do
    if type(key) == "string" and value ~= nil then
      merged[key] = tostring(value)
    end
  end
  for key, value in pairs(env) do
    if type(key) == "string" then
      if value == nil or value == false then
        merged[key] = nil
      else
        merged[key] = tostring(value)
      end
    end
  end

  local entries = {}
  for key, value in pairs(merged) do
    table.insert(entries, ("%s=%s"):format(key, value))
  end
  return entries
end

---@param args string[]
---@param opts table|nil
---@return string|nil
---@return string|nil
local function run_with_system(args, opts)
  local result = vim
    .system(args, {
      cwd = opts.cwd,
      env = opts.env,
      text = true,
      timeout = opts.timeout_ms,
    })
    :wait()

  local stdout = result.stdout or ""
  if result.code ~= 0 then
    return nil, command_error(args[1], result.code, stdout, result.stderr)
  end

  return stdout, nil
end

---@param args string[]
---@param opts table|nil
---@return string|nil
---@return string|nil
local function run_with_spawn(args, opts)
  local proc = require("snacks.util.spawn").new({
    args = command_args(args),
    cmd = tostring(args[1]),
    cwd = opts.cwd,
    env = spawn_env(opts.env),
    timeout = opts.timeout_ms,
  })

  proc:wait()
  local stdout = proc:out()
  if proc:failed() then
    return nil, command_error(args[1], proc.code, stdout, proc:err())
  end

  return stdout, nil
end

---@param args string[]
---@param opts table|nil
---@return string|nil
---@return string|nil
function M.run_command(args, opts)
  opts = opts or {}

  local ok, async = pcall(require, "snacks.picker.util.async")
  if ok and async.running() then
    return run_with_spawn(args, opts)
  end

  return run_with_system(args, opts)
end

---@param message string|nil
---@param level number|nil
function M.schedule_notify(message, level)
  if type(message) ~= "string" or message == "" then
    return
  end

  local highlight = notify_highlight(level)
  vim.schedule(function()
    local ok = pcall(vim.api.nvim_echo, { { message, highlight } }, true, {})
    if not ok then
      pcall(vim.api.nvim_err_writeln, message)
    end
  end)
end

return M
