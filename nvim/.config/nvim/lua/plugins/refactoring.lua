local M = {}

M.setup = function()
  local config = {
    prompt_func_return_type = {
      go = true,
      js = true,
      ts = true,
    },
    prompt_func_param_type = {
      go = false,
      js = true,
      ts = true,
    },
  }
  require("refactoring").setup(config)
end

return M
