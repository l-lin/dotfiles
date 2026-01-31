local selector = require("helpers.selector")
local subject = require("helpers.coding.subject")
local file_helper = require("helpers.file")

---Switch mode from files to grep.
---src: https://github.com/folke/snacks.nvim/discussions/499
---@param picker snacks.Picker the current picker
local function switch_to_grep(picker)
  local snacks = require("snacks")
  local cwd = picker.input.filter.cwd

  picker:close()

  local pattern = picker.input.filter.pattern or picker.input.filter.search
  local search = (pattern and pattern:match("%S")) and (" -- -g **/*" .. pattern .. "*/**") or ""

  snacks.picker.grep({ cwd = cwd, search = search })
  vim.defer_fn(function()
    require("helpers.cursor").move_to_column(0)
  end, 10)
end

---Append file search to the search.
---@param picker snacks.Picker the current picker
local function append_file_search(picker)
  local snacks = require("snacks")
  local cwd = picker.input.filter.cwd

  picker:close()

  local pattern = picker.input.filter.search or picker.input.filter.pattern
  local search = (pattern and pattern:match("%S")) and (pattern .. " -- -g **/**/**") or ""
  -- cursor position: after "pattern -- -g **/*" (before the second *)
  local cursor_col = (pattern and pattern:match("%S")) and (#pattern + #" -- -g **/*") or 0

  snacks.picker.grep({ cwd = cwd, search = search })
  vim.defer_fn(function()
    require("helpers.cursor").move_to_column(cursor_col)
  end, 10)
end

---Append file type to the search.
---@param picker snacks.Picker the current picker
local function append_file_type(picker)
  local snacks = require("snacks")
  local cwd = picker.input.filter.cwd

  picker:close()

  local pattern = picker.input.filter.search or picker.input.filter.pattern
  local filetype = vim.bo.filetype
  local search = (pattern and pattern:match("%S")) and (pattern .. " -- -t" .. filetype) or ""

  snacks.picker.grep({ cwd = cwd, search = search })
end

---Edit the file typed on the prompt.
---@param picker snacks.Picker the current picker
local function edit_file(picker)
  local prompt = picker.input.filter.pattern
  picker:close()
  vim.api.nvim_command("edit! " .. prompt)
end

local nav_keys_select = {
  input = {
    keys = {
      ["<M-C-j>"] = { "focus_list", mode = { "i", "n" } },
      ["<M-C-k>"] = { "", mode = { "i", "v" } },
    },
  },
  list = {
    keys = {
      ["<M-C-j>"] = "",
      ["<M-C-k>"] = "focus_input",
    },
  },
}

local snacks_picker_opts = {
  layouts = {
    vertical = {
      reverse = true,
      cycle = true,
      layout = {
        backdrop = false,
        border = "rounded",
        box = "vertical",
        height = 0.9,
        min_height = 30,
        title = "{title} {live} {flags}",
        title_pos = "center",
        width = 0.9,
        { win = "preview", title = "{preview}", height = 0.6, border = "bottom" },
        { win = "list", border = "none" },
        { win = "input", height = 1, border = "top" },
      },
    },
    select = { cycle = true },
  },
  -- Default layout to use.
  layout = "vertical",
  -- Default focus to use (input, list or preview).
  focus = "input",
  formatters = {
    file = { truncate = 150 },
  },
  previewers = {
    diff = {
      builtin = false,
      cmd = { "delta" },
    },
    git = { builtin = false },
  },
  sources = {
    files = {
      focus = "input",
      actions = {
        edit_file = edit_file,
        switch_to_grep = switch_to_grep,
      },
      win = {
        input = {
          keys = {
            ["<M-k>"] = { "switch_to_grep", desc = "Switch to grep", mode = { "i", "v" } },
            ["<C-s>"] = { "edit_file", desc = "Edit file", mode = { "i", "v" } },
          },
        },
        list = {
          keys = {
            ["<C-s>"] = "edit_file",
          },
        },
      },
    },
    git_files = {
      focus = "input",
      actions = {
        edit_file = edit_file,
        switch_to_grep = switch_to_grep,
      },
      win = {
        input = {
          keys = {
            ["<M-k>"] = { "switch_to_grep", desc = "Switch to grep", mode = { "i", "v" } },
            ["<C-s>"] = { "edit_file", desc = "Edit file", mode = { "i", "v" } },
          },
        },
        list = {
          keys = {
            ["<C-s>"] = "edit_file",
          },
        },
      },
    },
    grep = {
      actions = {
        append_file_search = append_file_search,
        append_file_type = append_file_type,
      },
      win = {
        input = {
          keys = {
            ["<M-k>"] = { "append_file_search", desc = "Append file search", mode = { "i", "v" } },
            ["<M-j>"] = { "append_file_type", desc = "Append file type", mode = { "i", "v" } },
          },
        },
      },
    },
    select = {
      win = nav_keys_select,
      focus = "input",
    },
  },
  win = {
    input = {
      keys = {
        ["<M-l>"] = { "focus_list", mode = { "i", "n" } },
        ["<M-w>"] = { "focus_preview", mode = { "i", "n" } },
        ["<M-q>"] = { "qflist", mode = { "i", "n" } },
        ["<M-C-j>"] = { "", mode = { "i", "v" } },
        ["<M-C-k>"] = { "focus_list", mode = { "i", "n" } },
      },
    },
    list = {
      keys = {
        ["a"] = "focus_input",
        ["<M-l>"] = "focus_list",
        ["<M-w>"] = "focus_preview",
        ["<M-q>"] = "qflist",
        ["<C-c>"] = "close",
        ["<M-C-k>"] = "focus_preview",
        ["<M-C-j>"] = "focus_input",
      },
    },
    preview = {
      keys = {
        ["a"] = "focus_input",
        ["<M-l>"] = "focus_list",
        ["<M-w>"] = "focus_preview",
        ["<M-C-j>"] = "focus_list",
        ["<M-C-k>"] = "",
      },
    },
  },
  debug = { scores = false },
}

return {
  -- No need for grug-far, let's use quickfix list!
  { "MagicDuck/grug-far.nvim", enabled = false },

  -- #######################
  -- override default config
  -- #######################

  -- picker
  {
    "folke/snacks.nvim",
    opts = {
      matcher = {
        fuzzy = true,
        cwd_bonus = true,
      },
      picker = snacks_picker_opts,
    },
    keys = {
      {
        "<C-g>",
        function()
          Snacks.picker.files({ focus = "input" })
        end,
        mode = "n",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
      {
        "<C-g>",
        function()
          Snacks.picker.files({ pattern = selector.get_selected_text() })
        end,
        mode = "v",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
      {
        "<C-t>",
        function()
          Snacks.picker.files({ pattern = subject.find_subject() })
        end,
        desc = "Find associated test file (Ctrl+t)",
        noremap = true,
        silent = true,
      },
      {
        "<M-f>",
        function()
          Snacks.picker.grep({ focus = "input" })
        end,
        mode = "n",
        noremap = true,
        silent = true,
        desc = "Find pattern in all files (Alt+f)",
      },
      {
        "<M-f>",
        function()
          Snacks.picker.grep({ search = selector.get_selected_text() })
        end,
        mode = "v",
        noremap = true,
        silent = true,
        desc = "Find pattern in all files (Alt+f)",
      },
      {
        "<M-e>",
        function()
          Snacks.picker.buffers({
            current = false,
            win = {
              input = {
                keys = {
                  ["<c-x>"] = { "bufdelete", mode = { "i", "n" } },
                  ["<C-j>"] = { "focus_list", mode = { "i", "n" } },
                  ["<C-k>"] = { "focus_preview", mode = { "i", "n" } },
                },
              },
              list = {
                keys = {
                  ["d"] = "bufdelete",
                  ["<C-j>"] = "",
                  ["<C-k>"] = "focus_input",
                },
              },
              preview = {
                keys = {
                  ["<C-j>"] = "focus_input",
                  ["<C-k>"] = "",
                },
              },
            },
            layout = "ivy_split",
          })
        end,
        noremap = true,
        silent = true,
        desc = "Find file in buffer (Ctrl+e)",
      },
      {
        "<C-x>",
        function()
          Snacks.picker.resume()
        end,
        noremap = true,
        silent = true,
        desc = "Resume search",
      },
      {
        "<M-6>",
        function()
          Snacks.picker.diagnostics()
        end,
        noremap = true,
        silent = true,
        desc = "Diagnostic (Alt+6)",
      },
      {
        "<leader>su",
        function()
          Snacks.picker.undo()
        end,
        noremap = true,
        silent = true,
        desc = "Undo",
      },
      { "<leader>n", false },
      { "<leader>N", function() Snacks.picker.notifications() end, desc = "Notification History" },
    },
  },

  -- highlight TODO comments
  {
    "folke/todo-comments.nvim",
    keys = {
      {
        "<M-2>",
        function()
          Snacks.picker.todo_comments()
        end,
        noremap = true,
        desc = "Find TODO (Alt+2)",
      },
    },
  },

  -- easily config neovim lsp
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            {
              "<C-b>",
              function()
                Snacks.picker.lsp_definitions()
              end,
              noremap = true,
              silent = true,
              desc = "Goto definition (Ctrl+b)",
            },
            {
              "<M-&>",
              function()
                Snacks.picker.lsp_references()
              end,
              noremap = true,
              desc = "LSP references (Ctrl+Shift+7)",
            },
            {
              "<M-C-B>",
              function()
                Snacks.picker.lsp_implementations()
              end,
              "Goto implementation (Ctrl+Alt+b)",
            },
          },
        },
      },
    },
  },
}
