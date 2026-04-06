---@type vim.pack.Spec
return {
  src = "https://github.com/folke/persistence.nvim",
  data = {
    setup = function()
      require("persistence").setup({})

      if vim.env.NVIM_SCRATCH == "1" then
        return
      end

      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("restore_session", { clear = true }),
        callback = function()
          if vim.fn.argc(-1) == 0 then
            require("persistence").load()
            vim.api.nvim_command("edit")
          end
        end,
        nested = true,
      })
    end,
  },
}
