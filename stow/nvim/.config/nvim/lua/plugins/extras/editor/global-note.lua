---@return string project_notes_directory containing the project notes
local function get_notes_directory()
  return os.getenv("HOME") .. "/perso/notes/2-areas/project-notes"
end

---@return string daily_notes_directory containing the daily notes
local function get_daily_notes_directory()
  return os.getenv("HOME") .. "/perso/notes/5-rituals/daily"
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
  return get_notes_directory() .. "/" .. get_project_name()
end

---Open the file on the current buffer, not on the floating window.
---@param window_id integer Window handle, or 0 for current window
local function open_file_under_cursor(window_id)
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
---- Close the floating window with "q".
---- Open the file under cursor in its original workspace with "gf".
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

local function daily_note_filename()
  return tostring(os.date("%Y-%m-%d")) .. ".md"
end

---@return GlobalNote_UserConfig global_opts the global note default options
local function global_opts()
  return {
    filename = "global.md",
    directory = get_notes_directory,
    command_name = "GlobalNote",
    post_open = post_open,
    additional_presets = {
      daily_note = {
        command_name = "DailyNote",
        directory = get_daily_notes_directory,
        filename = daily_note_filename,
        post_open = post_open,
        title = daily_note_filename,
      },
      project_note = {
        command_name = "ProjectNote",
        directory = get_project_directory,
        filename = get_project_name() .. ".md",
        post_open = post_open,
        title = get_project_name,
      },
    },
  }
end

---Open the note in floating window.
---@param filename string the file to open
---@param directory string the directory that contains the file
local function open_note(filename, directory)
  local global_note = require("global-note")
  local opts = global_opts()
  opts.additional_presets = {
    project_note = {
      directory = directory,
      filename = filename,
      post_open = post_open,
      title = filename,
    },
  }
  global_note.setup(opts)
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
          open_note(item.text, get_project_directory())
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
          open_note(input, get_project_directory())
        end
      end,
    },
  })
end

-- I frequently open global, project, or daily notes across multiple projects.
-- As a result, opening the same file can trigger a swap file error.
-- I don't need this safety feature, just allow me to edit these files!
local function disable_swap_for_dirs()
  local patterns = {
    get_project_directory(),
    get_daily_notes_directory()
  }

  for _, pattern in ipairs(patterns) do
    vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
      pattern = pattern,
      callback = function()
        vim.opt_local.swapfile = false
      end,
    })
  end
end

return {
  -- Opens global note in a floating window.
  {
    "backdround/global-note.nvim",
    cmd = { "GlobalNote" },
    keys = {
      { "<leader>fd", "<cmd>DailyNote<cr>", noremap = true, silent = true, desc = "Open daily notes" },
      { "<leader>fP", note_picker, noremap = true, silent = true, desc = "Open project notes" },
      { "<leader>fn", "<cmd>ProjectNote<cr>", noremap = true, silent = true, desc = "Open project note" },
      { "<leader>fN", "<cmd>GlobalNote<cr>", noremap = true, silent = true, desc = "Open global notes" },
    },
    opts = global_opts(),
    init = function ()
      disable_swap_for_dirs()
    end
  },
}
