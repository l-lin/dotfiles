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
map('n', '<C-g>',
  '<cmd>Telescope find_files find_command=rg,--no-ignore,--hidden,--glob=!.git/,--files prompt_prefix=🔍<CR>',
  { noremap = true, silent = true, desc = 'Find file' })
map('n', '<leader>f%', '<cmd>Telescope oldfiles<CR>',
  { noremap = true, desc = 'Telescope find recently open files' })
map('n', '<leader>f/', '<cmd>Telescope search_history<CR>',
  { noremap = true, desc = 'Telescope find in search history' })
map('n', '<leader>fG', '<cmd>Telescope git_status<CR>',
  { noremap = true, desc = 'Telescope find modified git files' })
map('n', '<leader>fa', '<cmd>Telescope live_grep<CR>',
  { noremap = true, desc = 'Telescope find pattern in all files' })
map('n', '<leader>fb', '<cmd>Telescope buffers<CR>', { noremap = true, desc = 'Telescope find buffer' })
map('n', '<C-e>', '<cmd>Telescope buffers<CR>', { noremap = true, desc = 'Telescope find buffer' })
map('n', '<leader>f:', '<cmd>Telescope commands<CR>',
  { noremap = true, desc = 'Telescope find nvim command' })
map('n', '<leader>fd', '<cmd>Telescope diagnostics<CR>',
  { noremap = true, desc = 'Telescope find diagnostic' })
map('n', '<leader>ff', '<cmd>Telescope find_files<CR>', { noremap = true, desc = 'Telescope find file' })
map('n', '<leader>fg', '<cmd>Telescope git_files<CR>',
  { noremap = true, desc = 'Telescope find git files' })
map('n', '<leader>fh', '<cmd>Telescope help_tags<CR>',
  { noremap = true, desc = 'Telescope find help tags' })
map('n', '<leader>fi', '<cmd>Telescope current_buffer_fuzzy_find<CR>',
  { noremap = true, desc = 'Telescope find in current buffer' })
map('n', '<leader>fj', '<cmd>Telescope jumplist<CR>',
  { noremap = true, desc = 'Telescope find in jumplist' })
map('n', '<leader>fk', '<cmd>Telescope keymaps<CR>', { noremap = true, desc = 'Telescope find keymap' })
map('n', '<leader>fl', '<cmd>Telescope loclist<CR>',
  { noremap = true, desc = 'Telescope find in location list' })
map('n', '<leader>f\'', '<cmd>Telescope marks<CR>', { noremap = true, desc = 'Telescope find marks' })
map('n', '<leader>fo', '<cmd>Telescope vim_options<CR>',
  { noremap = true, desc = 'Telescope find vim option' })
map('n', '<leader>fq', '<cmd>Telescope quickfix<CR>',
  { noremap = true, desc = 'Telescope find in quickfix list' })
map('n', '<leader>f"', '<cmd>Telescope registers<CR>',
  { noremap = true, desc = 'Telescope find in registers' })
map('n', '<leader>fw', '<cmd>Telescope grep_string<CR>',
  { noremap = true, desc = 'Telescope find string in path' })
map('n', '<leader>ft', '<cmd>Telescope tags<CR>', { noremap = true, desc = 'Telescope find tag' })
map('n', '<leader>fu', '<cmd>Telescope lsp_references<CR>',
  { noremap = true, desc = 'Telescope find lsp reference' })
map('n', '<leader>f<', '<cmd>Telescope lsp_incoming_calls<CR>',
  { noremap = true, desc = 'Telescope find lsp who am I calling' })
map('n', '<leader>f>', '<cmd>Telescope lsp_outgoing_calls<CR>',
  { noremap = true, desc = 'Telescope find lsp who is calling me' })
map('n', '<leader>f$', '<cmd>Telescope lsp_document_symbols<CR>',
  { noremap = true, desc = 'Telescope find in document functions, variables, expressions...' })
map('n', '<leader>f^', '<cmd>Telescope lsp_workspace_symbols<CR>',
  { noremap = true, desc = 'Telescope find in workspace functions, variables, expressions...' })
map('n', '<leader>fD', '<cmd>Telescope lsp_definitions<CR>',
  { noremap = true, desc = 'Telescope find definition' })
map('n', '<leader>fI', '<cmd>Telescope lsp_implementations<CR>',
  { noremap = true, desc = 'Telescope find implementation' })
map('n', '<leader>ft', '<cmd>Telescope lsp_type_definitions<CR>',
  { noremap = true, desc = 'Telescope find type definition' })
map('n', '<leader>fv', '<cmd>Telescope treesitter<CR>',
  { noremap = true, desc = 'Telescope find treesitter symbol' })
map('n', '<leader>fc', '<cmd>Telescope git_commits<CR>',
  { noremap = true, desc = 'Telescope find in commits' })
map('n', '<leader>fT', '<cmd>Telescope git_branches<CR>',
  { noremap = true, desc = 'Telescope find in branches' })
map('n', '<leader>fs', '<cmd>Telescope luasnip<CR>', { noremap = true, desc = 'Telescope find snippet' })
map('n', '<leader>fS', '<cmd>Telescope git_stash<CR>',
  { noremap = true, desc = 'Telescope find git stash' })
map('n', '<leader>fB', '<cmd>Telescope git_bcommits<CR>',
  { noremap = true, desc = 'Telescope find current buffer commit history' })
map('n', '<leader>fz', '<cmd>Telescope spell_suggest<CR>',
  { noremap = true, desc = 'Telescope find spelling suggestions for current word under cursor' })
map('n', '<leader>f%', '<cmd>Telescope oldfiles<CR>',
  { noremap = true, desc = 'Telescope find recently open files' })
map('n', '<leader>fF', "<cmd>lua require 'telescope'.extensions.file_browser.file_browser()<CR>",
  { noremap = true, desc = 'Telescope file browser' })
map('n', '<leader>fp', "<cmd>lua require'telescope'.extensions.project.project{ display_type = 'full' }<CR>",
  { noremap = true, silent = true, desc = 'Telescope find project' })
