require('gitsigns').setup {
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Actions
      map({ 'n', 'v' }, '<leader>ga', ':Gitsigns stage_hunk<CR>', { desc = 'Gitsigns add/stage hunk' })
      map({ 'n', 'v' }, '<leader>gr', ':Gitsigns reset_hunk<CR>', { desc = 'Gitsigns reset hunk' })
      map({ 'n', 'v' }, '<M-C-Z>', ':Gitsigns reset_hunk<CR>', { desc = 'Gitsigns reset hunk (Ctrl+Alt+z)' })
      map('n', '<leader>gA', gs.stage_buffer, { desc = 'Gitsigns add/stage buffer' })
      map('n', '<leader>gu', gs.undo_stage_hunk, { desc = 'Gitsigns undo add/stage hunk' })
      map('n', '<leader>gR', gs.reset_buffer, { desc = 'Gitsigns reset buffer' })
      map('n', '<leader>gv', gs.preview_hunk_inline, { desc = 'Gitsigns preview hunk' })
      map('n', '<leader>gB', function() gs.blame_line { full = true } end, { desc = 'Gitsigns blame line' })
      map('n', '<leader>gT', gs.toggle_current_line_blame, { desc = 'Gitsigns toggle current line blame' })
      map('n', '<leader>gD', gs.diffthis, { desc = 'Gitsigns diff this' })
      map('n', '<leader>gt', gs.toggle_deleted, { desc = 'Gitsigns toggle deleted' })

      -- Text object
      map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
    end
}

