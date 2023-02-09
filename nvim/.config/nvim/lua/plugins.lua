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

  -- min config
  use { 'tpope/vim-sensible' }

  -- -------------------------------------
  -- GUI
  -- -------------------------------------
  -- colorscheme
  use { 'luisiacc/gruvbox-baby', config = function() require('plugins.gruvbox') end }
  -- filetype icons
  use { 'kyazdani42/nvim-web-devicons', config = function() require('plugins.web-devicons') end }
  -- zen mode
  use { 'Pocco81/true-zen.nvim', config = function() require('plugins.true-zen') end }
  -- dim interactive portions of code you are editing
  use { 'folke/twilight.nvim', config = function() require('twilight').setup() end }
  -- display marks
  use { 'kshenoy/vim-signature' }
  -- status line (bottom)
  use { 'nvim-lualine/lualine.nvim', requires = { 'kyazdani42/nvim-web-devicons', opt = true }, config = function() require('plugins.lualine') end }
  -- buffer line (top)
  use { 'akinsho/bufferline.nvim', tag = "v3.*", requires = 'kyazdani42/nvim-web-devicons', config = function() require('plugins.bufferline') end }
  -- display bottom status bar
  --use { 'vim-airline/vim-airline', config = function() require('plugins.airline') end }
  --use { 'vim-airline/vim-airline-themes' }

  -- -------------------------------------
  -- EDITOR
  -- -------------------------------------
  -- smooth scrolling
  use { 'psliwka/vim-smoothie' }
  -- surround parenthese
  use { 'tpope/vim-surround' }
  -- autoclose pairs, (), []...
  use { 'windwp/nvim-autopairs', config = function() require('nvim-autopairs').setup {} end }
  -- syntax aware commenting
  use { 'numToStr/Comment.nvim', config = function() require('Comment').setup() end }
  -- set commentstring option based on the cursor location in the file.
  -- TODO: set keymap
  use { 'JoosepAlviste/nvim-ts-context-commentstring' }
  -- a pretty list for diagnostics
  use { 'folke/trouble.nvim', requires = 'nvim-tree/nvim-web-devicons', config = function() require('plugins.trouble') end }
  -- linting
  use { 'dense-analysis/ale', config = function() require('plugins.ale') end }
  -- multiple cursors
  use { 'mg979/vim-visual-multi', config = function() require('plugins.visual-multi') end }
  -- handle trailing whitespace
  use { 'ntpeters/vim-better-whitespace', config = function() require('plugins.better-whitespace') end }
  -- autoformat
  --use { 'Chiel92/vim-autoformat', config = function() require('plugins.autoformat') end }

  -- -------------------------------------
  -- DEV
  -- -------------------------------------
  -- enhanced syntax by treesitter
  use { 'nvim-treesitter/nvim-treesitter', config = function() require('plugins.treesitter') end }
  -- show lightbulb for code hints
  use { 'kosayoda/nvim-lightbulb', requires = 'antoinemadec/FixCursorHold.nvim' }
  -- easily install/update lsp servers directly from neovim
  -- TODO: how to check documentation
  use { 'williamboman/mason.nvim', config = function() require('mason').setup {} end }
  -- bridge between mason and nvim-lspconfig
  use { 'williamboman/mason-lspconfig', config = function() require('mason-lspconfig').setup {} end }
  -- lua support
  use { 'folke/neodev.nvim' }
  -- terraform support
  use { 'hashivim/vim-terraform' }
  -- ansible support
  use { 'pearofducks/ansible-vim' }
  -- markdown support
  use { 'plasticboy/vim-markdown', config = function() require('plugins.markdown') end }

  -- -------------------------------------
  -- AUTOCOMPLETION
  -- -------------------------------------
  -- autocompletion engine
  use { 'hrsh7th/nvim-cmp', requires = { 'L3MON4D3/LuaSnip' }, config = function() require('plugins.cmp') end }
  -- snippet engine
  use { 'L3MON4D3/LuaSnip', config = function() require('plugins.luasnip') end }
  -- lsp progress eye candy
  use { 'j-hui/fidget.nvim', config = function() require('fidget').setup {} end }
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
  -- autocompletion from tmux panes
  use { 'andersevenrud/cmp-tmux' }
  -- luasnip snippets
  use { 'saadparwaiz1/cmp_luasnip' }

  -- -------------------------------------
  -- NAVIGATION
  -- -------------------------------------
  -- file explorer
  use { 'kyazdani42/nvim-tree.lua', config = function() require('plugins.tree') end }
  -- multilevel undo explorer
  use { 'mbbill/undotree', config = function() require('plugins.undotree') end }
  -- fuzzy finding anything anywhere
  use { 'nvim-telescope/telescope.nvim', requires = { 'nvim-lua/plenary.nvim' }, config = function() require('plugins.telescope') end }
  -- telescope extension to use telescope as selection ui instead of vim command line
  -- TODO: how to use it?
  use { 'nvim-telescope/telescope-ui-select.nvim' }
  -- telescope extension file browser
  -- TODO: how to use it?
  use { 'nvim-telescope/telescope-file-browser.nvim' }
  -- general-purpose motion plugin
  use { 'ggandor/leap.nvim', config = function() require('plugins.leap') end }

  -- -------------------------------------
  -- GIT
  -- -------------------------------------
  -- git integration
  use { 'tpope/vim-fugitive', config = function() require('plugins.fugitive') end }
  -- show git diff in the gutter
  use { 'airblade/vim-gitgutter' }
  -- nice view for git diff
  -- TODO: how to use it?
  use { 'sindrets/diffview.nvim', requires = 'nvim-lua/plenary.nvim', config = function() require('plugins.diffview') end }

  -- -------------------------------------
  -- MISC
  -- -------------------------------------
  -- show available keymaps + description as you type them
  use { 'folke/which-key.nvim', config = function() require('plugins.which-key') end }
  -- open to last known cursor position
  use { 'ethanholz/nvim-lastplace', config = function() require('nvim-lastplace').setup() end }
  -- caching init to improve starting time
  use { 'lewis6991/impatient.nvim' }
  -- embed neovim on the browser
  --use { 'glacambre/firenvim', run = function() vim.fn['firenvim#install'](0) end, config = function() require('plugins.firenvim') end }

  -- -------------------------------------
  -- Automatically set up your configuration after cloning packer.nvim
  if packer_bootstrap then
      require('packer').sync()
  end
end)
