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
  use { 'ellisonleao/gruvbox.nvim', config = function() require('plugins.gruvbox') end }
  -- filetype icons
  use { 'kyazdani42/nvim-web-devicons', config = function() require('plugins.nvim-web-devicons') end }
  -- zen mode
  use { 'Pocco81/true-zen.nvim', config = function() require('plugins.true-zen') end }
  -- dim interactive portions of code you are editing
  use { 'folke/twilight.nvim', config = function() require('twilight').setup() end }
  -- display bottom status bar
  use { 'vim-airline/vim-airline', config = function() require('plugins.airline') end }
  use { 'vim-airline/vim-airline-themes' }
  -- display marks
  use { 'kshenoy/vim-signature' }

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
  use { 'dense-analysis/ale' }
  -- grammar checker
  use { 'rhysd/vim-grammarous' }
  -- autoformat
  --use { 'Chiel92/vim-autoformat', config = function() require('plugins.autoformat') end }

  -- -------------------------------------
  -- DEV
  -- -------------------------------------
  -- enhanced syntax by treesitter
  use { 'nvim-treesitter/nvim-treesitter', config = function() require('plugins.treesitter') end } 
  -- show lightbulb for code hints
  use { 'kosayoda/nvim-lightbulb', requires = 'antoinemadec/FixCursorHold.nvim' }
  -- lsp progress eye candy
  use { 'j-hui/fidget.nvim', config = function() require('fidget').setup {} end }
  -- terraform support
  use { 'hashivim/vim-terraform' }
  -- init.lua syntax awareness and completion
  --use { 'folke/neodev.nvim', config = function() require('neodev').setup({ library = { plugins = { 'nvim-dap-ui" }, types = true }, }) end } 

  -- -------------------------------------
  -- NAVIGATION
  -- -------------------------------------
  -- file explorer
  use { 'kyazdani42/nvim-tree.lua', config = function() require('plugins.nvim-tree') end }
  -- multilevel undo explorer
  use { 'mbbill/undotree', config = function() require('plugins.undotree') end }
  -- fuzzy finding anything anywhere
  -- TODO: set keymap
  use { 'nvim-telescope/telescope.nvim', requires = { 'nvim-lua/plenary.nvim' }, config = function() require('plugins.telescope') end }

  -- -------------------------------------
  -- GIT
  -- -------------------------------------
  -- git integration
  use { 'tpope/vim-fugitive', config = function() require('plugins.fugitive') end }
  -- show git diff in the gutter
  use { 'airblade/vim-gitgutter' }

  -- -------------------------------------
  -- MISC
  -- -------------------------------------
  -- show available keymaps + description as you type them
  use { 'folke/which-key.nvim', config = function() require('plugins.which-key') end }
  -- embed neovim on the browser
  use { 'glacambre/firenvim', run = function() vim.fn['firenvim#install'](0) end, config = function() require('plugins.firenvim') end }
  -- open to last known cursor position
  use { 'ethanholz/nvim-lastplace', config = function() require('nvim-lastplace').setup() end }
  -- caching init to improve starting time
  use { 'lewis6991/impatient.nvim' }

  -- -------------------------------------
  -- Automatically set up your configuration after cloning packer.nvim
  if packer_bootstrap then
      require('packer').sync()
  end
end)
