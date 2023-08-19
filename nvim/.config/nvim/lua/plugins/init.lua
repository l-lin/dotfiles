local plugins = {
  -- -------------------------------------
  -- NVIM
  -- -------------------------------------

  -- -------------------------------------
  -- GUI
  -- -------------------------------------
  -- colorscheme
  {
    "sainnhe/gruvbox-material",
    enabled = false,
    lazy = false,
    priority = 1000,
    config = function() require("plugins.configs.gruvbox").setup() end,
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    config = function() require("plugins.configs.kanagawa").setup() end,
  },
  -- filetype icons
  {
    "nvim-tree/nvim-web-devicons",
    config = function() require("plugins.configs.web-devicons").setup() end,
    lazy = true,
  },
  -- display marks
  {
    "kshenoy/vim-signature",
    event = "VeryLazy",
  },
  -- status line (bottom)
  {
    "nvim-lualine/lualine.nvim",
    config = function() require("plugins.configs.lualine").setup() end,
    dependencies = {
      { "sainnhe/gruvbox-material",    opt = true, },
      { "rebelot/kanagawa.nvim",       opt = true, },
      { "nvim-tree/nvim-web-devicons", opt = true, }
    },
    event = "VimEnter",
  },
  -- buffer line (top)
  {
    "akinsho/bufferline.nvim",
    config = function() require("plugins.configs.bufferline").setup() end,
    dependencies = {
      { "sainnhe/gruvbox-material",    opt = true, },
      { "rebelot/kanagawa.nvim",       opt = true, },
      { "nvim-tree/nvim-web-devicons", opt = true, }
    },
    event = "VimEnter",
  },

  -- -------------------------------------
  -- EDITOR
  -- -------------------------------------
  -- autoclose pairs, (), []...
  {
    "windwp/nvim-autopairs",
    config = function() require("nvim-autopairs").setup({}) end,
    event = "VeryLazy",
  },
  -- syntax aware commenting
  {
    "numToStr/Comment.nvim",
    config = function() require("Comment").setup() end,
    event = "VeryLazy",
  },
  -- highlight TODO comments
  {
    "folke/todo-comments.nvim",
    config = function() require("plugins.configs.todo-comments").setup() end,
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
  },
  -- a pretty list for diagnostics
  {
    "folke/trouble.nvim",
    config = function() require("plugins.configs.trouble").setup() end,
    dependencies = { "nvim-tree/nvim-web-devicons", "neovim/nvim-lspconfig" },
    event = "VeryLazy",
  },
  -- multiple cursors
  {
    "mg979/vim-visual-multi",
    event = "VeryLazy",
    init = function() require("plugins.configs.visual-multi") end,
  },
  -- handle trailing whitespace
  {
    "ntpeters/vim-better-whitespace",
    config = function() require("plugins.configs.better-whitespace").setup() end,
    event = "VeryLazy"
  },
  -- automatically manage hlsearch
  {
    "asiryk/auto-hlsearch.nvim",
    config = function() require("auto-hlsearch").setup() end,
    event = "VeryLazy",
  },
  -- better glance at matched information
  {
    "kevinhwang91/nvim-hlslens",
    config = function() require("plugins.configs.hlslens").setup() end,
    event = "VeryLazy",
  },
  -- search and replace
  {
    "windwp/nvim-spectre",
    config = function() require("plugins.configs.spectre").setup() end,
  },
  -- markdown table
  {
    "dhruvasagar/vim-table-mode",
    event = "VeryLazy",
  },
  -- improved Yank with Yank ring to access to circle on yank history
  {
    "gbprod/yanky.nvim",
    config = function() require("plugins.configs.yanky").setup() end,
    event = "VeryLazy",
  },
  -- highlight words under cursor
  {
    "RRethy/vim-illuminate",
    config = function() require("plugins.configs.illuminate").setup() end,
    event = "VeryLazy",
  },

  -- -------------------------------------
  -- DEV
  -- -------------------------------------
  -- enhanced syntax by treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    config = function() require("plugins.configs.treesitter").setup() end,
    lazy = true,
  },
  -- ansible support
  -- FIX: not working with default config
  {
    "pearofducks/ansible-vim",
  },
  -- refactoring
  {
    "ThePrimeagen/refactoring.nvim",
    config = function() require("plugins.configs.refactoring").setup() end,
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy"
  },
  -- preview code actions
  {
    "aznhe21/actions-preview.nvim",
    config = function() require("plugins.configs.actions-preview").setup() end,
    event = "VeryLazy"
  },

  -- -------------------------------------
  -- LSP
  -- -------------------------------------
  -- easily config neovim lsp
  {
    "neovim/nvim-lspconfig",
    config = function() require("plugins.configs.lspconfig").setup() end,
    dependencies = { "williamboman/mason-lspconfig.nvim", "glepnir/lspsaga.nvim" },
  },
  -- easily install/update lsp servers directly from neovim
  {
    "williamboman/mason.nvim",
    config = function() require("plugins.configs.mason").setup() end,
    lazy = true,
  },
  -- bridge between mason and nvim-lspconfig
  {
    "williamboman/mason-lspconfig",
    config = function() require("plugins.configs.mason-lspconfig").setup() end,
    dependencies = "williamboman/mason.nvim",
  },
  -- ui for lsp features
  {
    "glepnir/lspsaga.nvim",
    config = function() require("plugins.configs.lspsaga").setup() end,
    dependencies = { "nvim-tree/nvim-web-devicons", "nvim-treesitter/nvim-treesitter" },
    lazy = true
  },
  -- lsp progress eye candy
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    config = function() require("plugins.configs.fidget").setup() end,
    tag = "legacy",
  },
  -- java support
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
  },
  -- lua support
  {
    "folke/neodev.nvim",
    config = function() require("plugins.configs.neodev").setup() end,
    ft = "lua",
  },

  -- -------------------------------------
  -- DAP
  -- -------------------------------------
  -- debugger engine
  {
    "mfussenegger/nvim-dap",
    config = function() require("plugins.configs.dap").setup() end,
    event = "VeryLazy",
  },
  -- dap ui
  {
    "rcarriga/nvim-dap-ui",
    config = function() require("plugins.configs.dap-ui").setup() end,
    dependencies = { "mfussenegger/nvim-dap" },
    event = "VeryLazy",
  },
  -- autocompletion for DAP
  {
    "rcarriga/cmp-dap",
    dependencies = { "hrsh7th/nvim-cmp" },
    event = "VeryLazy",
  },
  -- framework for interacting with tests
  {
    "nvim-neotest/neotest",
    config = function() require("plugins.configs.neotest").setup() end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-go"
    },
    event = "VeryLazy",
  },

  -- -------------------------------------
  -- AUTOCOMPLETION
  -- -------------------------------------
  -- add pictograms to cmp
  {
    "onsails/lspkind.nvim",
    lazy = true,
  },
  -- autocompletion engine
  {
    "hrsh7th/nvim-cmp",
    config = function() require("plugins.configs.cmp").setup() end,
    dependencies = { "onsails/lspkind.nvim" },
    lazy = true,
  },
  -- lsp based
  {
    "hrsh7th/cmp-nvim-lsp",
    dependencies = { "hrsh7th/nvim-cmp" },
  },
  -- buffer based
  {
    "hrsh7th/cmp-buffer",
    dependencies = { "hrsh7th/nvim-cmp" },
  },
  -- filepath based
  {
    "hrsh7th/cmp-path",
    dependencies = { "hrsh7th/nvim-cmp" },
  },
  -- command based
  {
    "hrsh7th/cmp-cmdline",
    dependencies = { "hrsh7th/nvim-cmp" },
  },
  -- autocompletion on lsp function/class signature
  {
    "hrsh7th/cmp-nvim-lsp-signature-help",
    dependencies = { "hrsh7th/nvim-cmp" },
  },
  -- lua support
  {
    "hrsh7th/cmp-nvim-lua",
    dependencies = { "hrsh7th/nvim-cmp" },
  },
  -- emoji support
  {
    "hrsh7th/cmp-emoji",
    dependencies = { "hrsh7th/nvim-cmp" },
  },
  -- omni
  {
    "hrsh7th/cmp-omni",
    dependencies = { "hrsh7th/nvim-cmp" },
  },
  -- autocompletion from tmux panes
  {
    "andersevenrud/cmp-tmux",
    dependencies = { "hrsh7th/nvim-cmp" },
  },
  -- the missing auto-completion for cmdline!
  {
    "gelguy/wilder.nvim",
    config = function() require("plugins.configs.wilder").setup() end,
  },
  -- snippet engine
  {
    "L3MON4D3/LuaSnip",
    config = function() require("plugins.configs.luasnip").setup() end,
    dependencies = { "hrsh7th/nvim-cmp", "rafamadriz/friendly-snippets", "honza/vim-snippets" },
    lazy = true,
  },
  -- buffer lines based
  {
    "amarakon/nvim-cmp-buffer-lines",
    dependencies = { "hrsh7th/nvim-cmp" },
  },
  -- snippets collection
  {
    "honza/vim-snippets",
    dependencies = { "hrsh7th/nvim-cmp" },
  },
  {
    "rafamadriz/friendly-snippets",
    dependencies = { "hrsh7th/nvim-cmp" },
  },
  -- luasnip snippets
  {
    "saadparwaiz1/cmp_luasnip",
    dependencies = { "hrsh7th/nvim-cmp" },
  },

  -- -------------------------------------
  -- NAVIGATION
  -- -------------------------------------
  -- file explorer
  {
    "nvim-tree/nvim-tree.lua",
    config = function() require("plugins.configs.tree").setup() end,
    event = "VeryLazy",
  },
  -- multilevel undo explorer
  {
    "mbbill/undotree",
    config = function() require("plugins.configs.undotree").setup() end,
    event = "VeryLazy",
  },
  -- fuzzy finding anything anywhere
  {
    "nvim-telescope/telescope.nvim",
    config = function() require("plugins.configs.telescope").setup() end,
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = true,
  },
  -- telescope extension to telescope as selection ui instead of vim command line
  {
    "nvim-telescope/telescope-ui-select.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
  },
  -- telescope extension for file browser
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
  },
  -- telescope extension for luasnip snippet
  {
    "benfowler/telescope-luasnip.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "L3MON4D3/LuaSnip" },
  },
  -- telescope dap
  {
    "nvim-telescope/telescope-dap.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
  },
  -- navigate your code with search labels, enhanced character motions and Treesitter integration
  {
    "folke/flash.nvim",
    config = function() require("plugins.configs.flash").setup() end,
    event = "VeryLazy",
  },
  -- file explorer to edit filesystem like a normal buffer, vim-vinegar like
  {
    "stevearc/oil.nvim",
    config = function() require("plugins.configs.oil").setup() end,
    event = "VeryLazy",
  },
  -- navigate between neovim and multiplexers
  {
    "numToStr/Navigator.nvim",
    config = function() require("plugins.configs.navigator").setup() end,
    event = "VeryLazy",
  },
  -- -------------------------------------
  -- GIT
  -- -------------------------------------
  -- git integration
  {
    "tpope/vim-fugitive",
    config = function() require("plugins.configs.fugitive").setup() end,
    event = "VeryLazy",
  },
  -- git modifications explorer/handler
  {
    "lewis6991/gitsigns.nvim",
    config = function() require("plugins.configs.gitsigns").setup() end,
  },
  -- nice view for git diff
  {
    "sindrets/diffview.nvim",
    config = function() require("plugins.configs.diffview").setup() end,
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- -------------------------------------
  -- MISC
  -- -------------------------------------
  -- show available keymaps + description as you type them
  {
    "folke/which-key.nvim",
    config = function() require("plugins.configs.which-key").setup() end,
    event = "VeryLazy",
  },
  -- open to last known cursor position
  {
    "ethanholz/nvim-lastplace",
    config = function() require("nvim-lastplace").setup() end,
  },
  -- session management
  {
    "folke/persistence.nvim",
    config = function() require("plugins.configs.persistence").setup() end,
    event = "BufReadPre",
  },
  -- dashboard
  {
    "glepnir/dashboard-nvim",
    config = function() require("plugins.configs.dashboard").setup() end,
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  -- project
  {
    "ahmedkhalf/project.nvim",
    config = function() require("project_nvim").setup() end,
    event = "VeryLazy",
  },
}

require("plugins.configs.lazy").setup(plugins)

