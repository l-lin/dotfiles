local o = vim.o
local cmd = vim.cmd

-- tab and space
o.tabstop = 2
o.shiftwidth = o.tabstop
o.expandtab = true -- use the appropriate number of spaces to insert a <Tab> in insert mode
o.list = true -- display tab
o.nojoinspaces = true -- use one space, not two, after punctuation
o.smartindent = true -- do smart autoindenting when starting a new line

-- copy yank
o.autoindent = true -- copy indent from current line when starting a new line
cmd [[ set clipboard=unnamedplus ]] -- yank in clipboard

-- search
o.hlsearch = true -- highlight searched-for phrases
o.incsearch = true -- but do highlight-as-I-type the search string
o.ignorecase = true -- makes pattern matching case-insensitive
o.smartcase = true -- overrides ignorecase if your pattern contains mixed case
o.gdefault = true -- this makes search/replace global by default"

-- encoding
o.encoding = "utf-8" -- change how nvim represents characters on the screen
o.fileencoding = "utf-8" -- set the encoding of files written

-- backup
o.nobackup = true -- turn backup off, since most stuff is versioned anyway
o.nowb = true
o.noswapfile = true
o.nowritebackup = true -- some servers have issues with backup files, see #649
o.undofile = true -- enable persistent undo
cmd [[ set undodir=~/.undodir ]] -- where to save undo histories

-- spell checking
o.spelllang = "en"
o.spell = false -- by default, do not spell check

-- responsiveness
o.updatetime = 300 -- shorter updatetime for better user exp (default: 4000ms)
o.timeout = true
o.timeoutlen = 100 -- default 1000ms

-- misc
o.showcmd = true -- display incomplete commands
o.showmode = true -- show insert mode in command line
o.so = 7 -- set 7 lines to the cursor when moving vertically
o.hidden = true -- TextEdit might fail if hidden is not set
o.splitbelow = true --default split below
o.splitright = true --default split right
o.laststatus = 3 -- always show statusline in single statusline mode
o.autoread = true -- refresh file if it changes on disc
o.confirm = true -- ask me if I try to leave the editor with an unsaved modified file in a buffer
o.cursorline = true -- highlight line
cmd [[ set shortmess+=c ]] -- don't pass messages to |ins-completion-menu|
cmd [[ au TextYankPost * silent! lua vim.highlight.on_yank{higroup="IncSearch", timeout=300} ]] -- highlight yank

