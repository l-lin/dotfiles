return {

  -- #######################
  -- override default config
  -- #######################
  --  Edit and review GitHub issues and pull requests from the comfort of your favorite editor
  {
    "pwntester/octo.nvim",
    dependencies = {
      {
        "folke/which-key.nvim",
        opts = {
          spec = {
            { "<leader>go", group = "octo" },
          },
        },
      },
    },
    keys = {
      { "<leader>gp", false },
      { "<leader>gP", false },
      { "<leader>gr", false },
      { "<leader>gS", false },

      { "<leader>gop", "<cmd>Octo pr list<CR>", desc = "List PRs (Octo)" },
      { "<leader>vR", "<cmd>Octo thread resolve<CR>", desc = "Resolve thread (Octo)", ft = "octo" },
    },
  },
}
