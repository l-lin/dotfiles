---@type vim.pack.Spec
return {
  src = "https://codeberg.org/l-lin/translate.nvim",
  data = {
    setup = function()
      require("translate").setup({ default_lang = "en" })

      local map = vim.keymap.set
      map("v", "<leader>oD", function()
        require("translate").replace_selection()
      end, { desc = "Translate & replace" })
      map("n", "<leader>oD", function()
        require("translate").replace_cword()
      end, { desc = "Translate & replace word under cursor" })
      map("n", "<leader>od", function()
        require("translate").translate(vim.fn.expand("<cword>"))
      end, { desc = "Translate word under cursor" })
      map("v", "<leader>od", function()
        require("translate").translate(require("functions.selector").get_selected_text())
      end, { desc = "Translate selected text" })
    end,
  },
}
