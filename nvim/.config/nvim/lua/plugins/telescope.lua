local homepath = os.getenv("HOME")
local telescope_project_base_dirs = {}
local possible_base_dirs = {
  homepath .. "/work",
}

for _, dirname in ipairs(possible_base_dirs) do
  if vim.fn.isdirectory(dirname) ~= 0 then
    table.insert(telescope_project_base_dirs, dirname)
  end
end

require("telescope").setup {
  defaults = {
    file_ignore_patterns = { "venv/.*" },
    layout_strategy = 'flex',
    layout_config = {
      prompt_position = 'bottom',
      width = 0.9
    },
    sorting_strategy = "descending",
  },
  extensions = {
    ["ui-select"] = {
      require("telescope.themes").get_cursor {}
    },
    file_browser = {},
    project = {
      base_dirs = {
        telescope_project_base_dirs
      },
      order_by = "asc",
      sync_with_nvim_tree = true
    }
  }
}
require('telescope').load_extension('ui-select')
require('telescope').load_extension('luasnip')
require('telescope').load_extension('project')

local map = vim.keymap.set
-- find files
map('n', '<C-g>', '<cmd>Telescope find_files find_command=rg,--no-ignore,--hidden,--glob=!.git/,--glob=!target/,--glob=!node_modules/,--files prompt_prefix=🔍<CR>',
  { noremap = true, silent = true, desc = 'Find file' })
map('n', '<leader>fa', '<cmd>Telescope live_grep<CR>', { noremap = true, desc = 'Find pattern in all files' })
map('n', '<leader>fb', '<cmd>Telescope buffers<CR>', { noremap = true, desc = 'Find file in buffer' })
map('n', '<C-e>', '<cmd>Telescope buffers<CR>', { noremap = true, desc = 'Find file in buffer (Ctrl+e)' })

-- history
map('n', '<leader>f/', '<cmd>Telescope search_history<CR>', { noremap = true, desc = 'Find in search history' })

-- misc
map('n', '<leader>f:', '<cmd>Telescope commands<CR>', { noremap = true, desc = 'Find nvim command' })
map('n', '<leader>fh', '<cmd>Telescope help_tags<CR>', { noremap = true, desc = 'Find help tags' })
map('n', '<leader>fk', '<cmd>Telescope keymaps<CR>', { noremap = true, desc = 'Find nvim keymap' })
map('n', '<leader>fo', '<cmd>Telescope vim_options<CR>', { noremap = true, desc = 'Find vim option' })
map('n', '<leader>fs', '<cmd>Telescope luasnip<CR>', { noremap = true, desc = 'Find snippet' })
map('n', '<leader>fp', "<cmd>lua require'telescope'.extensions.project.project{ display_type = 'full' }<CR>", { noremap = true, silent = true, desc = 'Find project' })

-- text
map('n', '<leader>fti', '<cmd>Telescope current_buffer_fuzzy_find<CR>', { noremap = true, desc = 'Find string in current buffer' })
map('n', '<leader>ftg', '<cmd>Telescope grep_string<CR>', { noremap = true, desc = 'Find string in path' })
map('n', '<M-f>', '<cmd>Telescope grep_string<CR>', { noremap = true, desc = 'Find string in path (Alt+f)' })
map('n', '<leader>fts', '<cmd>Telescope spell_suggest<CR>', { noremap = true, desc = 'Spelling suggestions for current word under cursor' })

-- code
map('n', '<leader>cd', '<cmd>Telescope lsp_definitions<CR>', { noremap = true, desc = 'Goto definition' })
map('n', '<C-b>', '<cmd>Telescope lsp_definitions<CR>', { noremap = true, desc = 'Goto definition (Ctrl+b)' })
map('n', '<leader>cD', '<cmd>Telescope diagnostics<CR>', { noremap = true, desc = 'Diagnostic' })
map('n', '<M-6>', '<cmd>Telescope diagnostics<CR>', { noremap = true, desc = 'Diagnostic (Alt+6)' })
map('n', '<leader>ci', '<cmd>Telescope lsp_implementations<CR>', { noremap = true, desc = 'Goto implementation' })
map('n', '<M-C-B>', '<cmd>Telescope lsp_implementations<CR>', { noremap = true, desc = 'Goto implementation (Ctrl+Alt+b)' })
map('n', '<leader>ct', '<cmd>Telescope lsp_type_definitions<CR>', { noremap = true, desc = 'Goto type definition' })
map('n', '<leader>cR', "<cmd>lua require'telescope'.extensions.refactoring.refactors()<CR>", { noremap = true, silent = true, desc = 'Refactor' })
map('n', '<leader>cu', '<cmd>Telescope lsp_references<CR>', { noremap = true, desc = 'Goto LSP reference' })
map('n', '<M-&>', '<cmd>Telescope lsp_references<CR>', { noremap = true, desc = 'Goto LSP reference (Ctrl+Alt+7)' })
map('n', '<leader>cv', '<cmd>Telescope treesitter<CR>', { noremap = true, desc = 'Treesitter symbol' })
map('n', '<F36>', '<cmd>Telescope treesitter default_text=function<CR>', { noremap = true, desc = 'Find function (Ctrl+F12)' })
-- map('n', '<leader>cT', '<cmd>Telescope tags<CR>', { noremap = true, desc = 'Find tag' })
-- map('n', '<leader>fj', '<cmd>Telescope jumplist<CR>', { noremap = true, desc = 'Telescope in jumplist' })
-- map('n', '<leader>fq', '<cmd>Telescope quickfix<CR>', { noremap = true, desc = 'Telescope in quickfix list' })
-- map('n', '<leader>f"', '<cmd>Telescope registers<CR>', { noremap = true, desc = 'Telescope in registers' })
-- map('n', '<leader>f<', '<cmd>Telescope lsp_incoming_calls<CR>', { noremap = true, desc = 'Telescope lsp who am I calling' })
-- map('n', '<leader>f>', '<cmd>Telescope lsp_outgoing_calls<CR>', { noremap = true, desc = 'Telescope lsp who is calling me' })
-- map('n', '<leader>f$', '<cmd>Telescope lsp_document_symbols<CR>', { noremap = true, desc = 'Telescope in document functions, variables, expressions...' })
-- map('n', '<leader>f^', '<cmd>Telescope lsp_workspace_symbols<CR>', { noremap = true, desc = 'Telescope in workspace functions, variables, expressions...' })

-- git
map('n', '<leader>fgb', '<cmd>Telescope git_branches<CR>', { noremap = true, desc = 'Telescope in branches' })
map('n', '<leader>fgc', '<cmd>Telescope git_commits<CR>', { noremap = true, desc = 'Telescope in commits' })
map('n', '<leader>fgC', '<cmd>Telescope git_bcommits<CR>', { noremap = true, desc = 'Telescope current buffer commit history' })
map('n', '<leader>fgf', '<cmd>Telescope git_files<CR>', { noremap = true, desc = 'Telescope git files' })
map('n', '<leader>fgs', '<cmd>Telescope git_status<CR>', { noremap = true, desc = 'Telescope modified git files' })
map('n', '<leader>fgt', '<cmd>Telescope git_stash<CR>', { noremap = true, desc = 'Telescope git stash' })

