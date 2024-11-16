---Get the text selected in visual mode, to be used for example in the Telescope opts `default_text`.
---@return string: the selected text from visual mode
local function get_selected_text()
  vim.cmd('noau normal! "vy"')
  local text = vim.fn.getreg("v")
  vim.fn.setreg("v", {})
  text = string.gsub(text, "\n", "")
  if string.len(text) == 0 then
    text = ""
  end
  return text
end

local function is_test(filepath)
  local filename = filepath:match("([^/]+)$")
  return filename:match("_test") ~= nil
end

local function add_or_remove_test_suffix(filename)
  local name, extension = filename:match("(.+)%.(.+)")

  if is_test(filename) then
    return name:gsub("_test", "") .. "." .. extension
  end

  return name .. "_test." .. extension
end

local function sanitize_for_ruby(target)
  local parts = {}
  for part in target:gmatch("([^/]+)") do
    table.insert(parts, part)
  end

  -- If we are in a project that uses engines, i.e. directory in convention:
  -- engines/engine_name/app/path/to/file.rb => engines/engine_name/test/path/to/file_test.rb
  if #parts > 2 and parts[1] == "engines" then
    if is_test(target) then
      parts[3] = "test"
    else
      parts[3] = "app"
    end
  else
    -- Using the default ruby bundler path convention:
    -- lib/path/to/file.rb => test/path/to/file_test.rb
    if is_test(target) then
      parts[1] = "test"
    else
      parts[1] = "lib"
    end
  end

  return table.concat(parts, "/")
end

local function find_associate_test_or_file()
  local relative_filepath = vim.fn.expand("%")
  local _, extension = relative_filepath:match("(.+)%.(.+)")

  local target = add_or_remove_test_suffix(relative_filepath)

  if extension == "rb" then
    return sanitize_for_ruby(target)
  end

  return target
end

local M = {}

M.get_selected_text = get_selected_text
M.find_associate_test_or_file = find_associate_test_or_file

return M
