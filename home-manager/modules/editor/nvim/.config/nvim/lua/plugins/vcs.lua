-- From: https://github.com/tpope/vim-fugitive/issues/1274#issuecomment-1748183602
local toggle_fugitive = function()
  local winids = vim.api.nvim_list_wins()
  for _, id in pairs(winids) do
    local status = pcall(vim.api.nvim_win_get_var, id, "fugitive_status")
    if status then
      vim.api.nvim_win_close(id, false)
      return
    end
  end
  vim.cmd("Git")
end

return {
  -- #######################
  -- override default config
  -- #######################

  -- git modifications explorer/handler
  {
    "lewis6991/gitsigns.nvim",
    keys = {
      { "<M-C-G>", "<cmd>Gitsigns preview_hunk_inline<cr>", desc = "Preview Hunk inline (Ctrl+Alt+g)" },
      { "<M-C-Z>", "<cmd>Gitsigns reset_hunk<cr>", mode = { "n", "v" }, desc = "Reset hunk (Ctrl+Alt+z)" },
    },
  },




  -- #######################
  -- add new plugins
  -- #######################

  -- git integration
  {
    "tpope/vim-fugitive",
    keys = {
      { "<A-0>", toggle_fugitive, desc = "git status (Alt+0)" },
      { "<leader>gb", "<cmd>G blame<cr>", desc = "git blame" },
      { "<leader>gc", "<cmd>G commit<cr>", desc = "git commit" },
      { "<leader>gd", "<cmd>G difftool<cr>", desc = "git difftool" },
      { "<leader>gF", "<cmd>G push --force-with-lease<cr>", desc = "git push --force-with-lease" },
      -- useful for creating new PR/MR where the url is displayed in the git push message
      { "<leader>gO", "<cmd>G -p push<cr>", desc = "git push and display git message" },
      { "<leader>gp", "<cmd>G pull<cr>", desc = "git pull" },
      { "<leader>gP", "<cmd>G push<cr>", desc = "git push" },
      { "<leader>gs", toggle_fugitive, desc = "git status (Alt+0)" },
    },
  },

  -- nice view for git diff
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    keys = {
      { "<leader>gL", "<cmd>DiffviewFileHistory<cr>", noremap = true, silent = true, desc = "Check full project git history" },
      { "<A-9>", "<cmd>DiffviewFileHistory %<cr>", noremap = true, silent = true, desc = "Check current file git history (Alt+9)" },
      { "<A-8>", "<cmd>DiffviewToggleFiles<cr>", noremap = true, silent = true, desc = "Toggle diffview files (Alt+8)" },
      { "<leader>go", "<cmd>DiffviewOpen<cr>", noremap = true, silent = true, desc = "Git status with Diffview" },

      { "<leader>m", "", desc = "+git mr/pr", mode = { "n", "v" } },
      { "<leader>mm", "<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<cr>", noremap = true, silent = true, desc = "Review MR/PR (Diffview)" },
      { "<leader>mC", "<cmd>DiffviewFileHistory --range=origin/HEAD...HEAD --right-only --no-merges<cr>", noremap = true, silent = true, desc = "Review MR/PR commit by commit (Diffview)" },
      { "<leader>mx", "<cmd>DiffviewClose<cr>", noremap = true, silent = true, desc = "Close review (Diffview)" },
    },
    config = function()
      require("diffview").setup()
    end,
    dependencies = { "nvim-lua/plenary.nvim" },
  },
}
