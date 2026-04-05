-- Build hooks (must be registered before vim.pack.add)
vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("pack_changed", { clear = true }),
  callback = function(ev)
    if ev.data.kind == "delete" then
      return
    end
    local name = ev.data.spec.name
    if name == "nvim-treesitter" then
      pcall(function()
        vim.cmd("TSUpdate")
      end)
    elseif name == "mason.nvim" then
      pcall(function()
        vim.cmd("MasonUpdate")
      end)
    end
  end,
})

vim.pack.add({
  -- Utility
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-neotest/nvim-nio",

  -- Treesitter
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
  "https://github.com/nvim-treesitter/nvim-treesitter-context",

  -- Completion
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.x") },
  "https://github.com/rafamadriz/friendly-snippets",

  -- LSP
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
  "https://github.com/b0o/schemastore.nvim",

  -- Mini
  { src = "https://github.com/nvim-mini/mini.nvim" },

  -- UI
  "https://github.com/folke/snacks.nvim",
  "https://github.com/folke/which-key.nvim",
  "https://github.com/folke/trouble.nvim",

  -- Editor
  "https://github.com/l-lin/emoji.nvim",
  "https://github.com/backdround/global-note.nvim",
  { src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2" },
  "https://github.com/folke/persistence.nvim",
  "https://github.com/christoomey/vim-tmux-navigator",
  "https://github.com/folke/todo-comments.nvim",
  "https://codeberg.org/l-lin/translate.nvim",
  "https://github.com/gbprod/yanky.nvim",

  -- Integration
  "https://codeberg.org/l-lin/jira.nvim",

  -- VCS
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/tpope/vim-fugitive",

  -- Coding
  "https://github.com/windwp/nvim-autopairs",
  "https://github.com/rcarriga/nvim-dap-ui",
  "https://github.com/mfussenegger/nvim-dap",
  "https://github.com/theHamsta/nvim-dap-virtual-text",

  -- Format
  "https://github.com/mfussenegger/nvim-lint",
  "https://github.com/stevearc/conform.nvim",

  -- AI
  "https://github.com/zbirenbaum/copilot.lua",
  "https://github.com/copilotlsp-nvim/copilot-lsp",
  "https://github.com/fang2hou/blink-copilot",
  "https://codeberg.org/l-lin/review-ai.nvim",
}, { load = true, confirm = false })

-- Load plugin configurations (order matters for dependencies)
require("plugins.treesitter")
require("plugins.ui")
require("plugins.editor")
require("plugins.coding")
require("plugins.lsp")
require("plugins.vcs")
require("plugins.integration")
require("plugins.format")
require("plugins.ai")
