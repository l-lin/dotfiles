return {
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
        "<leader>mc",
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
  -- gitlab integration
  {
    "harrisoncramer/gitlab.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
    },
    enabled = false,
    keys = {
      { "<leader>ms", "<cmd>lua require('gitlab').summary()<cr>", desc = "Gitlab MR summary" },
      { "<leader>mA", "<cmd>lua require('gitlab').approve()<cr>", desc = "Gitlab MR approve" },
      { "<leader>mR", "<cmd>lua require('gitlab').revoke()<cr>", desc = "Gitlab MR revoke" },
      { "<leader>mC", "<cmd>lua require('gitlab').create_comment()<cr>", desc = "Gitlab MR create comment" },
      { "<leader>md", "<cmd>lua require('gitlab').list_discussions()<cr>", desc = "Gitlab MR list discussions" },
    },
    build = function()
      require("gitlab").build()
    end,
    config = function()
      require("gitlab").setup({
        port = 20136, -- The port of the Go server, which runs in the background
        log_path = vim.fn.stdpath("cache") .. "gitlab.nvim.log", -- Log path for the Go server
        keymaps = {
          popup = { -- The popup for comment creation, editing, and replying
            exit = "<Esc>",
            perform_action = "<C-s>", -- Once in normal mode, does action (like saving comment or editing description, etc)
          },
          discussion_tree = { -- The discussion tree that holds all comments
            jump_to_location = "o", -- Jump to comment location in file
            edit_comment = "e", -- Edit coment
            delete_comment = "d", -- Delete comment
            reply_to_comment = "r", -- Reply to comment
            toggle_resolved = "p", -- Toggles the resolved status of the discussion
            toggle_node = "=", -- Opens or closes the discussion
            position = "bottom", -- "top", "right", "bottom" or "left"
            relative = "editor", -- Position of tree split relative to "editor" or "window"
            size = "20%", -- Size of split
          },
          dialogue = { -- The confirmation dialogue for deleting comments
            focus_next = { "j", "<Down>", "<Tab>" },
            focus_prev = { "k", "<Up>", "<S-Tab>" },
            close = { "<Esc>", "<C-c>" },
            submit = { "<CR>", "<Space>" },
          },
        },
        symbols = {
          resolved = "",
          unresolved = "",
        },
      })
    end,
  },
}
