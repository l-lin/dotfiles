" Using https://github.com/junegunn/vim-plug as dependency manager
" Execute :PlugInstall
call plug#begin()
Plug 'tpope/vim-sensible' " VIM minimal config
Plug 'vim-scripts/taglist.vim' " Add taglist when autocompleting
Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' } " Golang support
Plug 'SirVer/ultisnips' " Snippets
Plug 'vim-airline/vim-airline' " Display the bottom status bar
Plug 'vim-airline/vim-airline-themes' " Themes for the airline
Plug 'plasticboy/vim-markdown' " Markdown support
Plug 'airblade/vim-gitgutter' " Show git diff in the gutter
Plug 'tpope/vim-fugitive' " Git wrapper (cmd Gstatus, Glog, ...)
Plug 'ervandew/supertab' " Use tab instead of <C-n> for autocompletion
Plug 'morhetz/gruvbox' " VIM theme
Plug 'ctrlpvim/ctrlp.vim' " Used for GoDecls
Plug 'Valloric/YouCompleteMe' "Auto completion
Plug 'scrooloose/nerdtree' " Tree explorer
Plug 'Xuyuanp/nerdtree-git-plugin' " Tree explorer with Git status
Plug 'easymotion/vim-easymotion' " Easily navigate through the file
call plug#end()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" BASIC EDITING CONFIGURATION
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Enable spell checking to english
set spelllang=en
set spell

set nocompatible
set autoindent

" Show line numbers
set number

set smartindent
set tabstop=4
set shiftwidth=4
set expandtab

set completeopt=longest,menuone

" Change how vim represents characters on the screen
set encoding=utf-8

" Set the encoding of files written
set fileencoding=utf-8

" Set leader
let mapleader=","

" Airline configuration
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='gruvbox'
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '>'

" Disable folding
let g:vim_markdown_folding_disabled=1

" Highlight line
set cursorline

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" VIM user interface
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set 7 lines to the cursor - when moving vertically using j/k
set so=7

" Close VIM if only window left is NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Files, backups and undo
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Turn backup off, since most stuff is in SVN, git et.c anyway...
set nobackup
set nowb
set noswapfile

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" KEY MAPS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Visual mode pressing * or # searches for the current selection
vnoremap <silent> * :call VisualSelection('f')<CR>
vnoremap <silent> # :call VisualSelection('b')<CR>

" Set ctrl-space instead of ctrl-n
if has("gui_running")
    " C-Space seems to work under gVim on both Linux and win32
    inoremap <C-Space> <C-n>
else " no gui
    if has("unix")
        inoremap <Nul> <C-n>
    else
        " I have no idea of the name of Ctrl-Space elsewhere
    endif
endif

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

"move lines around
nnoremap <leader>k :m-2<cr>==
nnoremap <leader>j :m+<cr>==
xnoremap <leader>k :m-2<cr>gv=gv
xnoremap <leader>j :m'>+<cr>gv=gv

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" COLORS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
syntax on
syntax enable

colorscheme gruvbox
set background=dark " Welcome to the dark side

filetype plugin on

" Omnicomplete
set omnifunc=syntaxcomplete#Complete
hi Pmenu ctermfg=153 ctermbg=NONE cterm=NONE guifg=#bcdbff guibg=NONE gui=NONE
hi PmenuSel ctermfg=NONE ctermbg=59 cterm=NONE guifg=NONE guibg=#3f4b52 gui=NONE

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" VIM-GO customization
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
