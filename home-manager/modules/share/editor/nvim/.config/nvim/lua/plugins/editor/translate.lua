---@type vim.pack.Spec
return
-- Perform translation in Neovim using translate-shell.
{
  src = "https://codeberg.org/l-lin/translate.nvim",
  data = {
    setup = function()
      vim.schedule(function()
        require("translate").setup({ default_lang = "en" })

        -- stylua: ignore start
        vim.keymap.set("v", "<leader>oD", function() require("translate").replace_selection() end, { desc = "Translate & replace" })
        vim.keymap.set("n", "<leader>oD", function() require("translate").replace_cword() end, { desc = "Translate & replace word under cursor" })
        vim.keymap.set("n", "<leader>od", function() require("translate").translate(vim.fn.expand("<cword>")) end, { desc = "Translate word under cursor" })
        vim.keymap.set("v", "<leader>od", function() require("translate").translate(require("functions.selector").get_selected_text()) end, { desc = "Translate selected text" })
        -- stylua: ignore end
      end)
    end,
  },
}
