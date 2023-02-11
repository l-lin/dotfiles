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
        layout_config = {
          prompt_position = 'top'
        }
    },
    extensions = {
        ["ui-select"] = {
            require("telescope.themes").get_dropdown {}
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

local map = vim.api.nvim_set_keymap
map('n', '<C-n>', ':Telescope find_files find_command=rg,--no-ignore,--hidden,--glob=!.git/,--files prompt_prefix=🔍<CR>',
    { noremap = true, silent = true, desc = 'Find file' })
map('n', '<C-g>', ':Telescope live_grep<CR>', { noremap = true, desc = 'Find pattern in all files' })
map('n', '<leader>f%', ':Telescope oldfiles<CR>',
    { noremap = true, desc = 'Telescope find recently open files' })
map('n', '<leader>f/', ':Telescope search_history<CR>',
    { noremap = true, desc = 'Telescope find in search history' })
map('n', '<leader>fG', ':Telescope git_status<CR>',
    { noremap = true, desc = 'Telescope find modified git files' })
map('n', '<leader>fa', ':Telescope live_grep<CR>',
    { noremap = true, desc = 'Telescope find pattern in all files' })
map('n', '<leader>fb', ':Telescope buffers<CR>', { noremap = true, desc = 'Telescope find buffer' })
map('n', '<leader>f:', ':Telescope commands<CR>',
    { noremap = true, desc = 'Telescope find nvim command' })
map('n', '<leader>fd', ':Telescope diagnostics<CR>',
    { noremap = true, desc = 'Telescope find diagnostic' })
map('n', '<leader>ff', ':Telescope find_files<CR>', { noremap = true, desc = 'Telescope find file' })
map('n', '<leader>fg', ':Telescope git_files<CR>',
    { noremap = true, desc = 'Telescope find git files' })
map('n', '<leader>fh', ':Telescope help_tags<CR>',
    { noremap = true, desc = 'Telescope find help tags' })
map('n', '<leader>fi', ':Telescope current_buffer_fuzzy_find<CR>',
    { noremap = true, desc = 'Telescope find in current buffer' })
map('n', '<leader>fj', ':Telescope jumplist<CR>',
    { noremap = true, desc = 'Telescope find in jumplist' })
map('n', '<leader>fk', ':Telescope keymaps<CR>', { noremap = true, desc = 'Telescope find keymap' })
map('n', '<leader>fl', ':Telescope loclist<CR>',
    { noremap = true, desc = 'Telescope find in location list' })
map('n', '<leader>f\'', ':Telescope marks<CR>', { noremap = true, desc = 'Telescope find marks' })
map('n', '<leader>fo', ':Telescope vim_options<CR>',
    { noremap = true, desc = 'Telescope find vim option' })
map('n', '<leader>fq', ':Telescope quickfix<CR>',
    { noremap = true, desc = 'Telescope find in quickfix list' })
map('n', '<leader>f"', ':Telescope registers<CR>',
    { noremap = true, desc = 'Telescope find in registers' })
map('n', '<leader>fw', ':Telescope grep_string<CR>',
    { noremap = true, desc = 'Telescope find string in path' })
map('n', '<leader>ft', ':Telescope tags<CR>', { noremap = true, desc = 'Telescope find tag' })
map('n', '<leader>fu', ':Telescope lsp_references<CR>',
    { noremap = true, desc = 'Telescope find lsp reference' })
map('n', '<leader>f<', ':Telescope lsp_incoming_calls<CR>',
    { noremap = true, desc = 'Telescope find lsp who am I calling' })
map('n', '<leader>f>', ':Telescope lsp_outgoing_calls<CR>',
    { noremap = true, desc = 'Telescope find lsp who is calling me' })
map('n', '<leader>f$', ':Telescope lsp_document_symbols<CR>',
    { noremap = true, desc = 'Telescope find in document functions, variables, expressions...' })
map('n', '<leader>f^', ':Telescope lsp_workspace_symbols<CR>',
    { noremap = true, desc = 'Telescope find in workspace functions, variables, expressions...' })
map('n', '<leader>fD', ':Telescope lsp_definitions<CR>',
    { noremap = true, desc = 'Telescope find definition' })
map('n', '<leader>fI', ':Telescope lsp_implementations<CR>',
    { noremap = true, desc = 'Telescope find implementation' })
map('n', '<leader>ft', ':Telescope lsp_type_definitions<CR>',
    { noremap = true, desc = 'Telescope find type definition' })
map('n', '<leader>fv', ':Telescope treesitter<CR>',
    { noremap = true, desc = 'Telescope find treesitter symbol' })
map('n', '<leader>fc', ':Telescope git_commits<CR>',
    { noremap = true, desc = 'Telescope find in commits' })
map('n', '<leader>fT', ':Telescope git_branches<CR>',
    { noremap = true, desc = 'Telescope find in branches' })
map('n', '<leader>fs', ':Telescope luasnip<CR>', { noremap = true, desc = 'Telescope find snippet' })
map('n', '<leader>fS', ':Telescope git_stash<CR>',
    { noremap = true, desc = 'Telescope find git stash' })
map('n', '<leader>fB', ':Telescope git_bcommits<CR>',
    { noremap = true, desc = 'Telescope find current buffer commit history' })
map('n', '<leader>fz', ':Telescope spell_suggest<CR>',
    { noremap = true, desc = 'Telescope find spelling suggestions for current word under cursor' })
map('n', '<leader>f%', ':Telescope oldfiles<CR>',
    { noremap = true, desc = 'Telescope find recently open files' })
map('n', '<leader>fF', "<cmd>lua require 'telescope'.extensions.file_browser.file_browser()<CR>",
    { noremap = true, desc = 'Telescope file browser' })
map('n', '<leader>fp', "<cmd>lua require'telescope'.extensions.project.project{ display_type = 'full' }<CR>",
    { noremap = true, silent = true, desc = 'Telescope find project' })
