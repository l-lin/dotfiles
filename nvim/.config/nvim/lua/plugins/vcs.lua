return {
  -- git integration
  {
    "tpope/vim-fugitive",
    keys = {
      { "<leader>gs", "<cmd>G<cr>", desc = "git status (Alt+0)" },
      { "<A-0>", "<cmd>G<cr>", desc = "git status (Alt+0)" },
      { "<leader>gc", "<cmd>G commit<cr>", desc = "git commit" },
      { "<leader>gp", "<cmd>G pull<cr>", desc = "git pull" },
      { "<leader>gP", "<cmd>G push<cr>", desc = "git push" },
      { "<leader>gF", "<cmd>G push --force-with-lease<cr>", desc = "git push --force-with-lease" },
      { "<leader>gb", "<cmd>G blame<cr>", desc = "git blame" },
      { "<leader>gl", "<cmd>0GcLog<cr>", desc = "git log" },
    },
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
        "<leader>mh",
        "<cmd>DiffviewFileHistory<cr>",
        noremap = true,
        silent = true,
        desc = "Check full project git history",
      },
      {
        "<leader>mf",
        "<cmd>DiffviewFileHistory %<cr>",
        noremap = true,
        silent = true,
        desc = "Check current file git history (Alt+9)",
      },
      {
        "<A-9>",
        "<cmd>DiffviewFileHistory %<cr>",
        noremap = true,
        silent = true,
        desc = "Check current file git history (Alt+9)",
      },
      {
        "<A-8>",
        "<cmd>DiffviewToggleFiles<cr>",
        noremap = true,
        silent = true,
        desc = "Toggle diffview files (Alt+8)",
      },
      {
        "<leader>mm",
        "<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<cr>",
        noremap = true,
        silent = true,
        desc = "Review MR/PR",
      },
      {
        "<leader>mC",
        "<cmd>DiffviewFileHistory --range=origin/HEAD...HEAD --right-only --no-merges<cr>",
        noremap = true,
        silent = true,
        desc = "Review MR/PR commit by commit",
      },
      {
        "<leader>mx",
        "<cmd>DiffviewClose<cr>",
        noremap = true,
        silent = true,
        desc = "Close review",
      },
      {
        "<leader>go",
        "<cmd>DiffviewOpen<cr>",
        noremap = true,
        silent = true,
        desc = "Git status with Diffview",
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
            ["<leader>m"] = { name = "+merge request" },
          },
        },
      },
    },
  },

  -- gitlab MR integration
  {
    "harrisoncramer/gitlab.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "stevearc/dressing.nvim",
    },
    keys = function()
      return {
        { "<leader>mA", "<cmd>lua require('plugins.extras.vcs.gitlab').approve()<cr>", desc = "Gitlab MR approve" },
        {
          "<leader>mc",
          "<cmd>lua require('plugins.extras.vcs.gitlab').create_comment()<cr>",
          desc = "Gitlab MR create comment",
        },
        {
          "<leader>mc",
          "<cmd>lua require('plugins.extras.vcs.gitlab').create_multiline_comment()<cr>",
          desc = "Gitlab MR create multiline comment",
          mode = "v",
        },
        {
          "<leader>ms",
          "<cmd>lua require('plugins.extras.vcs.gitlab').create_comment_suggestion()<cr>",
          desc = "Gitlab MR create comment suggestion",
          mode = "v",
        },
        {
          "<leader>md",
          "<cmd>lua require('plugins.extras.vcs.gitlab').toggle_discussions()<cr>",
          desc = "Gitlab MR toggle discussions",
        },
        {
          "<leader>mn",
          "<cmd>lua require('plugins.extras.vcs.gitlab').create_note()<cr>",
          desc = "Gitlab MR create note",
        },
        {
          "<leader>mo",
          "<cmd>lua require('plugins.extras.vcs.gitlab').open_in_browser()<cr>",
          desc = "Gitlab MR open in browser",
        },
        { "<leader>mp", "<cmd>lua require('plugins.extras.vcs.gitlab').pipeline()<cr>", desc = "Gitlab MR pipeline" },
        { "<leader>mr", "<cmd>lua require('plugins.extras.vcs.gitlab').review()<cr>", desc = "Gitlab MR open review" },
        { "<leader>mR", "<cmd>lua require('plugins.extras.vcs.gitlab').revoke()<cr>", desc = "Gitlab MR revoke" },
        { "<leader>ms", "<cmd>lua require('plugins.extras.vcs.gitlab').summary()<cr>", desc = "Gitlab MR summary" },
      }
    end,
    build = function()
      require("gitlab.server").build(true)
    end,
  },
}
