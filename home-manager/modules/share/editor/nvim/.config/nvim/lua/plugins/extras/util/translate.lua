local selector = require("helpers.selector")

return {
  {
    "https://codeberg.org/l-lin/translate.nvim",
    cmd = "Translate",
    opts = { default_lang = "en" },
    keys = {
      { "<leader>oD", function() require("translate").replace_selection() end, mode = "v", desc = "Translate & replace" },
      { "<leader>oD", function() require("translate").replace_cword() end, mode = "n", desc = "Translate & replace word under cursor" },
      { "<leader>od", function() require("translate").translate(vim.fn.expand("<cword>")) end, mode = "n", desc = "Translate word under cursor" },
      { "<leader>od", function() require("translate").translate(selector.get_selected_text()) end, mode = "v", desc = "Translate selected text" },
    },
  }
}
