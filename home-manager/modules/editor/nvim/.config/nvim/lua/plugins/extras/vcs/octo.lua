return {

  -- #######################
  -- override default config
  -- #######################
  --  Edit and review GitHub issues and pull requests from the comfort of your favorite editor
  {
    "pwntester/octo.nvim",
    keys = {
      { "<leader>gp", false },
      { "<leader>gP", false },
      { "<leader>gr", false },
      { "<leader>gS", false },

      { "<leader>gl", "<cmd>Octo pr list<CR>", desc = "List PRs (Octo)" },
      { "<leader>vR", "<cmd>Octo thread resolve<CR>", desc = "Resolve thread (Octo)" },
    },
  },
}
