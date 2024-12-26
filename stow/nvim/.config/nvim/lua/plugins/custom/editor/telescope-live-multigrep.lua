local conf = require("telescope.config").values
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")

---Search for word on current working directory with additional features to add
---ripgrep flags, like "--hidden", "-tlua" or "-g *.lua", by pressing double
---spaces.
---It's better than nvim-telescope/telescope-live-grep-args.nvim for me because
---this won't add double quotes in the prompt, which are a hassle when trying to
---find stuff.
---
---src: TJ DeVries - https://www.youtube.com/watch?v=xdXE1tOT-qg
local function search(opts, default_text)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()
  opts.default_text = default_text or ""

  local finder = finders.new_async_job({
    command_generator = function(prompt)
      if not prompt or prompt == "" then
        return nil
      end

      local pieces = vim.split(prompt, "  ")
      local args = { "rg" }
      if pieces[1] then
        table.insert(args, "-e")
        table.insert(args, pieces[1])
      end

      -- pieces[2] is the content of what's typed after the double space
      if pieces[2] then
        local nested_pieces = vim.split(pieces[2], " ")
        for _, nested_piece in ipairs(nested_pieces) do
          table.insert(args, nested_piece)
        end
      end

      local additional_rg_opts = {
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
      }

      ---@diagnostic disable-next-line: deprecated
      return vim.tbl_flatten({ args, additional_rg_opts })
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  })
  pickers
    .new(opts, {
      debounce = 100,
      prompt_title = "Live Multi Grep",
      finder = finder,
      previewer = conf.grep_previewer(opts),
      sorter = sorters.highlighter_only(opts),
    })
    :find()
end

local M = {}

M.search = search

return M
