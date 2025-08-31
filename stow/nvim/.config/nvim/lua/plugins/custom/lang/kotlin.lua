---Extract package name from the first line of the file
---@return string|nil package_name The package name or nil if not found
local function get_package_name()
  local first_line = vim.fn.getline(1)
  return string.match(first_line, "^package%s+([%w%._]+)")
end

---Find the class that contains the cursor position by searching backwards
---@return string class_name The class name containing the cursor or filename as fallback
local function find_class_containing_cursor()
  local cursor_line = vim.fn.line(".")

  for line_num = cursor_line, 1, -1 do
    local line_content = vim.fn.getline(line_num)
    local found_class = string.match(line_content, "^%s*class%s+([%w_]+)")
    if found_class then
      return found_class
    end
  end

  -- Fallback to filename if no class found
  local filename = vim.fn.expand("%:t")
  local result, _ = string.gsub(filename, "%.kt$", "")
  return result
end

---Find the test method that contains the cursor position by searching backwards
---@return string|nil method_name The test method name or nil if not found
local function find_test_method_containing_cursor()
  local cursor_line = vim.fn.line(".")

  for line_num = cursor_line, 1, -1 do
    local line_content = vim.fn.getline(line_num)
    -- Match both regular method names and backtick-quoted method names
    local method_name = string.match(line_content, "^%s*fun%s+`([^`]+)`%s*%(")
    if not method_name then
      method_name = string.match(line_content, "^%s*fun%s+([%w_]+)%s*%(")
    end
    if method_name then
      return method_name
    end
  end

  return nil
end

---Build the fully qualified test name with optional method name
---@param include_method boolean Whether to include the method name
---@return string|nil full_test_name The fully qualified test name with optional method, nil if not found
local function build_test_name(include_method)
  local package_name = get_package_name()
  local class_name = find_class_containing_cursor()
  local base_name = package_name and (package_name .. "." .. class_name) or class_name

  if include_method then
    local method_name = find_test_method_containing_cursor()
    if method_name == nil or not method_name then
      return nil
    end
    return base_name .. "\\#" .. method_name
  end

  return base_name
end

---@class dotfiles.kotlin.TestConfig
---@field include_method boolean Whether to include the method name

---Execute the nearest test method with maven on a new tmux pane below
---@param config dotfiles.kotlin.TestConfig configuration options
local function execute(config)
  local filename = vim.fn.expand("%:t")
  if not string.match(filename, "%.kt$") then
    vim.notify("Not a Kotlin file.", vim.log.levels.WARN)
    return
  end

  local full_test_name = build_test_name(config.include_method)
  if full_test_name == nil then
    vim.notify("No test method found above the cursor.", vim.log.levels.WARN)
    return
  end

  local command_to_run = "./mvnw test -q -Dsurefire.failIfNoSpecifiedTests=false -Dtest=\\\"" .. full_test_name .. "\\\""

  local success_log = 'echo -e \\"\\e[1;30;42m SUCCESS \\e[0m\\"'
  -- `-l 20` specifies the size of the tmux pane, in this case 20 rows
  vim.cmd(
    "silent !tmux split-window -v -l 20 '"
      .. 'bash -i -c "'
      .. 'echo \\"' .. command_to_run .. '\\"'
      .. ' && ' .. command_to_run
      .. ' && ' .. success_log
      .. "; echo; echo Press q to exit...; while true; do read -n 1 key; if [[ \\$key == \"q\" ]]; then exit; fi; done\"'"
  )
end

local M = {}
M.execute_all_tests_with_maven = function () execute({ include_method = false }) end
M.execute_nearest_test_with_maven = function () execute({ include_method = true }) end
return M
