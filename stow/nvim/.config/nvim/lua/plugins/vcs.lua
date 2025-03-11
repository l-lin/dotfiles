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

  -- use snacks.picker for git status
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>gb", function() Snacks.picker.git_log_line({ focus = "list" }) end, desc = "Git Blame Line" },
      {
        "<leader>gs",
        function()
          Snacks.picker.git_status({
            layout = "sidebar",
            focus = "list",
            win = {
              list = {
                keys = {
                  ["<space>"] = { "git_stage", mode = { "n", "i" } },
                }
              },
            },
          })
        end,
        desc = "Git Status"
      },
      { "<leader>gl", function() Snacks.picker.git_log({ cwd = LazyVim.root.git(), focus = "list" }) end, desc = "Git Log" },
      { "<leader>gL", function() Snacks.picker.git_log({ focus = "list" }) end, desc = "Git Log (cwd)" },
      { "<A-9>", function() Snacks.picker.git_log({ current_file = true, focus = "list" }) end, noremap = true, silent = true, desc = "Check current file git history (Alt+9)" },
    }
  },
}
