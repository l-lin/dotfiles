local plugins = {
  -- -------------------------------------
  -- NVIM
  -- -------------------------------------
  -- lua module for asynchronous programming (dependancy lib)
  {
    "nvim-lua/plenary.nvim",
  },

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
  },
  -- status line (bottom)
  {
    "nvim-lualine/lualine.nvim",
    event = "VimEnter",
    config = function() require("plugins.configs.lualine").setup() end,
  },
  -- buffer line (top)
  {
    "akinsho/bufferline.nvim",
    event = "VimEnter",
    config = function() require("plugins.configs.bufferline").setup() end,
  },

  -- -------------------------------------
  -- EDITOR
  -- -------------------------------------
  -- syntax aware commenting
  {
    "numToStr/Comment.nvim",
    keys = {
      { "gcc", mode = "n",          desc = "Comment toggle current line" },
      { "gc",  mode = { "n", "o" }, desc = "Comment toggle linewise" },
      { "gc",  mode = "x",          desc = "Comment toggle linewise (visual)" },
      { "gbc", mode = "n",          desc = "Comment toggle current block" },
      { "gb",  mode = { "n", "o" }, desc = "Comment toggle blockwise" },
      { "gb",  mode = "x",          desc = "Comment toggle blockwise (visual)" },
    },
    config = function(_, opts) require("Comment").setup(opts) end,
  },
  -- highlight TODO comments
  {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    keys = {
      { "<M-2>", "<cmd>TodoTelescope<cr>", noremap = true, desc = "Telescope find TODO (Alt+2)" }
    },
    config = function() require("todo-comments").setup() end,
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  -- a pretty list for diagnostics
  {
    "folke/trouble.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>xx",
        "<cmd>TroubleToggle<cr>",
        noremap = true,
        silent = true,
        desc = "Toggle trouble",
      },
      {
        "<leader>xw",
        "<cmd>TroubleToggle workspace_diagnostics<cr>",
        noremap = true,
        silent = true,
        desc = "Toggle trouble workspace diagnostics",
      },
      {
        "<leader>xd",
        "<cmd>TroubleToggle document_diagnostics<cr>",
        noremap = true,
        silent = true,
        desc = "Toggle trouble document diagnostics",
      },
      {
        "<leader>xl",
        "<cmd>TroubleToggle loclist<cr>",
        noremap = true,
        silent = true,
        desc = "Toggle trouble loclist",
      },
      {
        "<leader>xq",
        "<cmd>TroubleToggle quickfix<cr>",
        noremap = true,
        silent = true,
        desc = "Toggle trouble quickfix",
      },
      {
        "<leader>xu",
        "<cmd>TroubleToggle lsp_references<cr>",
        noremap = true,
        silent = true,
        desc = "Toggle trouble LSP reference",
      },
    },
    config = function() require("plugins.configs.trouble").setup() end,
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  -- multiple cursors
  {
    "mg979/vim-visual-multi",
    event = "ModeChanged",
    init = function() require("plugins.configs.visual-multi").setup() end,
  },
  -- handle trailing whitespace
  {
    "ntpeters/vim-better-whitespace",
    event = "VeryLazy",
    keys = {
      { "<leader>ws", "<cmd>StripWhitespace<cr>",  noremap = true, silent = true, desc = "Strip whitespace" },
      { "<leader>wt", "<cmd>ToggleWhitespace<cr>", noremap = true, silent = true, desc = "Toggle whitespace" },
    },
    config = function() require("plugins.configs.better-whitespace").setup() end,
  },
  -- automatically manage hlsearch
  {
    "asiryk/auto-hlsearch.nvim",
    event = "VeryLazy",
    config = function() require("auto-hlsearch").setup() end,
  },
  -- better glance at matched information
  {
    "kevinhwang91/nvim-hlslens",
    keys = {
      { "n", [[<Cmd>execute("normal! " . v:count1 . "n")<cr><Cmd>lua require("hlslens").start()<cr>]], },
      { "N", [[<Cmd>execute("normal! " . v:count1 . "N")<cr><Cmd>lua require("hlslens").start()<cr>]], },
      { "*", [[*<Cmd>lua require("hlslens").start()<cr>]], },
      { "#", [[#<Cmd>lua require("hlslens").start()<cr>]], },
    },
  },
  -- search and replace
  {
    "windwp/nvim-spectre",
    keys = {
      {
        "<leader>rr",
        "<cmd>lua require('spectre').open()<cr>",
        mode = { "n", "v" },
        noremap = true,
        silent = true,
        desc = "Spectre open search and replace"
      },
      {
        "<leader>rw",
        "<cmd>lua require('spectre').open_visual({select_word=true})<cr>",
        mode = "v",
        noremap = true,
        silent = true,
        desc = "Spectre open visual search and replace word"
      },
      {
        "<A-r>",
        "<cmd>lua require('spectre').open_file_search()<cr>",
        noremap = true,
        silent = true,
        desc = "Spectre open search and replace in file (Alt+r)"
      },
      {
        "<leader>rf",
        "<cmd>lua require('spectre').open_file_search()<cr>",
        noremap = true,
        silent = true,
        desc = "Spectre open search and replace in file"
      },
    },
  },
  -- markdown table
  {
    "dhruvasagar/vim-table-mode",
    ft = "md",
  },
  -- improved Yank with Yank ring to access to circle on yank history
  {
    "gbprod/yanky.nvim",
    keys = {
      { "p",     "<Plug>(YankyPutAfter)",     mode = { "n", "x" } },
      { "p",     "<Plug>(YankyPutAfter)",     mode = { "n", "x" } },
      { "P",     "<Plug>(YankyPutBefore)",    mode = { "n", "x" } },
      { "gp",    "<Plug>(YankyGPutAfter)",    mode = { "n", "x" } },
      { "gP",    "<Plug>(YankyGPutBefore)",   mode = { "n", "x" } },
      { "<c-n>", "<Plug>(YankyCycleForward)" },
      { "<c-p>", "<Plug>(YankyCycleBackward)" },
    },
    config = function() require("plugins.configs.yanky").setup() end,
  },
  -- highlight words under cursor
  {
    "RRethy/vim-illuminate",
    event = "LspAttach",
    config = function() require("plugins.configs.illuminate").setup() end,
  },

  -- -------------------------------------
  -- DEV
  -- -------------------------------------
  -- enhanced syntax by treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    init = function() require("lazy_loader").lazy_load("nvim-treesitter") end,
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    config = function() require("plugins.configs.treesitter").setup() end,
  },
  -- ansible support
  {
    "pearofducks/ansible-vim",
    -- FIX: not working with default config
    enabled = false,
  },
  -- refactoring
  {
    "ThePrimeagen/refactoring.nvim",
    keys = {
      {
        "<leader>cr",
        function() require("refactoring").select_refactor() end,
        mode = "v",
        noremap = true,
        silent = true,
        expr = false,
        desc = "Refactor"
      },
    },
    config = function() require("plugins.configs.refactoring").setup() end,
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
  },

  -- -------------------------------------
  -- LSP
  -- -------------------------------------
  -- easily config neovim lsp
  {
    "neovim/nvim-lspconfig",
    init = function() require("lazy_loader").lazy_load("nvim-lspconfig") end,
    config = function() require("plugins.configs.lspconfig").setup() end,
    dependencies = {
      -- ui for lsp features
      {
        "glepnir/lspsaga.nvim",
        keys = {
          {
            "]e",
            "<cmd>Lspsaga diagnostic_jump_next<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga diagnostic go to next (F2)",
          },
          {
            "<F2>",
            "<cmd>Lspsaga diagnostic_jump_next<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga diagnostic go to next (F2)",
          },
          {
            "[e",
            "<cmd>Lspsaga diagnostic_jump_prev<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga diagnostic go to previous (Shift+F2)",
          },
          {
            "<F14>",
            "<cmd>Lspsaga diagnostic_jump_prev<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga diagnostic go to previous (Shift+F2)",
          },
          {
            "[E",
            function() require("lspsaga.diagnostic"):goto_prev({ severity = vim.diagnostic.severity.ERROR }) end,
            noremap = true,
            silent = true,
            desc = "Lspsaga diagnostic go to previous ERROR",
          },
          {
            "]E",
            function() require("lspsaga.diagnostic"):goto_next({ severity = vim.diagnostic.severity.ERROR }) end,
            noremap = true,
            silent = true,
            desc = "Lspsaga diagnostic go to next ERROR",
          },
          {
            "<leader>ce",
            "<cmd>Lspsaga show_line_diagnostics<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga diagnostic show message (Ctrl+F1)",
          },
          {
            "<F25>",
            "<cmd>Lspsaga show_line_diagnostics<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga diagnostic show message (Ctrl+F1)",
          },
          {
            "<leader>ch",
            "<cmd>Lspsaga hover_doc<cr>",
            noremap = true,
            silent = true,
            desc = "LSP show hovering help (Shift+k)",
          },
          {
            "<S-k>",
            "<cmd>Lspsaga hover_doc<cr>",
            noremap = true,
            silent = true,
            desc = "LSP show hovering help (Shift+k)",
          },
          {
            "<leader>cc",
            "<cmd>Lspsaga finder<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga definition and usage finder (Cltr+Alt+7)",
          },
          {
            "<M-&>",
            "<cmd>Lspsaga finder<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga definition and usage finder (Ctrl+Alt+7)",
          },
          -- NOTE: does not work for going into third party dependencies => use the one from Telescope
          -- {
          --   "<leader>cd",
          --   "<cmd>Lspsaga goto_definition<cr>",
          --   noremap = true,
          --   silent = true,
          --   desc = "Lspsaga go to definition (Ctrl+b)",
          -- },
          -- {
          --   "<C-b>",
          --   "<cmd>Lspsaga goto_definition<cr>",
          --   noremap = true,
          --   silent = true,
          --   desc = "Lspsaga go to definition (Ctrl+b)",
          -- },
          {
            "<leader>cD",
            "<cmd>Lspsaga peek_definition<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga peek definition",
          },
          {
            "<leader>ct",
            "<cmd>Lspsaga goto_type_definition<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga goto type definition",
          },
          {
            "<leader>cT",
            "<cmd>Lspsaga peek_type_definition<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga peek type definition",
          },
          {
            "<leader>ci",
            "<cmd>Lspsaga incoming_calls<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga incoming calls",
          },
          {
            "<leader>co",
            "<cmd>Lspsaga outgoing_calls<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga outgoing calls",
          },
          {
            "<leader>cm",
            "<cmd>Lspsaga outline<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga outline minimap (Ctrl+F12)",
          },
          {
            "<F36>",
            "<cmd>Lspsaga outline<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga outline minimap (Ctrl+F12)",
          },
          {
            "<leader>cr",
            "<cmd>Lspsaga rename ++project<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga rename (Shift+F6)",
          },
          {
            "<F18>",
            "<cmd>Lspsaga rename ++project<cr>",
            noremap = true,
            silent = true,
            desc = "Lspsaga rename (Shift+F6)",
          },
          {
            "<leader>cE",
            "<cmd>Lspsaga show_buf_diagnostics<cr>",
            noremap = true,
            silent = true,
            desc = "LSP show errors",
          },
          {
            "<leader>ca",
            "<cmd>Lspsaga code_action<cr>",
            noremap = true,
            silent = true,
            desc = "LSP code action (Alt+Enter)",
          },
          {
            "<M-CR>",
            "<cmd>Lspsaga code_action<cr>",
            noremap = true,
            silent = true,
            desc = "LSP code action (Alt+Enter)",
          },
          {
            "<leader>cb",
            "<cmd>Lspsaga finder imp<cr>",
            noremap = true,
            silent = true,
            desc = "Goto implementation",
          },
          {
            "<M-C-B>",
            "<cmd>Lspsaga finder imp<cr>",
            noremap = true,
            silent = true,
            desc = "Goto implementation (Ctrl+Alt+b)",
          },
        },
        config = function() require("plugins.configs.lspsaga").setup() end,
      },
      -- lsp progress eye candy
      {
        "j-hui/fidget.nvim",
        config = function() require("plugins.configs.fidget").setup() end,
        tag = "legacy",
      },
    },
  },
  -- java support
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
  },
  -- lua support
  {
    "folke/neodev.nvim",
    ft = "lua",
    config = function() require("plugins.configs.neodev").setup() end,
  },
  -- easily install/update lsp servers directly from neovim
  {
    "williamboman/mason.nvim",
    keys = {
      { "<leader>vm", "<cmd>Mason<cr>", noremap = true, desc = "Open Mason" }
    },
    cmd = { "Mason", "MasonInstall", "MasonInstallAll", "MasonUninstall", "MasonUninstallAll", "MasonLog" },
    config = function() require("plugins.configs.mason").setup() end,
  },

  -- -------------------------------------
  -- DAP
  -- -------------------------------------
  -- debugger engine
  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<F9>",
        "<Cmd>lua require('dap').continue()<cr>",
        noremap = true,
        silent = true,
        desc = "Begin debug session (F9)"
      },
      {
        "<leader>db",
        "<Cmd>lua require('dap').continue()<cr>",
        noremap = true,
        silent = true,
        desc = "Begin debug session (F9)"
      },
      {
        "<F4>",
        "<Cmd>lua require('dap').close()<cr>",
        noremap = true,
        silent = true,
        desc = "End debug session (F4)"
      },
      {
        "<leader>de",
        "<Cmd>lua require('dap').close()<cr>",
        noremap = true,
        silent = true,
        desc = "End debug session (F4)"
      },
      {
        "<F32>",
        "<Cmd>lua require('dap').toggle_breakpoint()<cr>",
        noremap = true,
        silent = true,
        desc = "Toggle breakpoint (Ctrl+F8)"
      },
      {
        "<leader>dt",
        "<Cmd>lua require('dap').toggle_breakpoint()<cr>",
        noremap = true,
        silent = true,
        desc = "Toggle breakpoint (Ctrl+F8)"
      },
      {
        "<F8>",
        "<Cmd>lua require('dap').step_over()<cr>",
        noremap = true,
        silent = true,
        desc = "Step over (F8)"
      },
      {
        "<leader>dv",
        "<Cmd>lua require('dap').step_over()<cr>",
        noremap = true,
        silent = true,
        desc = "Step over (F8)"
      },
      {
        "<F7>",
        "<Cmd>lua require('dap').step_into()<cr>",
        noremap = true,
        silent = true,
        desc = "Step into (F7)"
      },
      {
        "<leader>di",
        "<Cmd>lua require('dap').step_into()<cr>",
        noremap = true,
        silent = true,
        desc = "Step into (F7)"
      },
      {
        "<F20>",
        "<Cmd>lua require('dap').step_out()<cr>",
        noremap = true,
        silent = true,
        desc = "Step out (Shift+F8)"
      },
      {
        "<leader>do",
        "<Cmd>lua require('dap').step_out()<cr>",
        noremap = true,
        silent = true,
        desc = "Step out (Shift+F8)"
      },
    },
    config = function() require("plugins.configs.dap").setup() end,
    dependencies = {
      -- dap ui
      {
        "rcarriga/nvim-dap-ui",
        keys = {
          {
            "<M-5>",
            "<cmd>lua require('dapui').toggle({ reset = true })<cr>",
            desc = "Open DAP UI (Alt+5)",
          },
          {
            "<leader>du",
            "<cmd>lua require('dapui').toggle({ reset = true })<cr>",
            desc = "Open DAP UI (Alt+5)",
          },
          {
            "<leader>da",
            "<cmd>lua require('dapui').eval()<cr>",
            silent = true,
            desc = "Evaluate",
          },
          {
            "<leader>df",
            "<cmd>lua require('dapui').float_element()<cr>",
            noremap = true,
            silent = true,
            desc = "Float element",
          },
        },
        config = function() require("plugins.configs.dap-ui").setup() end,
      },
      -- autocompletion for DAP
      {
        "rcarriga/cmp-dap",
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
      },
    },
  },

  -- -------------------------------------
  -- AUTOCOMPLETION
  -- -------------------------------------
  -- autocompletion engine
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    config = function() require("plugins.configs.cmp").setup() end,
    dependencies = {
      -- snippet engine
      {
        "L3MON4D3/LuaSnip",
        config = function() require("plugins.configs.luasnip").setup() end,
        dependencies = { "rafamadriz/friendly-snippets", "honza/vim-snippets" },
      },
      -- autoclose pairs, (), []...
      {
        "windwp/nvim-autopairs",
        config = function() require("plugins.configs.autopairs").setup() end,
      },
      -- add pictograms to cmp
      "onsails/lspkind.nvim",
      -- cmp sources plugins
      {
        -- lsp based
        "hrsh7th/cmp-nvim-lsp",
        -- buffer based
        "hrsh7th/cmp-buffer",
        -- filepath based
        "hrsh7th/cmp-path",
        -- command based
        "hrsh7th/cmp-cmdline",
        -- autocompletion on lsp function/class signature
        "hrsh7th/cmp-nvim-lsp-signature-help",
        -- lua support
        "hrsh7th/cmp-nvim-lua",
        "saadparwaiz1/cmp_luasnip",
        -- emoji support
        "hrsh7th/cmp-emoji",
        -- omni
        "hrsh7th/cmp-omni",
        -- autocompletion from tmux panes
        "andersevenrud/cmp-tmux",
        -- buffer lines based
        "amarakon/nvim-cmp-buffer-lines",
      }
    },
  },
  -- the missing auto-completion for cmdline!
  {
    "gelguy/wilder.nvim",
    event = "CmdlineEnter",
    config = function() require("plugins.configs.wilder").setup() end,
  },

  -- -------------------------------------
  -- NAVIGATION
  -- -------------------------------------
  -- file explorer
  {
    "nvim-tree/nvim-tree.lua",
    keys = {
      { "<A-1>", "<cmd>NvimTreeToggle<cr>",         desc = "Toggle NvimTree (Alt+1)", },
      { "<A-3>", "<cmd>NvimTreeFindFileToggle<cr>", desc = "Toggle NvimTree & focus on current file (Alt+3)" },
    },
    config = function() require("plugins.configs.tree").setup() end,
  },
  -- multilevel undo explorer
  {
    "mbbill/undotree",
    keys = {
      { "<leader>u", "<cmd>UndotreeToggle<cr>", noremap = true, desc = "Undotree Toggle" },
    },
  },
  -- fuzzy finding anything anywhere
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    init = function() require("plugins.configs.telescope").attach_keymaps() end,
    config = function() require("plugins.configs.telescope").setup() end,
    dependencies = {
      -- telescope extension to telescope as selection ui instead of vim command line
      "nvim-telescope/telescope-ui-select.nvim",
      -- telescope extension for luasnip snippet
      "benfowler/telescope-luasnip.nvim",
      -- telescope dap
      "nvim-telescope/telescope-dap.nvim",
    },
  },
  -- navigate your code with search labels, enhanced character motions and Treesitter integration
  {
    "folke/flash.nvim",
    keys = {
      {
        "s",
        function() require("flash").jump() end,
        mode = { "n", "x", "o" },
        noremap = true,
        silent = true,
        desc = "Flash",
      },
      {
        "<leader>nf",
        function() require("flash").jump() end,
        mode = { "n", "x", "o" },
        noremap = true,
        silent = true,
        desc = "Flash (or use s)",
      },
      {
        "S",
        function() require("flash").treesitter() end,
        mode = { "n", "o", "x" },
        noremap = true,
        silent = true,
        desc = "Flash treesitter",
      },
      {
        "<leader>nt",
        function() require("flash").treesitter() end,
        mode = { "n", "o", "x" },
        noremap = true,
        silent = true,
        desc = "Flash treesitter (or use S)",
      },
      {
        "r",
        function() require("flash").remote() end,
        mode = { "o" },
        noremap = true,
        silent = true,
        desc = "Remote Flash",
      },
      {
        "R",
        function() require("flash").treesitter_search() end,
        mode = { "o", "x" },
        noremap = true,
        silent = true,
        desc =
        "Treesitter Search"
      },
      {
        "<C-s>",
        function() require("flash").toggle() end,
        mode = { "c" },
        noremap = true,
        silent = true,
        desc = "Toggle Flash Search",
      },
    },
    config = function() require("plugins.configs.flash").setup() end,
  },
  -- file explorer to edit filesystem like a normal buffer, vim-vinegar like
  {
    "stevearc/oil.nvim",
    keys = {
      { "<leader>no", function() require("oil").open() end, desc = "Oil open current directory" },
    },
    config = function() require("oil").setup() end,
  },
  -- navigate between neovim and multiplexers
  {
    "numToStr/Navigator.nvim",
    keys = {
      { "<C-h>", "<cmd>NavigatorLeft<cr>",  mode = { "n", "t" }, noremap = true, silent = true, desc = "Navigate left" },
      { "<C-l>", "<cmd>NavigatorRight<cr>", mode = { "n", "t" }, noremap = true, silent = true, desc = "Navigate right" },
      { "<C-k>", "<cmd>NavigatorUp<cr>",    mode = { "n", "t" }, noremap = true, silent = true, desc = "Navigate up" },
      { "<C-j>", "<cmd>NavigatorDown<cr>",  mode = { "n", "t" }, noremap = true, silent = true, desc = "Navigate down" },
    },
    config = function() require("Navigator").setup() end,
  },
  -- -------------------------------------
  -- GIT
  -- -------------------------------------
  -- git integration
  {
    "tpope/vim-fugitive",
    keys = {
      { "<leader>gs", "<cmd>G<cr>",                         desc = "git status" },
      { "<leader>gc", "<cmd>G commit<cr>",                  desc = "git commit" },
      { "<leader>gp", "<cmd>G pull<cr>",                    desc = "git pull" },
      { "<leader>gP", "<cmd>G push<cr>",                    desc = "git push" },
      { "<leader>gF", "<cmd>G push --force-with-lease<cr>", desc = "git push --force-with-lease" },
      { "<leader>gb", "<cmd>G blame<cr>",                   desc = "git blame" },
      { "<leader>gl", "<cmd>0GcLog<cr>",                    desc = "git log" },
    },
    config = function() require("plugins.configs.fugitive").setup() end,
  },
  -- git modifications explorer/handler
  {
    "lewis6991/gitsigns.nvim",
    init = function() require("plugins.configs.gitsigns").init() end,
    config = function() require("plugins.configs.gitsigns").setup() end,
  },
  -- nice view for git diff
  {
    "sindrets/diffview.nvim",
    keys = {
      {
        "<leader>gd",
        "<cmd>DiffviewFileHistory %<cr>",
        noremap = true,
        silent = true,
        desc =
        "Check file git history (Alt+0)"
      },
      -- FIX: calling DiffviewOpen will make file saving behaving weirdly, i.e. always opening the file diffview
      { "<A-0>", "<cmd>DiffviewOpen<cr>", noremap = true, silent = true, desc = "Open diffView (Alt+0)" },
    },
    config = function() require("plugins.configs.diffview").setup() end,
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- -------------------------------------
  -- MISC
  -- -------------------------------------
  -- show available keymaps + description as you type them
  {
    "folke/which-key.nvim",
    keys = { "<leader>", '"', "'", "`", "c", "v", "g" },
    config = function() require("plugins.configs.which-key").setup() end,
  },
  -- open to last known cursor position
  {
    "ethanholz/nvim-lastplace",
    event = "VeryLazy",
    config = function() require("nvim-lastplace").setup() end,
  },
  -- session management
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    keys = {
      {
        "<leader>ss",
        "<cmd>lua require('persistence').load()<cr>",
        noremap = true,
        silent = true,
        desc = "Restore session for current directory",
      },
      {
        "<leader>sl",
        "<cmd>lua require('persistence').load({ last = true})<cr>",
        noremap = true,
        silent = true,
        desc = "Restore last session",
      },
      {
        "<leader>sd",
        "<cmd>lua require('persistence').stop()<cr>",
        noremap = true,
        silent = true,
        desc = "Stop persistence",
      },
    },
    config = function() require("persistence").setup() end,
  },
  -- dashboard
  {
    "glepnir/dashboard-nvim",
    event = "VimEnter",
    config = function() require("plugins.configs.dashboard").setup() end,
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  -- project
  {
    "ahmedkhalf/project.nvim",
    event = "VeryLazy",
    config = function() require("project_nvim").setup() end,
  },
}

require("plugins.configs.lazy").setup(plugins)
