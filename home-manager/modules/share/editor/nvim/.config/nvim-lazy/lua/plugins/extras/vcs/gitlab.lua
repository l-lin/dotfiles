return {
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
        { "<leader>mA", "<cmd>lua require('plugins.custom.vcs.gitlab').approve()<cr>", desc = "Gitlab MR approve" },
        { "<leader>mc", "<cmd>lua require('plugins.custom.vcs.gitlab').create_comment()<cr>", desc = "Gitlab MR create comment" },
        {
          "<leader>mc",
          "<cmd>lua require('plugins.custom.vcs.gitlab').create_multiline_comment()<cr>",
          desc = "Gitlab MR create multiline comment",
          mode = "v",
        },
        {
          "<leader>ms",
          "<cmd>lua require('plugins.custom.vcs.gitlab').create_comment_suggestion()<cr>",
          desc = "Gitlab MR create comment suggestion",
          mode = "v",
        },
        { "<leader>md", "<cmd>lua require('plugins.custom.vcs.gitlab').toggle_discussions()<cr>", desc = "Gitlab MR toggle discussions" },
        { "<leader>mn", "<cmd>lua require('plugins.custom.vcs.gitlab').create_note()<cr>", desc = "Gitlab MR create note" },
        { "<leader>mo", "<cmd>lua require('plugins.custom.vcs.gitlab').open_in_browser()<cr>", desc = "Gitlab MR open in browser" },
        { "<leader>mO", "<cmd>lua require('plugins.custom.vcs.gitlab').create_mr()<cr>", desc = "Gitlab MR create MR" },
        { "<leader>mp", "<cmd>lua require('plugins.custom.vcs.gitlab').pipeline()<cr>", desc = "Gitlab MR pipeline" },
        { "<leader>mr", "<cmd>lua require('plugins.custom.vcs.gitlab').review()<cr>", desc = "Gitlab MR open review" },
        { "<leader>mR", "<cmd>lua require('plugins.custom.vcs.gitlab').revoke()<cr>", desc = "Gitlab MR revoke" },
        { "<leader>ms", "<cmd>lua require('plugins.custom.vcs.gitlab').summary()<cr>", desc = "Gitlab MR summary" },
      }
    end,
    build = function()
      require("gitlab.server").build(true)
    end,
  },
};
