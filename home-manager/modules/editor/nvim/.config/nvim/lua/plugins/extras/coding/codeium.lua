return {

  -- Community NeoVim plugin of Codeium (better than the official one)
  {
    "monkoose/neocodeium",
    event = "VeryLazy",
    keys = {
      { "<leader>ca", "<cmd>NeoCodeium enable<cr>", silent = true, noremap = true, desc = "Startup NeoCodeium" },
      { "<leader>cA", "<cmd>NeoCodeium disable<cr>", silent = true, noremap = true, desc = "Stop NeoCodeium" },
      { "<C-e>", "<cmd>lua require('neocodeium').accept()<cr>", mode = "i", silent = true, desc = "Accept NeoCodeium suggestion" },
      { "<A-a>", "<cmd>lua require('neocodeium').accept_line()<cr>", mode = "i", silent = true, desc = "Accept NeoCodeium line suggestion" },
      { "<A-e>", "<cmd>lua require('neocodeium').cycle_or_complete()<cr>", mode = "i", silent = true, desc = "Cycle NeoCodeium suggestion" },
      { "<A-c>", "<cmd>lua require('neocodeium').clear()<cr>", mode = "i", silent = true, desc = "Clear NeoCodeium" },
    },
    config = function()
      local neocodeium = require("neocodeium")
      local cmp = require("cmp")

      neocodeium.setup({
        -- If `false`, then would not start codeium server (disabled state)
        -- You can manually enable it at runtime with `:NeoCodeium enable`
        enabled = false,
        -- When set to `true`, autosuggestions are disabled.
        -- Use `require'neodecodeium'.cycle_or_complete()` to show suggestions manually
        manual = false,
        -- Set to `true` to disable some non-important messages, like "NeoCodeium: server started..."
        silent = true,
        debounce = true,
        filetypes = {
          help = false,
          gitcommit = false,
          gitrebase = false,
          cvs = false,
          ["."] = false,
          TelescopePrompt = false,
          ["dap-repl"] = false,
        },
        filter = function()
          return not cmp.visible()
        end,
      })

      cmp.event:on("menu_opened", function()
        neocodeium.clear()
      end)
      cmp.setup({
        completion = {
          autocomplete = false,
        },
      })
    end,
  },
}
