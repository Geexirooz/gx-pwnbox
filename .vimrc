" =====================================
" Vim Configuration
" =====================================

" ---------------- Basic Setup ----------------
let mapleader = "\\"
let maplocalleader = "\\"

set nocompatible              " Be iMproved
filetype off                  " Required for plugin setup
set laststatus=2              " Always show status line

syntax on
set t_Co=256                  " 256 colors

" Line numbers
set number
set relativenumber

" Folding
set foldmethod=indent         " Indent-based folding
set foldlevel=99              " Start unfolded

" Colour scheme
colorscheme atom-dark-256

" ---------------- Custom Mappings ----------------
" Map Ctrl+C to quit Vim in normal mode
nnoremap <C-c> :q<CR>

" Map Ctrl+S to save in normal & insert mode
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>a

" ---------------- Plugins (Vundle) ----------------
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Vundle manages itself
Plugin 'VundleVim/Vundle.vim'

" File explorer and editing helpers
Plugin 'scrooloose/nerdtree'             " File tree explorer
Plugin 'jiangmiao/auto-pairs'            " Auto close brackets, quotes

" Python development
Plugin 'dense-analysis/ale'              " Async Lint Engine
Plugin 'davidhalter/jedi-vim'            " Python auto-completion

call vundle#end()              " Required
filetype plugin indent on       " Required

" ---------------- Mappings ----------------
" Folding
nnoremap <space> za

" NERDTree
nnoremap <Leader>\ :NERDTreeFind<CR>

" ---------------- ALE Configuration ----------------
let g:ale_enabled = 1
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_save = 1
let g:ale_fix_on_save = 1

" Optional: show lint messages in status line
let g:ale_sign_error = '✗'
let g:ale_sign_warning = '⚠'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'

" ---------------- Python File Settings ----------------
augroup python_settings
  autocmd!
  autocmd BufNewFile,BufRead *.py
        \ set tabstop=4 |
        \ set softtabstop=4 |
        \ set shiftwidth=4 |
        \ set textwidth=79 |
        \ set expandtab |
        \ set autoindent |
        \ set fileformat=unix
augroup END

" ALE for Python
" Use Python tools from virtual environment
let g:ale_python_flake8_executable = expand('~/python-tools/bin/flake8')
let g:ale_python_black_executable = expand('~/python-tools/bin/black')
let g:ale_linters = {'python': ['flake8']}
let g:ale_fixers  = {'python': ['black']}

" ---------------- Bash File Settings ----------------
augroup bash_settings             
  autocmd!                       
  autocmd BufNewFile,BufRead *.sh,*.bash,*.zsh
        \ set filetype=sh |     
        \ set tabstop=4 |       
        \ set shiftwidth=4 |    
        \ set softtabstop=4 |   
        \ set expandtab |       
        \ set autoindent |      
        \ set textwidth=80 |    
        \ set fileformat=unix   
augroup END                       

" ALE for Bash scripts
let g:ale_linters.sh = ['shellcheck']        
let g:ale_fixers.sh  = ['shfmt']            

" ---------------- C Language ALE Configuration ----------------
augroup c_settings
  autocmd!
  autocmd FileType c,h
        \ let g:ale_linters = {'c': ['clangtidy', 'cppcheck']} |
        \ let g:ale_fixers  = {'c': ['clang-format']} |
        \ let g:ale_lint_on_save = 1 |
        \ let g:ale_fix_on_save  = 1
augroup END

