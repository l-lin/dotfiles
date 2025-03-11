local selector = require("plugins.custom.editor.selector")
local subject = require("plugins.custom.coding.subject")

local default_to_normal = function()
  vim.cmd.stopinsert()
end

---Swap files and grep.
---src: https://github.com/folke/snacks.nvim/discussions/499
---TODO: Check if snacks has an API to which picker is being used instead of
---passing a flag.
---@param picker any
---@param is_grep boolean true if the picker is grep picker, false otherwise
local function switch_grep_files(picker, is_grep)
  -- switch b/w grep and files picker
  local snacks = require("snacks")
  local cwd = picker.input.filter.cwd

  picker:close()

  if is_grep then
    -- if we are inside grep picker then switch to files picker and set M.is_grep = false
    local pattern = picker.input.filter.search or picker.input.filter.pattern
    snacks.picker.files({ cwd = cwd, pattern = pattern })
    is_grep = false
    return
  else
    -- if we are inside files picker then switch to grep picker and set M.is_grep = true
    local pattern = picker.input.filter.pattern or picker.input.filter.search
    snacks.picker.grep({ cwd = cwd, search = pattern })
    is_grep = true
  end
end

local snacks_picker_opts = {
  layouts = {
    vertical = {
      reverse = true,
      cycle = true,
      layout = {
        backdrop = false,
        width = 0.9,
        min_width = 80,
        height = 0.9,
        min_height = 30,
        box = "vertical",
        border = "rounded",
        title = "{title} {live} {flags}",
        title_pos = "center",
        { win = "preview", title = "{preview}", height = 0.8, border = "bottom" },
        { win = "list", border = "none" },
        { win = "input", height = 1, border = "top" },
      }
    },
    select = {
      layout = {
        width = 0.9
      }
    },
  },
  -- Default layout to use.
  layout = "vertical",
  formatters = {
    file = { filename_first = true, truncate = 150 }
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
      actions = {
        switch_grep_files = function(picker, _)
          switch_grep_files(picker, false)
        end,
      },
      win = {
        input = {
          keys = {
            ["<a-k>"] = { "switch_grep_files", desc = "Switch to grep", mode = { "i", "v" } },
          },
        },
      },
    },
    grep = {
      actions = {
        switch_grep_files = function(picker, _)
          switch_grep_files(picker, true)
        end,
      },
      win = {
        input = {
          keys = {
            ["<a-k>"] = { "switch_grep_files", desc = "Switch to grep", mode = { "i", "v" } },
          },
        },
      },
    },
  },
  win = {
    input = {
      keys = {
        ["<A-l>"] = { "focus_list", mode = { "i", "n" } },
        ["<A-w>"] = { "focus_preview", mode = { "i", "n" } },
      }
    },
    list = {
      keys = {
        ["<A-l>"] = { "focus_list", mode = { "i", "n" } },
        ["<A-w>"] = { "focus_preview", mode = { "i", "n" } },
        ["<C-c>"] = "close",
      }
    },
    preview = {
      keys = {
        ["<A-l>"] = { "focus_list", mode = { "i", "n" } },
        ["<A-w>"] = { "focus_preview", mode = { "i", "n" } },
      }
    }
  },
  debug = { scores = true }
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
      matcher = { frecency = true },
      picker = snacks_picker_opts,
    },
    keys = {
      {
        "<C-g>",
        function() Snacks.picker.files() end,
        mode = "n",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
      {
        "<C-g>",
        function()
          Snacks.picker.files({
            on_show = default_to_normal,
            pattern = selector.get_selected_text()
          })
        end,
        mode = "v",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
      {
        "<C-t>",
        function()
          Snacks.picker.files({
            on_show = default_to_normal,
            pattern = subject.find_subject()
          })
        end,
        desc = "Find associated test file (Ctrl+t)",
        noremap = true,
        silent = true,
      },
      {
        "<M-f>",
        function () Snacks.picker.grep() end,
        mode = "n",
        noremap = true,
        silent = true,
        desc = "Find pattern in all files (Alt+f)",
      },
      {
        "<M-f>",
        function()
          Snacks.picker.grep({
            on_show = default_to_normal,
            search = selector.get_selected_text()
          })
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
            on_show = default_to_normal,
            finder = "buffers",
            format = "buffer",
            hidden = false,
            unloaded = true,
            current = false,
            sort_lastused = true,
            win = {
              input = {
                keys = {
                  ["<c-x>"] = "bufdelete",
                },
              },
              list = { keys = { ["d"] = "bufdelete" } },
            },
            layout = "select"
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
          Snacks.picker.diagnostics({ on_show = default_to_normal })
        end,
        noremap = true,
        silent = true,
        desc = "Diagnostic (Alt+6)"
      },
      { "<leader>su", function() Snacks.picker.undo({ on_show = default_to_normal }) end, noremap = true, silent = true, desc = "Undo" },
    }
  },

  -- highlight TODO comments
  {
    "folke/todo-comments.nvim",
    keys = {
      {
        "<M-2>",
        function()
          Snacks.picker.todo_comments({ on_show = default_to_normal, })
        end,
        noremap = true,
        desc = "Find TODO (Alt+2)"
      },
    },
  },

  -- better diagnostics list and others
  {
    "folke/trouble.nvim",
    optional = true,
    specs = {
      "folke/snacks.nvim",
      opts = function(_, opts)
        return vim.tbl_deep_extend("force", opts or {}, {
          picker = {
            actions = require("trouble.sources.snacks").actions,
            win = {
              input = {
                keys = {
                  ["<c-t>"] = {
                    "trouble_open",
                    mode = { "n", "i" },
                  },
                },
              },
            },
          },
        })
      end,
    },
  },

  -- code outline window
  {
    "stevearc/aerial.nvim",
    optional = true,
    keys = {
      {
        "<F36>", function ()
        require("aerial").snacks_picker({
            on_show = default_to_normal,
            layout = {
              preset = "dropdown",
              preview = false
            }
          })
        end,
        desc = "Goto Symbol (Ctrl+F12)"
      },
    },
  },

  -- easily config neovim lsp
  {
    "neovim/nvim-lspconfig",
    opts = function ()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      keys[#keys + 1] = {
        "<C-b>",
        function() Snacks.picker.lsp_definitions({ on_show = default_to_normal }) end,
        noremap = true,
        silent = true,
        desc = "Goto definition (Ctrl+b)",
      }
      keys[#keys + 1] = {
        "<M-&>",
        function() Snacks.picker.lsp_references({ on_show = default_to_normal }) end,
        noremap = true,
        desc = "LSP references (Ctrl+Shift+7)",
      }
      keys[#keys + 1] = {
        "<M-C-B>",
        function() Snacks.picker.lsp_implementations({ on_show = default_to_normal }) end,
        "Goto implementation (Ctrl+Alt+b)",
      }
    end
  },
}

