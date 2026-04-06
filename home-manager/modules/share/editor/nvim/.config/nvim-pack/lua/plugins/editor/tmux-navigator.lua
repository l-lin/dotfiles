vim.g.tmux_navigator_no_mappings = 1

---@type vim.pack.Spec
return
-- Seamless navigation between tmux panes and vim splits.
{
  src = "https://github.com/christoomey/vim-tmux-navigator",
  data = {
    setup = function()
      vim.keymap.set("n", "<M-C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Navigate left", silent = true })
      vim.keymap.set("n", "<M-C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Navigate down", silent = true })
      vim.keymap.set("n", "<M-C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Navigate up", silent = true })
      vim.keymap.set("n", "<M-C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Navigate right", silent = true })
    end,
  },
}
