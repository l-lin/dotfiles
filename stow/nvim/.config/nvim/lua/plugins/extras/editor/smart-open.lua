local telescope_commands = require("plugins.custom.editor.telescope")

return {
  {
    "l-lin/smart-open.nvim",
    branch = "0.2.x",
    opts = function()
      LazyVim.on_load("telescope.nvim", function()
        require("telescope").load_extension("smart_open")
      end)
    end,
    dependencies = {
      "kkharji/sqlite.lua",
      { "nvim-telescope/telescope-fzy-native.nvim" },
    },
    keys = {
      {
        "<C-g>",
        function()
          require("telescope").extensions.smart_open.smart_open({
            cwd_only = true,
            mappings = {
              i = {
                ["<C-w>"] = function()
                  print("FOOBAR")
                end,
              },
            },
          })
        end,
        mode = "n",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
      {
        "<C-g>",
        function()
          require("telescope").extensions.smart_open.smart_open({
            cwd_only = true,
            default_text = telescope_commands.get_selected_text(),
          })
        end,
        mode = "v",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
    },
  },
}
