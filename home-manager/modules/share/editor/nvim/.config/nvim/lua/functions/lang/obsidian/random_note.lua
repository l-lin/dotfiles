---@class dotfiles.obsidian.RandomNote
---@field filename string the random note file name
---@field filepath string the absolute filepath of the random note

---Return random file from given files.
---@param files string[] the list of files to make a random
---@return string|nil random_file the random file
local function random(files)
  if #files == 0 then
    return nil
  end

  math.randomseed(os.time())
  return files[math.random(#files)]
end

---Return the filename of the given filepath.
---@param relative_dir string the relative filepath
---@return string filename the extracted filename without its extension
local function filename(relative_dir)
  return relative_dir:match("([^/]+)%.md$")
end

---Return a random note from given directory filepath.
---@param relative_dir string relative filepath of the directory where to open a random note
---@return dotfiles.obsidian.RandomNote|nil random_note the filepath of the random note, nil if there's no note
local function pick(relative_dir)
  if vim.fn.isdirectory(relative_dir) ~= 1 then
    return nil
  end

  local files = vim.fs.find(function(name)
    return name:match("%.md$")
  end, { limit = math.huge, type = "file", path = relative_dir })

  local random_file = random(files)
  if not random_file then
    return nil
  end

  ---@type dotfiles.obsidian.RandomNote
  return {
    filepath = random_file,
    filename = filename(random_file),
  }
end

---Open a random note.
---@param directory_filepath string file path of the directory where to open a random note
local function open(directory_filepath)
  local random_note = pick(directory_filepath)
  if random_note then
    vim.cmd("edit " .. vim.fn.fnameescape(random_note.filepath))
  else
    vim.notify("No random note found", vim.log.levels.WARN)
  end
end

local M = {}
M.pick = pick
M.open = open
return M
