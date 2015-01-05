" Using https://github.com/junegunn/vim-plug as depency manager
" Execute :PlugInstall
call plug#begin()
Plug 'tpope/vim-sensible'
Plug 'vim-scripts/SQLComplete.vim'
Plug 'vim-scripts/taglist.vim'
Plug 'scrooloose/nerdcommenter'
Plug 'fatih/vim-go'
Plug 'majutsushi/tagbar'
" Plug 'ervandew/supertab'
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

" Set leader
let mapleader=","

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" KEY MAPS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Display a completion menu
inoremap <expr> <C-n> pumvisible() ? '<C-n>' :
  \ '<C-n><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'

inoremap <expr> <M-,> pumvisible() ? '<C-n>' :
  \ '<C-x><C-o><C-n><C-p><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'

" open omni completion menu closing previous if open and opening new menu
" without changing the text
inoremap <expr> <C-Space> (pumvisible() ? (col('.') > 1 ? '<Esc>i<Right>' : '<Esc>i') : '') .
            \ '<C-x><C-o><C-r>=pumvisible() ? "\<lt>C-n>\<lt>C-p>\<lt>Down>" : ""<CR>'
" open user completion menu closing previous if open and opening new menu
" without changing the text
inoremap <expr> <S-Space> (pumvisible() ? (col('.') > 1 ? '<Esc>i<Right>' : '<Esc>i') : '') .
            \ '<C-x><C-u><C-r>=pumvisible() ? "\<lt>C-n>\<lt>C-p>\<lt>Down>" : ""<CR>'


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

" Map comment
nmap <c-b> :call NERDComment(0, "toggle")<cr>

" Show/Hide line number
nmap <c-n> :set invnumber<CR>

" Press Space to toggle highlighting on/off, and show current value.
noremap <silent> <Space> :set hlsearch! hlsearch?<CR>

" Tagbar
nmap <F8> :TagbarToggle<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" COLORS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
syntax on
syntax enable

filetype plugin on
set omnifunc=syntaxcomplete#Complete

