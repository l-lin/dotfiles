return {
  -- framework for interacting with tests
  {
    "nvim-neotest/neotest",
    ft = { "go" },
    opts = {
      adapters = {
        "neotest-go",
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neotest/neotest-go",
    },
  },
}
