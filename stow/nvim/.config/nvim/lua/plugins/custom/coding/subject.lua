---Check if the given filepath is a test or implementation file.
---@param filepath string the filepath to check
---@param test_suffix string the test suffix, e.g. "_test" or ".test" depending on the programming language
---@return boolean is_test true if it's an test file, false otherwise
local function is_test(filepath, test_suffix)
  local filename = filepath:match("([^/]+)$")
  return filename:match(test_suffix) ~= nil
end

---Add or remove the test suffix to the given filepath.
---Examples:
---- src/foobar.go            => src/foobar_test.go
---- src/foobar_test.go       => src/foobar.go
---- src/foobar.ts            => src/foobar.test.ts
---- src/foobar.test.ts       => src/foobar.ts
---- src/main/Foobar.java     => src/main/FoobarTest.java
---- src/main/FoobarTest.java => src/main/Foobar.java
---@param filepath string the filepath to add or remove the test suffix
---@param test_suffix string the test suffix, e.g. "_test" or ".test" depending on the programming language
---@return string converted_filename new filepath with/without the test suffix
local function add_or_remove_test_suffix(filepath, test_suffix)
  local name, extension = filepath:match("(.+)%.(.+)")

  if is_test(filepath, test_suffix) then
    return name:gsub(test_suffix, "") .. "." .. extension
  end

  return name .. test_suffix .. "." .. extension
end


-- ############################################################################
-- RUBY
-- ############################################################################

---Sanitize the file to search for Ruby files.
---@param filepath string the filepath to look for either the test or implementation file
---@return string sanitized_filepath new filepath with/without the test suffix
local function sanitize_for_ruby(filepath)
  local parts = {}
  for part in filepath:gmatch("([^/]+)") do
    table.insert(parts, part)
  end

  local test_suffix = "_test"

  -- If we are in a project that uses engines, i.e. directory in convention:
  -- engines/engine_name/app/path/to/file.rb <=> engines/engine_name/test/path/to/file_test.rb
  -- engines/engine_name/lib/path/to/file.rb <=> engines/engine_name/test/lib/path/to/file_test.rb
  if #parts > 2 and parts[1] == "engines" then
    if is_test(filepath, test_suffix) then
      if #parts > 3 and parts[4] == "lib" then -- engines/engine_name/test/lib/path/to/file_test.rb => engines/engine_name/lib/path/to/file.rb
        table.remove(parts, 3)
      else -- engines/engine_name/test/path/to/file_test.rb => engines/engine_name/app/path/to/file.rb
        parts[3] = "app"
      end
    else
      if parts[3] == "lib" then -- engines/engine_name/lib/path/to/file.rb => engines/engine_name/test/lib/path/to/file_test.rb
        parts[3] = "test/lib"
      else -- engines/engine_name/app/path/to/file.rb => engines/engine_name/test/path/to/file_test.rb
        parts[3] = "test"
      end
    end
  else
    -- Using the default ruby bundler path convention:
    -- lib/path/to/file.rb => test/path/to/file_test.rb
    if is_test(filepath, test_suffix) then
      parts[1] = "lib"
    else
      parts[1] = "test"
    end
  end

  return add_or_remove_test_suffix(table.concat(parts, "/"), test_suffix)
end

-- ############################################################################
-- TYPESCRIPT / REACT
-- ############################################################################

---Sanitize the file to search for Typescript / React files.
---@param filepath string the filepath to look for either the test or implementation file
---@return string sanitized_filepath new filepath with/without the test suffix
local function sanitize_for_ts(filepath)
  return add_or_remove_test_suffix(filepath, ".test")
end

-- ############################################################################
-- JAVA
-- ############################################################################

---Sanitize the file to search for Java files.
---@param filepath string the filepath to look for the test or implementation file
---@return string sanitized_filepath new filepath with/without the test suffix
local function sanitize_for_java(filepath)
  local parts = {}
  for part in filepath:gmatch("([^/]+)") do
    table.insert(parts, part)
  end

  local test_suffix = "Test"

  -- Find the index of "src" in the path
  local src_index = nil
  for i, part in ipairs(parts) do
    if part == "src" then
      src_index = i
      break
    end
  end

  if src_index and src_index < #parts then
    if is_test(filepath, test_suffix) then
      parts[src_index + 1] = "main"
    else
      parts[src_index + 1] = "test"
    end
  end

  return add_or_remove_test_suffix(table.concat(parts, "/"), test_suffix)
end

-- ############################################################################

---Find the associate test or implementation file depending on the current
---opened file in the current buffer.
---E.g. if the current buffer is:
---- lib/path/to/file.rb => test/path/to/file_test.rb
---- test/path/to/file_test.rb => lib/path/to/file.rb
---- src/foobar.go => src/foobar_test.go
---- src/foobar_test.go => src/foobar.go
---@return string: the associated test or implementation file
local function find_subject()
  local relative_filepath = vim.fn.expand("%:.")
  local filetype = vim.bo.filetype

  if filetype == "ruby" then
    return sanitize_for_ruby(relative_filepath)
  end

  if filetype == "typescript" or filetype == "typescriptreact" then
    return sanitize_for_ts(relative_filepath)
  end

  if filetype == "java" then
    return sanitize_for_java(relative_filepath)
  end

  return add_or_remove_test_suffix(relative_filepath, "_test")
end

local M = {}
M.find_subject = find_subject
return M
