---@type vim.pack.Spec
return
-- 💾 Simple session management for Neovim.
{
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
          if vim.fn.argc(-1) ~= 0 then
            return
          end

          require("persistence").load()

          if vim.api.nvim_buf_get_name(0) ~= "" then
            vim.api.nvim_command("edit")
          end
        end,
        nested = true,
      })
    end,
  },
}
