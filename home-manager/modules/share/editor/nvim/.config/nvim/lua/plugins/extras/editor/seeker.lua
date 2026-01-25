local selector = require("helpers.selector")

return {
  -- progressive file seeker
  {
    "2kabhishek/seeker.nvim",
    dev = true,
    dependencies = { "folke/snacks.nvim" },
    cmd = { "Seeker" },
    keys = {
      {
        "<C-g>",
        function()
          require("seeker").seek({ picker_opts = { focus = "input" } })
        end,
        mode = "n",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
      {
        "<C-g>",
        function()
          require("seeker").seek({ picker_opts = { focus = "input", pattern = selector.get_selected_text() } })
        end,
        mode = "v",
        noremap = true,
        silent = true,
        desc = "Find file (Ctrl+g)",
      },
      {
        "<M-f>",
        function()
          require("seeker").seek({ mode = "grep", picker_opts = { focus = "input" } })
        end,
        mode = "n",
        noremap = true,
        silent = true,
        desc = "Find pattern in all files (Alt+f)",
      },
      {
        "<M-f>",
        function()
          require("seeker").seek({ mode = "grep", picker_opts = { search = selector.get_selected_text() } })
        end,
        mode = "v",
        noremap = true,
        silent = true,
        desc = "Find pattern in all files (Alt+f)",
      },
    },
    opts = { toggle_key = "<C-e>" },
  },
}
