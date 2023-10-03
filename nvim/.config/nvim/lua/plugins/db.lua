return {
  {
    "tpope/vim-dadbod",
    keys = {
      {
        "<leader>D",
        "<cmd>DBUIToggle<cr>",
        noremap = true,
        silent = true,
        desc = "Toggle DB UI",
      }
    },
    cmd = {
      "DBUIToggle",
      "DBUI",
      "DBUIAddConnection",
      "DBUIFindBuffer",
      "DBUIRenameBuffer",
      "DBUILastQueryInfo",
    },
    dependencies = {
      "kristijanhusak/vim-dadbod-ui",
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "psql" } },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
}
