local selector = require("plugins.custom.editor.selector")
local subject = require("plugins.custom.coding.subject")

---Swap files and grep.
---src: https://github.com/folke/snacks.nvim/discussions/499
---@param picker snacks.Picker the current picker
local switch_grep_files = function(picker)
  -- switch b/w grep and files picker
  local snacks = require("snacks")
  local cwd = picker.input.filter.cwd
  local is_grep = picker.init_opts.source == "grep"

  picker:close()

  if is_grep then
    local pattern = picker.input.filter.search or picker.input.filter.pattern
    snacks.picker.files({ cwd = cwd, pattern = pattern })
  else
    local pattern = picker.input.filter.pattern or picker.input.filter.search
    snacks.picker.grep({ cwd = cwd, search = pattern })
  end
end

---Edit the file typed on the prompt.
---@param picker snacks.Picker the current picker
local edit_file = function(picker)
  local prompt = picker.input.filter.pattern
  picker:close()
  vim.api.nvim_command("edit! " .. prompt)
end

local nav_keys_select = {
  input = {
    keys = {
      ["<C-j>"] = { "focus_list", mode = { "i", "n" } },
      ["<C-k>"] = { "", mode = { "i", "v" } },
    },
  },
  list = {
    keys = {
      ["<C-j>"] = "",
      ["<C-k>"] = "focus_input"
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
      }
    },
    select = { cycle = true },
  },
  -- Default layout to use.
  layout = "vertical",
  -- Default focus to use (input, list or preview).
  focus = "list",
  formatters = {
    file = { truncate = 150 }
  },
  previewers = {
    diff = {
      builtin = false,
      cmd = { "delta" }
    },
    git = { builtin = false }
  },
  sources = {
    files = {
      focus = "input",
      actions = {
        edit_file = edit_file,
        switch_grep_files = switch_grep_files,
      },
      win = {
        input = {
          keys = {
            ["<A-k>"] = { "switch_grep_files", desc = "Switch to grep", mode = { "i", "v" } },
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
        switch_grep_files = switch_grep_files,
      },
      win = {
        input = {
          keys = {
            ["<A-k>"] = { "switch_grep_files", desc = "Switch to grep", mode = { "i", "v" } },
          },
        },
      },
    },
    select = {
      win = nav_keys_select
    }
  },
  win = {
    input = {
      keys = {
        ["<A-l>"] = { "focus_list", mode = { "i", "n" } },
        ["<A-w>"] = { "focus_preview", mode = { "i", "n" } },
        ["<A-q>"] = { "qflist", mode = { "i", "n" } },
        ["<C-j>"] = { "", mode = { "i", "v" } },
        ["<C-k>"] = { "focus_list", mode = { "i", "n" } },
      }
    },
    list = {
      keys = {
        ["a"] = "focus_input",
        ["<A-l>"] = "focus_list",
        ["<A-w>"] = "focus_preview",
        ["<A-q>"] = "qflist",
        ["<C-c>"] = "close",
        ["<C-k>"] = "focus_preview",
        ["<C-j>"] = "focus_input",
      }
    },
    preview = {
      keys = {
        ["a"] = "focus_input",
        ["<A-l>"] = "focus_list",
        ["<A-w>"] = "focus_preview",
        ["<C-j>"] = "focus_list",
        ["<C-k>"] = "",
      }
    }
  },
  debug = { scores = false }
}

return {
  -- No need for grug-far, let's use quickfix list!
  { "MagicDuck/grug-far.nvim", enabled = false, },

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
        function() Snacks.picker.files({ focus = "input" }) end,
        mode = "n",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
      {
        "<C-g>",
        function() Snacks.picker.files({ pattern = selector.get_selected_text() }) end,
        mode = "v",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
      {
        "<C-t>",
        function() Snacks.picker.files({ pattern = subject.find_subject() }) end,
        desc = "Find associated test file (Ctrl+t)",
        noremap = true,
        silent = true,
      },
      {
        "<M-f>",
        function () Snacks.picker.grep({ focus = "input" }) end,
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
        "<C-e>",
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
                }
              },
              preview = {
                keys = {
                  ["<C-j>"] = "focus_input",
                  ["<C-k>"] = "",
                },
              },
            },
            layout = "ivy_split"
          })
        end,
        noremap = true,
        silent = true,
        desc = "Find file in buffer (Ctrl+e)",
      },
      { "<C-x>", function() Snacks.picker.resume() end, noremap = true, silent = true, desc = "Resume search" },
      {
        "<M-6>",
        function()
          Snacks.picker.diagnostics()
        end,
        noremap = true,
        silent = true,
        desc = "Diagnostic (Alt+6)"
      },
      { "<leader>su", function() Snacks.picker.undo() end, noremap = true, silent = true, desc = "Undo" },
    }
  },

  -- highlight TODO comments
  {
    "folke/todo-comments.nvim",
    keys = {
      { "<M-2>", function() Snacks.picker.todo_comments() end, noremap = true, desc = "Find TODO (Alt+2)" },
    },
  },

  -- easily config neovim lsp
  {
    "neovim/nvim-lspconfig",
    opts = function ()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      keys[#keys + 1] = {
        "<C-b>",
        function() Snacks.picker.lsp_definitions() end,
        noremap = true,
        silent = true,
        desc = "Goto definition (Ctrl+b)",
      }
      keys[#keys + 1] = {
        "<M-&>",
        function() Snacks.picker.lsp_references() end,
        noremap = true,
        desc = "LSP references (Ctrl+Shift+7)",
      }
      keys[#keys + 1] = {
        "<M-C-B>",
        function() Snacks.picker.lsp_implementations() end,
        "Goto implementation (Ctrl+Alt+b)",
      }
    end
  },
}

