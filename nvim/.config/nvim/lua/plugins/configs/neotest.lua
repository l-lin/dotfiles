local M = {}

M.attach_diagnostic = function()
  -- get neotest namespace (api call creates or returns namespace)
  local neotest_ns = vim.api.nvim_create_namespace("neotest")

  vim.diagnostic.config({
    virtual_text = {
      format = function(diagnostic)
        local message =
            diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
        return message
      end,
    },
  }, neotest_ns)
end

M.setup = function()
  local config = {
    adapters = {
      require("neotest-go"),
    },
  }
  require("neotest").setup(config)
  M.attach_diagnostic()
end

return M
