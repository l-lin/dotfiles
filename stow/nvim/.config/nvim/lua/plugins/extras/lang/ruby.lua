return {
  -- Neotest adapter for Minitest
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "zidhuss/neotest-minitest",
    },
    opts = {
      adapters = {
        ["neotest-minitest"] = {
          test_cmd = function()
            return vim.iter({
              "bundle",
              "exec",
              "rails",
              "test"
            }):flatten():totable()
          end,
        },
      },
    },
  },
}
