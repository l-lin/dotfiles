--
-- Opens global note in a float window
--

---@return string
local function get_notes_directory()
  return vim.fn.expand(vim.g.notes_dir) .. "/2-areas/project-notes"
end

---@return string
local function get_daily_notes_directory()
  return vim.fn.expand(vim.g.notes_dir) .. "/5-rituals/daily"
end

---@return string
local function get_project_name()
  local result = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
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

---@return string
local function get_project_directory()
  return get_notes_directory() .. "/" .. get_project_name()
end

---@param window_id integer
local function open_file_under_cursor(window_id)
  local word = vim.fn.expand("<cfile>")
  if vim.fn.filereadable(word) == 1 then
    vim.api.nvim_win_close(window_id, true)
    vim.cmd("edit " .. word)
  else
    vim.cmd("normal! gf")
  end
end

---@param buffer_id integer|boolean
---@param window_id integer
local function post_open(buffer_id, window_id)
  vim.api.nvim_win_set_option(window_id, "relativenumber", true)

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(window_id, true)
  end, { buffer = buffer_id })

  vim.keymap.set("n", "gf", function()
    open_file_under_cursor(window_id)
  end, { buffer = buffer_id })
end

local function daily_note_filename()
  return tostring(os.date("%Y-%m-%d")) .. ".md"
end

---@return GlobalNote_UserConfig
local function global_opts()
  return {
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
    command_name = "GlobalNote",
    directory = get_notes_directory,
    filename = "global.md",
    post_open = post_open,
  }
end

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
  files = vim.tbl_filter(function(file)
    return vim.fn.isdirectory(target_dir .. "/" .. file) ~= 1
  end, files)

  local items = {}
  for index, file in ipairs(files) do
    items[#items + 1] = {
      file = target_dir .. "/" .. file,
      idx = index,
      score = index,
      text = file,
    }
  end

  if #items == 0 then
    items[1] = {
      file = target_dir .. "/" .. project_filename,
      text = project_filename,
    }
  end
  return items
end

local function note_picker()
  Snacks.picker({
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
          if not input:match("%.%w+$") then
            input = input .. ".md"
          end
          open_note(input, get_project_directory())
        end
      end,
    },
    format = "file",
    items = find_files(),
    source = "file",
    win = {
      input = {
        keys = {
          ["<C-s>"] = { "create_note", desc = "Create note", mode = { "i", "n" } },
        },
      },
      list = {
        keys = {
          ["<C-s>"] = "create_note",
        },
      },
    },
  })
end

local function disable_swap_for_dirs()
  local patterns = {
    get_notes_directory() .. "/*",
    get_project_directory() .. "/*",
    get_daily_notes_directory() .. "/*",
  }

  for _, pattern in ipairs(patterns) do
    vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
      callback = function()
        vim.opt_local.swapfile = false
      end,
      pattern = pattern,
    })
  end
end

--
-- Setup
--
disable_swap_for_dirs()
require("global-note").setup(global_opts())

--
-- Keymaps
--
local map = vim.keymap.set
map("n", "<leader>nd", "<cmd>DailyNote<cr>", { desc = "Open daily notes", noremap = true, silent = true })
map("n", "<leader>np", note_picker, { desc = "Open project notes", noremap = true, silent = true })
map("n", "<leader>nn", "<cmd>ProjectNote<cr>", { desc = "Open project note", noremap = true, silent = true })
map("n", "<leader>ng", "<cmd>GlobalNote<cr>", { desc = "Open global notes", noremap = true, silent = true })
