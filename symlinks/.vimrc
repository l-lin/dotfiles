" Plugins {{{
" Using https://github.com/junegunn/vim-plug as dependency manager
" Execute :PlugInstall
call plug#begin()
Plug 'tpope/vim-sensible'             " VIM minimal config

" GUI stuffs
Plug 'morhetz/gruvbox'                " VIM theme
Plug 'arcticicestudio/nord-vim'       " VIM theme
Plug 'vim-airline/vim-airline'        " Display the bottom status bar
Plug 'vim-airline/vim-airline-themes' " Themes for the airline
Plug 'ryanoasis/vim-devicons'         " Icons everywhere
Plug 'dense-analysis/ale'             " Linting
Plug 'airblade/vim-gitgutter'         " Show git diff in the gutter
Plug 'kshenoy/vim-signature'          " Display marks

" Completions
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Languages
"Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' } " Golang support
Plug 'plasticboy/vim-markdown'        " Markdown support
Plug 'editorconfig/editorconfig-vim'  " .editorconfig support
Plug 'rust-lang/rust.vim'             " Rust support
Plug 'hashivim/vim-terraform'         " Terraform support
Plug 'chr4/nginx.vim'                 " Nginx support

" Snippets
Plug 'SirVer/ultisnips'               " Snippets
Plug 'honza/vim-snippets'             " Snippets

" Others
Plug 'ctrlpvim/ctrlp.vim'             " Open file directory directly with C-p + used for GoDecls
Plug 'scrooloose/nerdtree'            " Tree explorer
Plug 'Xuyuanp/nerdtree-git-plugin'    " Tree explorer with Git status
Plug 'easymotion/vim-easymotion'      " Easily navigate through the file
Plug 'mbbill/undotree'                " Undo history
Plug 'terryma/vim-multiple-cursors'   " Sublime text's multiple selection
Plug 'Chiel92/vim-autoformat'         " Format code
Plug 'vim-scripts/dbext.vim'          " DB access (exec SQL directly from VIM)
Plug 'vim-scripts/DrawIt'             " Help draw ascii schemas
Plug 'psliwka/vim-smoothie'           " Smooth scrolling
Plug 'rhysd/vim-grammarous'           " Grammar checker
Plug 'machakann/vim-highlightedyank'  " Highlight yank
call plug#end()
" }}}
" Basic editing configuration {{{
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
" display tab
set list
" yank in clipboard
set clipboard=unnamedplus
" }}}
" VIM user interface {{{
" Set 7 lines to the cursor - when moving vertically using j/k
set so=7
" Close VIM if only window left is NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" Airline configuration
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='nord'
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '>'

syntax on
syntax enable
" Highlight spell errors: https://github.com/morhetz/gruvbox/issues/175#issuecomment-390428621
let g:gruvbox_guisp_fallback='bg'
" Theme colorscheme
colorscheme nord
set background=dark
if (has("termguicolors"))
  set termguicolors
endif
" File type detection
filetype plugin on
" Omnicomplete
set omnifunc=syntaxcomplete#Complete
" }}}
" Files, backups and undo {{{
" Turn backup off, since most stuff is in SVN, git etc anyway...
set nobackup
set nowb
set noswapfile
" Persistent undo
if has("persistent_undo")
    set undodir=$HOME/.undodir/
    set undofile
endif
" Source other vim config files
if isdirectory($HOME . "/work/.vim")
  source $HOME/work/.vim/*.vim
endif
" Exclude files & folders from full path fuzzy ctrlp
let g:ctrlp_custom_ignore = 'node_modules'
" }}}
" Key maps {{{
" Visual mode pressing * or # searches for the current selection
vnoremap <silent> * :call VisualSelection('f')<CR>
vnoremap <silent> # :call VisualSelection('b')<CR>
" Switch back and forth from buffer
map ;; <C-^>
" Show/Hide line number
"nmap <C-m> :set invnumber<CR>
" Build & test
map <F9> :GoBuild<CR>
map <F8> :GoTest<CR>
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
" Format
noremap <leader>l :Autoformat<CR>
" use a different buffer for delete and paste
nnoremap d "_d
vnoremap d "_d
vnoremap p "_dP

" coc key mappings
" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()
" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
" Show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction
" GoTo code navigation.
nmap <C-b> <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <A-7> <Plug>(coc-references)
" Symbol renaming.
nmap <S-F6> <Plug>(coc-rename)
" }}}
" Cursor shape {{{
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
" }}}
" vim-go customization {{{
" Call goimports on save
let g:go_fmt_command = "goimports"
let g:go_def_mode='gopls'
let g:go_info_mode='gopls'
" Call vet, golint & errcheck on save
let g:go_metalinter_autosave = 0
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
" Debug window config
let g:go_debug_windows = {
      \ 'vars':       'rightbelow 60vnew',
      \ 'stack':      'rightbelow 10new',
\ }
" }}}
" rust.vim customization {{{
" fmt on save
let g:rustfmt_autosave = 1
" }}}
" Linting {{{
" Error and warning signs.
let g:ale_sign_error = '⤫'
let g:ale_sign_warning = '⚠'
" Enable integration with airline.
let g:airline#extensions#ale#enabled = 1
" Keep sign in gutter open
let g:ale_sign_column_always = 1
let g:ale_linters = {
	\ 'go': ['gopls'],
	\}
" If no Go error are not displayed in gutter with Go 1.13+, edit the file ~/.vim/plugged/ale/autoload/ale/handlers/go.vim
" see https://github.com/dense-analysis/ale/issues/2761
" }}}
" Conquer of completion {{{
" TextEdit might fail if hidden is not set.
set hidden
" Some servers have issues with backup files, see #649.
set nowritebackup
" Give more space for displaying messages.
set cmdheight=2
" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300
" Don't pass messages to |ins-completion-menu|.
set shortmess+=c
" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
set signcolumn=yes

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
" position. Coc only does snippet and additional edit on confirm.
if exists('*complete_info')
  inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
  imap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif
" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')
" }}}
" Editorconfig {{{
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
" }}}
" Spell checking {{{
" Enable spell checking to english
set spelllang=en
" by default, do not spell check
set nospell
" }}}
" Database access {{{
let g:dbext_default_profile_PG_localhost = 'type=PGSQL:user=postgres:dbname=oodev:host=localhost'
let g:dbext_default_profile = 'PG_localhost'
" }}}

" vim:foldmethod=marker:foldlevel=0
