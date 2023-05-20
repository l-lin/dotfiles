local ensure_packer = function()
  local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
  if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()
return require('packer').startup(function(use)
  -- package manager
  use { 'wbthomason/packer.nvim' }

  -- -------------------------------------
  -- GUI
  -- -------------------------------------
  -- colorscheme
  use { "ellisonleao/gruvbox.nvim" }

  -- filetype icons
  use { 'nvim-tree/nvim-web-devicons', config = function() require('plugins.web-devicons') end }
  -- display marks
  use { 'kshenoy/vim-signature' }
  -- status line (bottom)
  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'nvim-tree/nvim-web-devicons', opt = true },
    event = 'VimEnter',
    config = function() require('plugins.lualine') end
  }
  -- buffer line (top)
  use {
    'akinsho/bufferline.nvim',
    tag = "v3.*",
    requires = 'nvim-tree/nvim-web-devicons',
    event = 'VimEnter',
    config = function() require('plugins.bufferline') end
  }

  -- -------------------------------------
  -- EDITOR
  -- -------------------------------------
  -- surround parenthese
  use { 'machakann/vim-sandwich' }
  -- autoclose pairs, (), []...
  use { 'windwp/nvim-autopairs', config = function() require('nvim-autopairs').setup {} end }
  -- syntax aware commenting
  use { 'numToStr/Comment.nvim', config = function() require('plugins.comment') end }
  -- a pretty list for diagnostics
  use {
    'folke/trouble.nvim',
    requires = 'nvim-tree/nvim-web-devicons',
    event = 'VimEnter',
    config = function() require('plugins.trouble') end
  }
  -- multiple cursors
  use { 'mg979/vim-visual-multi', config = function() require('plugins.visual-multi') end }
  -- handle trailing whitespace
  use { 'ntpeters/vim-better-whitespace', config = function() require('plugins.better-whitespace') end }
  -- automatically manage hlsearch
  use { 'asiryk/auto-hlsearch.nvim', config = function() require('auto-hlsearch').setup() end }
  -- better glance at matched information
  use { 'kevinhwang91/nvim-hlslens', config = function() require('plugins.hlslens') end }
  -- search and replace
  use { 'windwp/nvim-spectre', config = function() require('plugins.spectre') end }
  -- markdown table
  use { 'dhruvasagar/vim-table-mode' }

  -- -------------------------------------
  -- DEV
  -- -------------------------------------
  -- enhanced syntax by treesitter
  use { 'nvim-treesitter/nvim-treesitter', config = function() require('plugins.treesitter') end }
  -- show lightbulb for code hints
  use {
    'kosayoda/nvim-lightbulb',
    requires = 'antoinemadec/FixCursorHold.nvim',
    config = function() require('plugins.lightbulb') end
  }
  -- lua support
  use { 'folke/neodev.nvim' }
  -- ansible support
  use { 'pearofducks/ansible-vim' }
  -- refactoring
  use {
    'ThePrimeagen/refactoring.nvim',
    requires = { { 'nvim-lua/plenary.nvim' }, { 'nvim-treesitter/nvim-treesitter' } },
    config = function() require('plugins.refactoring') end
  }

  -- -------------------------------------
  -- LSP
  -- -------------------------------------
  -- easily config neovim lsp
  use { 'neovim/nvim-lspconfig', config = function() require('plugins.lspconfig') end }
  -- easily install/update lsp servers directly from neovim
  use {
    'williamboman/mason.nvim',
    requires = 'neovim/nvim-lspconfig',
    config = function() require('plugins.mason') end
  }
  -- bridge between mason and nvim-lspconfig
  use {
    'williamboman/mason-lspconfig',
    requires = 'williamboman/mason.nvim',
    config = function() require('plugins.mason-lspconfig') end
  }

  -- -------------------------------------
  -- DAP
  -- -------------------------------------
  -- debugger engine
  use { 'mfussenegger/nvim-dap', config = function() require('plugins.dap') end }
  -- dap ui
  use { 'rcarriga/nvim-dap-ui', requires = 'mfussenegger/nvim-dap', config = function() require('plugins.dap-ui') end }
  -- autocompletion for DAP
  use { 'rcarriga/cmp-dap', requires = 'hrsh7th/nvim-cmp' }

  -- -------------------------------------
  -- AUTOCOMPLETION
  -- -------------------------------------
  -- add pictograms to cmp
  use { 'onsails/lspkind.nvim' }
  -- autocompletion engine
  use {
    'hrsh7th/nvim-cmp',
    requires = { 'L3MON4D3/LuaSnip', 'onsails/lspkind.nvim' },
    config = function() require('plugins.cmp') end
  }
  -- lsp based
  use { 'hrsh7th/cmp-nvim-lsp' }
  -- buffer based
  use { 'hrsh7th/cmp-buffer' }
  -- filepath based
  use { 'hrsh7th/cmp-path' }
  -- command based
  use { 'hrsh7th/cmp-cmdline' }
  -- autocompletion on lsp function/class signature
  use { 'hrsh7th/cmp-nvim-lsp-signature-help' }
  -- lua support
  use { 'hrsh7th/cmp-nvim-lua' }
  -- emoji support
  use { 'hrsh7th/cmp-emoji' }
  -- omni
  use { 'hrsh7th/cmp-omni' }
  -- autocompletion from tmux panes
  use { 'andersevenrud/cmp-tmux' }

  -- snippet engine
  use { 'L3MON4D3/LuaSnip', config = function() require('plugins.luasnip') end }
  -- buffer lines based
  use { 'amarakon/nvim-cmp-buffer-lines' }
  -- snippets collection
  use { 'honza/vim-snippets' }
  use { 'rafamadriz/friendly-snippets' }
  -- luasnip snippets
  use { 'saadparwaiz1/cmp_luasnip' }

  -- lsp progress eye candy
  use { 'j-hui/fidget.nvim', config = function() require('fidget').setup {} end }

  -- -------------------------------------
  -- NAVIGATION
  -- -------------------------------------
  -- file explorer
  use { 'nvim-tree/nvim-tree.lua', config = function() require('plugins.tree') end }
  -- multilevel undo explorer
  use { 'mbbill/undotree', config = function() require('plugins.undotree') end }
  -- fuzzy finding anything anywhere
  use {
    'nvim-telescope/telescope.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
    config = function() require('plugins.telescope') end
  }
  -- telescope extension to use telescope as selection ui instead of vim command line
  use { 'nvim-telescope/telescope-ui-select.nvim' }
  -- telescope extension for file browser
  use { 'nvim-telescope/telescope-file-browser.nvim' }
  -- telescope project finder
  use { 'nvim-telescope/telescope-project.nvim' }
  -- telescope extension for luasnip snippet
  use { 'benfowler/telescope-luasnip.nvim', requires = { 'L3MON4D3/LuaSnip' } }
  -- general-purpose motion plugin
  use { 'ggandor/leap.nvim', event = 'VimEnter', config = function() require('plugins.leap') end }
  -- file explorer to edit filesystem like a normal buffer, vim-vinegar like
  use { 'stevearc/oil.nvim', config = function() require('plugins.oil') end }

  -- -------------------------------------
  -- GIT
  -- -------------------------------------
  -- git integration
  use { 'tpope/vim-fugitive', config = function() require('plugins.fugitive') end }
  -- git modifications explorer/handler
  use { 'lewis6991/gitsigns.nvim', config = function() require('plugins.gitsigns') end }
  -- nice view for git diff
  use {
    'sindrets/diffview.nvim',
    requires = 'nvim-lua/plenary.nvim',
    config = function() require('plugins.diffview') end
  }

  -- -------------------------------------
  -- MISC
  -- -------------------------------------
  -- show available keymaps + description as you type them
  use { 'folke/which-key.nvim', event = 'VimEnter', config = function() require('plugins.which-key') end }
  -- open to last known cursor position
  use { 'ethanholz/nvim-lastplace', config = function() require('nvim-lastplace').setup() end }

  -- the missing auto-completion for cmdline!
  use { 'gelguy/wilder.nvim', config = function() require('plugins.wilder') end }

  -- -------------------------------------
  -- Automatically set up your configuration after cloning packer.nvim
  if packer_bootstrap then
    require('packer').sync()
  end
end)
