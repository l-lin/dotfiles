return {
  -- git integration
  {
    "tpope/vim-fugitive",
    keys = {
      { "<leader>gs", "<cmd>G<cr>",                         desc = "git status (Alt+0)" },
      { "<A-0>",      "<cmd>G<cr>",                         desc = "git status (Alt+0)" },
      { "<leader>gc", "<cmd>G commit<cr>",                  desc = "git commit" },
      { "<leader>gp", "<cmd>G pull<cr>",                    desc = "git pull" },
      { "<leader>gP", "<cmd>G push<cr>",                    desc = "git push" },
      { "<leader>gF", "<cmd>G push --force-with-lease<cr>", desc = "git push --force-with-lease" },
      { "<leader>gb", "<cmd>G blame<cr>",                   desc = "git blame" },
      { "<leader>gl", "<cmd>0GcLog<cr>",                    desc = "git log" },
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
            ["<leader>mg"] = { name = "+gitlab" },
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
      "stevearc/dressing.nvim",
    },
    keys = function()
      local gitlab = require("gitlab")
      return {
        { "<leader>mga", gitlab.approve,            desc = "Gitlab MR approve" },
        { "<leader>mgc", gitlab.create_comment,     desc = "Gitlab MR create comment" },
        { "<leader>mgd", gitlab.toggle_discussions, desc = "Gitlab MR toggle discussions" },
        { "<leader>mgD", gitlab.delete_comment,     desc = "Gitlab MR delete comment" },
        { "<leader>mge", gitlab.edit_comment,       desc = "Gitlab MR edit comment" },
        { "<leader>mgn", gitlab.create_note,        desc = "Gitlab MR create note" },
        { "<leader>mgr", gitlab.review,             desc = "Gitlab MR open review" },
        { "<leader>mgR", gitlab.revoke,             desc = "Gitlab MR revoke" },
        { "<leader>mgS", gitlab.summary,            desc = "Gitlab MR summary" },
        { "<leader>mgt", gitlab.toggle_resolved,    desc = "Gitlab MR toggle resolved" },
        { "<leader>mgy", gitlab.reply,              desc = "Gitlab MR reply comment" },
      }
    end,
    build = function()
      require("gitlab.server").build()
    end,
    config = function()
      require("gitlab").setup({
        port = 21036, -- The port of the Go server, which runs in the background
        log_path = vim.fn.stdpath("cache") .. "/gitlab.nvim.log", -- Log path for the Go server
        reviewer = "delta", -- The reviewer type (only delta is currently supported)
        popup = { -- The popup for comment creation, editing, and replying
          exit = "<Esc>",
          perform_action = "<C-s>", -- Once in normal mode, does action (like saving comment or editing description, etc)
          perform_linewise_action = "<leader>l", -- Once in normal mode, does the linewise action (see logs for this job, etc)
        },
        discussion_tree = { -- The discussion tree that holds all comments
          blacklist = {}, -- List of usernames to remove from tree (bots, CI, etc)
          jump_to_file = "o", -- Jump to comment location in file
          jump_to_reviewer = "m", -- Jump to the location in the reviewer window
          edit_comment = "e", -- Edit coment
          delete_comment = "dd", -- Delete comment
          reply = "r", -- Reply to comment
          toggle_node = "<cr>", -- Opens or closes the discussion
          toggle_resolved = "p", -- Toggles the resolved status of the discussion
          position = "bottom", -- "top", "right", "bottom" or "left"
          size = "40%", -- Size of split
          relative = "editor", -- Position of tree split relative to "editor" or "window"
          resolved = "", -- Symbol to show next to resolved discussions
          unresolved = "", -- Symbol to show next to unresolved discussions
        },
        review_pane = { -- Specific settings for different reviewers
          delta = {
            added_file = "", -- The symbol to show next to added files
            modified_file = "", -- The symbol to show next to modified files
            removed_file = "", -- The symbol to show next to removed files
          },
        },
        dialogue = { -- The confirmation dialogue for deleting comments
          focus_next = { "j", "<Down>", "<Tab>" },
          focus_prev = { "k", "<Up>", "<S-Tab>" },
          close = { "<Esc>", "<C-c>" },
          submit = { "<CR>", "<Space>" },
        },
        pipeline = {
          created = "",
          pending = "",
          preparing = "",
          scheduled = "",
          running = "ﰌ",
          canceled = "ﰸ",
          skipped = "ﰸ",
          success = "✓",
          failed = "",
        },
      })
    end,
  },
}
