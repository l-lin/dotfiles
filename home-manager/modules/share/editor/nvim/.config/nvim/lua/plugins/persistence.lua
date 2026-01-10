return {
  "folke/persistence.nvim",
  lazy = false,
  opts = function(_, opts)
    -- Auto-restore session when opening nvim without arguments
    vim.api.nvim_create_autocmd("VimEnter", {
      group = vim.api.nvim_create_augroup("restore_session", { clear = true }),
      callback = function()
        if vim.fn.argc(-1) == 0 then
          require("persistence").load()
        end
      end,
      nested = true,
    })
    return opts
  end,
}
