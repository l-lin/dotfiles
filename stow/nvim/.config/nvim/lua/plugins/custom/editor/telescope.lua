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

local function is_implementation(filepath)
  local filename = filepath:match("([^/]+)$")
  return filename:match("_test") ~= nil
end

local function add_or_remove_test_suffix(filename)
  local name, extension = filename:match("(.+)%.(.+)")

  if is_implementation(filename) then
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
  -- engines/engine_name/app/path/to/file.rb <=> engines/engine_name/test/path/to/file_test.rb
  -- engines/engine_name/lib/path/to/file.rb <=> engines/engine_name/test/lib/path/to/file_test.rb
  if #parts > 2 and parts[1] == "engines" then
    if is_implementation(target) then
      if parts[3] == "lib" then -- engines/engine_name/lib/path/to/file.rb => engines/engine_name/test/lib/path/to/file_test.rb
        parts[3] = "test/lib"
      else -- engines/engine_name/app/path/to/file.rb => engines/engine_name/test/path/to/file_test.rb
        parts[3] = "test"
      end
    else
      if #parts > 3 and parts[4] == "lib" then -- engines/engine_name/test/lib/path/to/file_test.rb => engines/engine_name/lib/path/to/file.rb
        table.remove(parts, 3)
      else -- engines/engine_name/test/path/to/file_test.rb => engines/engine_name/app/path/to/file.rb
        parts[3] = "app"
      end
    end
  else
    -- Using the default ruby bundler path convention:
    -- lib/path/to/file.rb => test/path/to/file_test.rb
    if is_implementation(target) then
      parts[1] = "test"
    else
      parts[1] = "lib"
    end
  end

  return table.concat(parts, "/")
end

---Find the associate test or implementation file depending on the current
---opened file in the current buffer.
---E.g. if the current buffer is:
---- lib/path/to/file.rb => test/path/to/file_test.rb
---- test/path/to/file_test.rb => lib/path/to/file.rb
---- src/foobar.go => src/foobar_test.go
---- src/foobar_test.go => src/foobar.go
---@return string: the associated test or implementation file
local function find_associate_test_or_file()
  local relative_filepath = vim.fn.expand("%:.")
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
