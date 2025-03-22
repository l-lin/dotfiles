---@return string root_directory containing the notes
local function get_root_directory()
  return os.getenv("HOME") .. "/perso/notes/2-areas/project-notes"
end

---@return string project_name project name, e.g. "dotfiles"
local function get_project_name()
  local result = vim
    .system({
      "git",
      "rev-parse",
      "--show-toplevel",
    }, {
      text = true,
    })
    :wait()

  if result.stderr ~= "" then
    vim.notify(result.stderr, vim.log.levels.WARN)
    return ""
  end

  local project_directory = result.stdout:gsub("\n", "")

  local project_name = vim.fs.basename(project_directory)
  if project_name == nil then
    vim.notify("Unable to get the project name", vim.log.levels.WARN)
    return ""
  end

  return project_name
end

---@return string project_directory containing the project notes
local function get_project_directory()
  return get_root_directory() .. "/" .. get_project_name()
end

---Open the file on the current buffer, not on the floating window.
---@param window_id integer Window handle, or 0 for current window
local open_file_under_cursor = function(window_id)
  local word = vim.fn.expand("<cfile>")
  -- Check if the word is a valid file path.
  if vim.fn.filereadable(word) == 1 then
    -- Close the floating window, so we won't open the file in the floating window.
    vim.api.nvim_win_close(window_id, true)
    -- Open the file in the current buffer
    vim.cmd("edit " .. word)
  else
    -- If not a valid file, fallback to default gf behavior.
    vim.cmd("normal! gf")
  end
end

---Add keymaps to:
---- close the floating window with "q"
---- open the file under cursor with "gf" so I don't have to change the workspace
---@param buffer_id integer|boolean `0` or `true` for current buffer.
---@param window_id integer Window handle, or 0 for current window
local function post_open(buffer_id, window_id)
  -- Add keymap on this buffer to press q to close the note.
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(window_id, true)
  end, { buffer = buffer_id })

  -- Remap gf to open the file under cursor in the current buffer, not
  -- in the floating window.
  vim.keymap.set("n", "gf", function()
    open_file_under_cursor(window_id)
  end, { buffer = buffer_id })
end

---Open the note in floating window.
---@param filename string the file to open
local function open_note(filename)
  local global_note = require("global-note")
  global_note.setup({
    additional_presets = {
      project_note = {
        command_name = "ProjectNote",
        directory = get_project_directory,
        filename = filename,
        post_open = post_open,
        title = filename,
      },
    },
  })
  global_note.toggle_note("project_note")
end

---@return snacks.picker.finder.Item[]
local function find_files()
  local target_dir = get_project_directory()
  local project_filename = get_project_name() .. ".md"

  if vim.fn.isdirectory(target_dir) ~= 1 then
    vim.notify("Directory " .. target_dir .. " does not exist => creating it.", vim.log.levels.TRACE)
    os.execute("mkdir -p " .. target_dir)
  end

  local files = vim.fn.readdir(target_dir)
  -- Filter out directories.
  files = vim.tbl_filter(function(file)
    return vim.fn.isdirectory(target_dir .. "/" .. file) ~= 1
  end, files)

  local items = {} ---@type snacks.picker.finder.Item[]
  for i, file in ipairs(files) do
    items[#items + 1] = {
      idx = i,
      score = i,
      file = target_dir .. "/" .. file,
      text = file,
    }
  end

  -- If there's no note for this project, suggest default.
  if #items == 0 then
    items[1] = {
      file = target_dir .. "/" .. project_filename,
      text = project_filename,
    }
  end
  return items
end

---Open picker to select a note.
local function note_picker()
  Snacks.picker({
    source = "file",
    items = find_files(),
    format = "file",
    win = {
      input = {
        keys = {
          ["<C-s>"] = { "create_note", desc = "Create note", mode = { "i", "n" } }
        },
      },
      list = {
        keys = {
          ["<C-s>"] = "create_note"
        },
      },
    },
    actions = {
      confirm = function(picker, item)
        picker:close()
        if item then
          open_note(item.text)
        end
      end,
      create_note = function(picker)
        local input = picker.input.filter.pattern
        picker:close()
        if input and input ~= "" then
          -- Add .md extension if not present
          if not input:match("%.%w+$") then
            input = input .. ".md"
          end
          open_note(input)
        end
      end,
    },
  })
end

return {
  -- Opens global note in a floating window.
  {
    "backdround/global-note.nvim",
    cmd = { "GlobalNote" },
    keys = {
      { "<leader>cn", note_picker, noremap = true, silent = true, desc = "Open project notes" },
      { "<leader>cN", "<cmd>GlobalNote<cr>", noremap = true, silent = true, desc = "Open global notes" },
    },
    opts = {
      filename = "global.md",
      directory = get_root_directory(),
      command_name = "GlobalNote",
      post_open = post_open,
    },
  },
}
