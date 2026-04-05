--
-- 💾 Simple session management for Neovim
--

--
-- Setup
--
local persistence = require("persistence")
persistence.setup({})

--
-- Autocmd
--
if vim.env.NVIM_SCRATCH ~= "1" then
  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("restore_session", { clear = true }),
    callback = function()
      if vim.fn.argc(-1) == 0 then
        persistence.load()
        vim.api.nvim_command("edit")
      end
    end,
    nested = true,
  })
end

---@type vim.pack.Spec
return {
  src = "https://github.com/folke/persistence.nvim",
  data = {
    setup = function()
      require("persistence").setup({})
    end,
    ---@param create_autocmd fun(event: string, opts: table)
    autocmds = function(create_autocmd)
      if vim.env.NVIM_SCRATCH ~= "1" then
        create_autocmd("VimEnter", {
          group = vim.api.nvim_create_augroup("restore_session", { clear = true }),
          callback = function()
            if vim.fn.argc(-1) == 0 then
              persistence.load()
              vim.api.nvim_command("edit")
            end
          end,
          nested = true,
        })
      end
    end,
  },
}
