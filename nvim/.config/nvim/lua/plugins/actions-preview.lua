require('actions-preview').setup {
  telescope = {
    sorting_strategy = 'ascending',
    layout_strategy = 'vertical',
    layout_config = {
      width = 0.8,
      height = 0.9,
      prompt_position = 'top',
      preview_cutoff = 15,
      preview_height = function(_, _, max_lines)
        return max_lines - 10
      end,
    },
  },
}
vim.keymap.set({ 'v', 'n' }, '<M-CR>', require('actions-preview').code_actions,
  { noremap = true, silent = true, desc = 'Code action with preview (Alt+Enter)' })
