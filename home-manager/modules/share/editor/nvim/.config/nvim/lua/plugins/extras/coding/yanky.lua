return {
  -- #######################
  -- override default config
  -- #######################

  {
    "gbprod/yanky.nvim",
    keys = {
      -- disable keybinding, in conflict with vim-fugitive
      { "=p", false },
      { "=P", false },
    },
    opts = {
      system_clipboard = {
        -- Disable synching with ring because it's creating events `FocusGained` and `FocusLost`.
        -- yanky.nvim then executes `wl-copy` (my default copy tool), and it seems to trigger some
        -- notification on gnome, which freezes NeoVim...
        sync_with_ring = false,
      },
    },
  },
}
