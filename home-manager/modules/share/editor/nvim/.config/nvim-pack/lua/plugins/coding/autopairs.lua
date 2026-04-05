---@type vim.pack.Spec
return {
  src = "https://github.com/windwp/nvim-autopairs",
  data = {
    ---@param create_autocmd fun(event: string|string[], opts: table)
    autocmds = function(create_autocmd)
      create_autocmd("InsertEnter", {
        once = true,
        callback = function()
          require("nvim-autopairs").setup({})
        end,
      })
    end,
  },
}
