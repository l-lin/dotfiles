" Basic editing configuration                                   vimrcbasic 
" VIM user interface                                            vimrcui
" Files, backups and undo                                       vimrcbackup
" Key maps                                                      vimrckeymaps
" Cursor shape                                                  vimrccursor
" Colors                                                        vimrccolors
" VIM-GO customization                                          vimrcgo
" Linting                                                       vimrclinting
" ncm2                                                          vimrcncm2
" Editorconfig                                                  vimrceditor
" Spell checking                                                vimrcspell
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Using https://github.com/junegunn/vim-plug as dependency manager
" Execute :PlugInstall
call plug#begin()
Plug 'tpope/vim-sensible' " VIM minimal config
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' } " Golang support
Plug 'w0rp/ale' " Linting
Plug 'SirVer/ultisnips' " Snippets
Plug 'honza/vim-snippets' " Snippets
Plug 'vim-airline/vim-airline' " Display the bottom status bar
Plug 'vim-airline/vim-airline-themes' " Themes for the airline
Plug 'plasticboy/vim-markdown' " Markdown support
Plug 'airblade/vim-gitgutter' " Show git diff in the gutter
Plug 'joshdick/onedark.vim' " VIM theme
Plug 'ctrlpvim/ctrlp.vim' " Open file directory directly with C-p + used for GoDecls
Plug 'scrooloose/nerdtree' " Tree explorer
Plug 'Xuyuanp/nerdtree-git-plugin' " Tree explorer with Git status
Plug 'easymotion/vim-easymotion' " Easily navigate through the file
Plug 'mbbill/undotree' " Undo history
" Neovim plugins
Plug 'roxma/nvim-yarp' " Remote plugin framework
Plug 'ncm2/ncm2' " Completion framework for NeoVim
Plug 'ncm2/ncm2-bufword' " Completion word from current buffer
Plug 'ncm2/ncm2-path' " Completion word for path
Plug 'ncm2/ncm2-tmux' " Completion for TMUX
Plug 'ncm2/ncm2-go' " Completion for Golang
Plug 'ncm2/ncm2-tern' " Completion for JS
Plug 'ncm2/ncm2-cssomni' " Completion for CSS
Plug 'rhysd/vim-grammarous' " Grammar checker
call plug#end()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Basic editing configuration                                   vimrcbasic 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set nocompatible
" Copy indent from current line when starting a new line
set autoindent
" Show line numbers
set number
" Do smart autoindenting when starting a new line
set smartindent
set tabstop=2
set shiftwidth=2
" Use the appropriate number of spaces to insert a <Tab> in insert mode
set expandtab
" Change how vim represents characters on the screen
set encoding=utf-8
" Set the encoding of files written
set fileencoding=utf-8
" Set leader
let mapleader=","
" Disable folding
let g:vim_markdown_folding_disabled=1
" Highlight line
set cursorline
" Ignore case
set ic
" snippets
let g:UltiSnipsSnippetDirectories=["UltiSnips", $HOME.'/.vim/UltiSnips']
" Wrap markdown files to 100 characters
au BufRead,BufNewFile *.md setlocal textwidth=100
" Use one space, not two, after punctuation.
set nojoinspaces
" display incomplete commands
set showcmd
" do incremental searching
set incsearch
" When editing a file, always jump to the last known cursor position.
" Don't do it for commit messages, when the position is invalid, or when
" inside an event handler (happens when dropping a file on gvim).
autocmd BufReadPost *
  \ if &ft != 'gitcommit' && line("'\"") > 0 && line("'\"") <= line("$") |
  \   exe "normal g`\"" |
  \ endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" VIM user interface                                            vimrcui
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set 7 lines to the cursor - when moving vertically using j/k
set so=7
" Close VIM if only window left is NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" Airline configuration
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='onedark'
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '>'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Files, backups and undo                                       vimrcbackup
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Turn backup off, since most stuff is in SVN, git etc anyway...
set nobackup
set nowb
set noswapfile
" Persistent undo
if has("persistent_undo")
    set undodir=$HOME/.undodir/
    set undofile
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Key maps                                                      vimrckeymaps
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Visual mode pressing * or # searches for the current selection
vnoremap <silent> * :call VisualSelection('f')<CR>
vnoremap <silent> # :call VisualSelection('b')<CR>
" Set ctrl-space behavior same as ctrl-n
inoremap <C-Space> <C-n>
" Switch back and forth from buffer
map ;; <C-^>
" Show/Hide line number
nmap <C-n> :set invnumber<CR>
" Go to definition
nmap <C-b> :GoDef<CR>
" Build & test
map <F9> :GoBuild<CR>
map <F8> :GoTest<CR>
" Close buffer
nmap <C-w> :bd<CR>
" Delete line
nmap <C-y> dd
" Press Space to toggle highlighting on/off, and show current value.
noremap <silent> <Space> :set hlsearch! hlsearch?<CR>
" Toggle auto-indenting for code paste
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
set showmode
" Add documentation
command Cheatsheet split ~/.vim/doc/cheat_sheet.txt
" Delete word after cursor
imap <C-d> <C-o>diw
" Pressing ,ss will toggle and untoggle spell checking
map <leader>ss :setlocal spell!<CR>
" Fast saving
nmap <leader>w :w!<CR>
" Fast quitting
nmap <leader>q :q<CR>
" Fast saving & quitting
nmap <leader>x :x<CR>
" Trigger snippet (also works with Ctrl+Enter)
let g:UltiSnipsExpandTrigger="<C-m>"
" Open NERDTree
nmap <leader>o :NERDTreeToggle<CR>
" move lines around
nnoremap <leader>k :m-2<cr>==
nnoremap <leader>j :m+<cr>==
xnoremap <leader>k :m-2<cr>gv=gv
xnoremap <leader>j :m'>+<cr>gv=gv
" Move around split windows
nmap <C-k> :wincmd k<CR>
nmap <C-j> :wincmd j<CR>
nmap <C-h> :wincmd h<CR>
nmap <C-l> :wincmd l<CR>
" Open undo history
nmap <leader>u :UndotreeToggle<CR> :UndotreeFocus<CR>
" Grammar check
nmap <leader>c :GrammarousCheck<CR>
" Move between linting errors
nnoremap <leader>r :ALENextWrap<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Cursor shape                                                  vimrccursor
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if has("autocmd")
  au VimEnter,InsertLeave * silent execute '!echo -ne "\e[1 q"' | redraw!
  au InsertEnter,InsertChange *
    \ if v:insertmode == 'i' | 
    \   silent execute '!echo -ne "\e[5 q"' | redraw! |
    \ elseif v:insertmode == 'r' |
    \   silent execute '!echo -ne "\e[3 q"' | redraw! |
    \ endif
  au VimLeave * silent execute '!echo -ne "\e[ q"' | redraw!
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Colors                                                        vimrccolors
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
syntax on
syntax enable
" Set onedark theme
colorscheme onedark
if (has("termguicolors"))
  set termguicolors
endif
" File type detection
filetype plugin on
" Omnicomplete
set omnifunc=syntaxcomplete#Complete
hi Pmenu ctermfg=153 ctermbg=NONE cterm=NONE guifg=#bcdbff guibg=NONE gui=NONE
hi PmenuSel ctermfg=NONE ctermbg=59 cterm=NONE guifg=NONE guibg=#3f4b52 gui=NONE

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" VIM-GO customization                                          vimrcgo
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Call goimports on save
let g:go_fmt_command = "goimports"
" Call vet, golint & errcheck on save
let g:go_metalinter_autosave = 1
" Syntax highlighting
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_build_constraints = 1
" Display var type info
" let g:go_auto_type_info = 1
" :GoAddTags should transform in camelCase
let g:go_addtags_transform = "camelcase"
" Use source code
let g:go_gocode_propose_source=1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Linting                                                       vimrclinting
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Error and warning signs.
let g:ale_sign_error = '⤫'
let g:ale_sign_warning = '⚠'
" Enable integration with airline.
let g:airline#extensions#ale#enabled = 1
" Keep sign in gutter open
let g:ale_sign_column_always = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ncm2                                                          vimrcncm2
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" enable ncm2 for all buffers
autocmd BufEnter * call ncm2#enable_for_buffer()
" IMPORTANT: :help Ncm2PopupOpen for more information
set completeopt=noinsert,menuone,noselect
" suppress the annoying 'match x of y', 'The only match' and 'Pattern not
" found' messages
set shortmess+=c
" When the <Enter> key is pressed while the popup menu is visible, it only
" hides the menu. Use this mapping to close the menu and also start a new
" line.
inoremap <expr> <C-j> pumvisible() ? "\<c-y>\<cr>" : "\<CR>"
" Use <TAB> to select the popup menu:
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" When the <Alt-*> is pressed while the popup menu is visible, perform
" the cursor reposition and set to mode normal
inoremap <expr> <A-h> pumvisible() ? "\<c-y>\<A-h>" : "\<A-h>"
inoremap <expr> <A-j> pumvisible() ? "\<c-y>\<A-j>" : "\<A-j>"
inoremap <expr> <A-k> pumvisible() ? "\<c-y>\<A-k>" : "\<A-k>"
inoremap <expr> <A-l> pumvisible() ? "\<c-y>\<A-l>" : "\<A-l>"
inoremap <expr> <A-o> pumvisible() ? "\<c-y>\<A-o>" : "\<A-o>"
inoremap <expr> <A-b> pumvisible() ? "\<c-y>\<A-b>" : "\<A-b>"
inoremap <expr> <A-u> pumvisible() ? "\<c-y>\<A-u>" : "\<A-u>"
inoremap <expr> <A-e> pumvisible() ? "\<c-y>\<A-e>" : "\<A-e>"
inoremap <expr> <A-$> pumvisible() ? "\<c-y>\<A-$>" : "\<A-$>"

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Editorconfig                                                  vimrceditor
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Language: SQL
au FileType sql set expandtab
au FileType sql set shiftwidth=2
au FileType sql set softtabstop=2
au FileType sql set tabstop=2
" Language: JSON
au FileType json set expandtab
au FileType json set shiftwidth=2
au FileType json set softtabstop=2
au FileType json set tabstop=2
" Language: YAML
au FileType yaml set expandtab
au FileType yaml set shiftwidth=2
au FileType yaml set softtabstop=2
au FileType yaml set tabstop=2

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Spell checking                                                vimrcspell
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Enable spell checking to english
set spelllang=en
set spell

