return {
  {
    "tpope/vim-fugitive",
    keys = {
      { "<leader>gs", "<cmd>G<cr>",                         desc = "git status" },
      { "<leader>gc", "<cmd>G commit<cr>",                  desc = "git commit" },
      { "<leader>gp", "<cmd>G pull<cr>",                    desc = "git pull" },
      { "<leader>gP", "<cmd>G push<cr>",                    desc = "git push" },
      { "<leader>gF", "<cmd>G push --force-with-lease<cr>", desc = "git push --force-with-lease" },
      { "<leader>gb", "<cmd>G blame<cr>",                   desc = "git blame" },
      { "<leader>gl", "<cmd>0GcLog<cr>",                    desc = "git log" },
    },
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("fugitive_close_with_q", { clear = true }),
        pattern = {
          "fugitive",
        },
        callback = function(event)
          vim.bo[event.buf].buflisted = false
          vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
        end,
      })
    end,
  },

  -- git modifications explorer/handler
  {
    "lewis6991/gitsigns.nvim",
    keys = {
      {
        "<M-C-G>",
        "<cmd>Gitsigns preview_hunk_inline<cr>",
        desc = "Preview Hunk inline (Ctrl+Alt+g)",
      },
      {
        "<M-C-Z>",
        "<cmd>Gitsigns reset_hunk<cr>",
        mode = { "n", "v" },
        desc = "Reset hunk (Ctrl+Alt+z)",
      },
    },
  },

  -- nice view for git diff
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    keys = {
      {
        "<leader>gdh",
        "<cmd>DiffviewFileHistory<cr>",
        noremap = true,
        silent = true,
        desc = "Check full project git history",
      },
      {
        "<leader>gdf",
        "<cmd>DiffviewFileHistory %<cr>",
        noremap = true,
        silent = true,
        desc = "Check current file git history (Alt+0)",
      },
      {
        "<A-0>",
        "<cmd>DiffviewFileHistory %<cr>",
        noremap = true,
        silent = true,
        desc = "Check current file git history (Alt+0)",
      },
      {
        "<leader>gdm",
        "<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<cr>",
        noremap = true,
        silent = true,
        desc = "Review MR/PR",
      },
      {
        "<leader>gdc",
        "<cmd>DiffviewFileHistory --range=origin/HEAD...HEAD --right-only --no-merges<cr>",
        noremap = true,
        silent = true,
        desc = "Review MR/PR commit by commit",
      },
    },
    config = function()
      require("diffview").setup()
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "folke/which-key.nvim",
        opts = {
          defaults = {
            ["<leader>gd"] = { name = "+diffview" },
          },
        },
      },
    },
  },
}
