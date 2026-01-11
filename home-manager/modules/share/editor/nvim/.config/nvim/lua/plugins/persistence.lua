return {
  "folke/persistence.nvim",
  lazy = false,
  opts = function(_, opts)
    -- Do not auto-restore session for scratch instances
    if vim.env.NVIM_SCRATCH == "1" then return opts end

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
