local selector = require("plugins.custom.editor.selector")
local telescope_live_multigrep = require("plugins.custom.editor.telescope-live-multigrep")
local subject = require("plugins.custom.coding.subject")

local find_files = function(default_text)
  -- require("telescope.builtin").find_files({ default_text = default_text })

  require("telescope").extensions.smart_open.smart_open({
    cwd_only = true,
    match_algorithm = "fzf",
    default_text = default_text,
    filename_first = false,
  })
end

local mappings = {
  -- Invert the keymap because I'm already using C-q with tmux, and I more often sending the whole result to qflist.
  ["<M-q>"] = function(prompt_bufn)
    require("telescope.actions").send_to_qflist(prompt_bufn)
    require("trouble").open({ mode = "qflist", focus = true })
  end,
  ["<C-q>"] = function(prompt_bufn)
    require("telescope.actions").send_selected_to_qflist(prompt_bufn)
    require("trouble").open({ mode = "qflist", focus = true })
  end,
  ["<C-o>"] = function(prompt_bufn)
    local picker = require("telescope.actions.state").get_current_picker(prompt_bufn)
    local prompt = picker:_get_prompt()
    vim.api.nvim_command("edit! " .. prompt)
  end,
  ["<M-d>"] = require("telescope.actions").delete_buffer,
}

return {
  -- #######################
  -- override default config
  -- #######################

  -- fuzzy finding anything anywhere
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        "l-lin/smart-open.nvim",
        branch = "0.2.x",
        config = function()
          LazyVim.on_load("telescope.nvim", function()
            require("telescope").load_extension("smart_open")
          end)
        end,
        dependencies = { "kkharji/sqlite.lua" },
      },
    },
    keys = {
      -- disable
      { "<leader>gc", false },
      { "<leader>gs", false },
      -- finder
      {
        "<C-g>",
        function()
          find_files("")
        end,
        mode = "n",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
      {
        "<C-g>",
        function()
          find_files(selector.get_selected_text())
        end,
        mode = "v",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
      {
        "<C-t>",
        function()
          find_files(subject.find_subject())
        end,
        desc = "Find associated test file (Ctrl+t)",
        noremap = true,
        silent = true,
      },
      {
        "<M-f>",
        telescope_live_multigrep.search,
        mode = "n",
        noremap = true,
        silent = true,
        desc = "Find pattern in all files (Alt+f)",
      },
      {
        "<M-f>",
        function(opts)
          telescope_live_multigrep.search(opts, selector.get_selected_text())
        end,
        mode = "v",
        noremap = true,
        silent = true,
        desc = "Find pattern in all files (Alt+f)",
      },
      {
        "<C-e>",
        function()
          require("telescope.builtin").buffers({ sort_mru = true, ignore_current_buffer = true })
        end,
        noremap = true,
        silent = true,
        desc = "Find file in buffer (Ctrl+e)",
      },
      { "<C-x>", "<cmd>Telescope resume<cr>", noremap = true, silent = true, desc = "Resume search" },
      { "<M-6>", "<cmd>Telescope diagnostics<cr>", noremap = true, silent = true, desc = "Diagnostic (Alt+6)" },
    },
    opts = {
      defaults = {
        mappings = {
          i = mappings,
          n = mappings,
        },
        prompt_prefix = " ",
        path_display = {
          "truncate",
        },
        layout_strategy = "vertical",
        sorting_strategy = "ascending",
        layout_config = {
          vertical = {
            prompt_position = "bottom",
            mirror = false,
            preview_height = 0.65,
          }
        },
      },
      pickers = {
        buffers = {
          sort_mru = true,
          sort_lastused = true,
          initial_mode = "normal"
        },
        git_status = { initial_mode = "normal" }
      },
    },
  },

  -- highlight TODO comments
  {
    "folke/todo-comments.nvim",
    keys = {
      { "<M-2>", "<cmd>TodoTelescope<cr>", noremap = true, desc = "Telescope find TODO (Alt+2)" },
    },
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    opts = function ()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      keys[#keys + 1] = {
        "<C-b>",
        function() require("telescope.builtin").lsp_definitions({ reuse_win = true }) end,
        noremap = true,
        silent = true,
        desc = "Goto definition (Ctrl+b)",
      }
      keys[#keys + 1] = {
        "<M-&>",
        function() require("telescope.builtin").lsp_references({ show_line = false }) end,
        noremap = true,
        desc = "LSP references (Ctrl+Shift+7)",
      }
      keys[#keys + 1] = {
        "<M-C-B>",
        function() require("telescope.builtin").lsp_implementations({ reuse_win = true, show_line = false }) end,
        "Goto implementation (Ctrl+Alt+b)",
      }
    end
  },

  -- DAP
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>dd",
        "<cmd>Telescope dap configurations<cr>",
        noremap = true,
        silent = true,
        desc = "Telescope DAP configuration (Alt+Shift+F10)",
      },
      {
        "<M-S-F10>",
        "<cmd>Telescope dap configurations<cr>",
        noremap = true,
        silent = true,
        desc = "Telescope DAP configuration (Alt+Shift+F10)",
      },
    },
    dependencies = {
      "nvim-telescope/telescope-dap.nvim",
      config = function()
        LazyVim.on_load("telescope.nvim", function()
          require("telescope").load_extension("dap")
        end)
      end,
    },
  },
}
