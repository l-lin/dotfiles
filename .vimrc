" Using https://github.com/junegunn/vim-plug as dependency manager
" Execute :PlugInstall
call plug#begin()
Plug 'tpope/vim-sensible' " VIM minimal config
Plug 'vim-scripts/taglist.vim' " Add taglist when autocompleting
Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' } " Golang support
Plug 'vim-airline/vim-airline' " Display the bottom status bar
Plug 'vim-airline/vim-airline-themes' " Themes for the airline
Plug 'plasticboy/vim-markdown' " Markdown support
Plug 'airblade/vim-gitgutter' " Show git diff in the gutter
Plug 'tpope/vim-fugitive' " Git wrapper (cmd Gstatus, Glog, ...)
Plug 'ervandew/supertab' " Use tab instead of <C-n> for autocompletion
Plug 'morhetz/gruvbox' " VIM theme
Plug 'ctrlpvim/ctrlp.vim' " Used for GoDecls
Plug 'dbeniamine/cheat.sh-vim' " Cheat sheet
Plug 'Valloric/YouCompleteMe' "Auto completion
call plug#end()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" BASIC EDITING CONFIGURATION
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set nocompatible
set autoindent

" Show line numbers
set number

set smartindent
set tabstop=4
set shiftwidth=4
set expandtab

set completeopt=longest,menuone

" Automatically save file
set autowrite

" Set leader
let mapleader=","

" Airline configuration
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='gruvbox'
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '>'

" Disable folding
let g:vim_markdown_folding_disabled=1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" KEY MAPS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

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
map ,, <C-^>

" Show/Hide line number
nmap <c-n> :set invnumber<CR>

" Go to definition
nmap <c-b> :GoDef<CR>

" Close buffer
nmap <c-w> :bd<CR>

" Press Space to toggle highlighting on/off, and show current value.
noremap <silent> <Space> :set hlsearch! hlsearch?<CR>

" Toggle auto-indenting for code paste
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
set showmode

" Move line
"nnoremap <C-j> :m .+1<CR>==
"nnoremap <C-k> :m .-2<CR>==
"inoremap <C-j> <Esc>:m .+1<CR>==gi
"inoremap <C-k> <Esc>:m .-2<CR>==gi
"vnoremap <C-j> :m '>+1<CR>gv=gv
"vnoremap <C-k> :m '<-2<CR>gv=gv

" New buffer
nmap <C-t> :enew<CR>

" Add
command Cheatsheet split ~/.vim/doc/cheat_sheet.txt

" Delete word after cursor
imap <C-d> <C-o>diw
 
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
" Highlight variable when cursor is on it
let g:go_auto_sameids = 1
" Syntax highlighting
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_build_constraints = 1
