return {

  -- Community NeoVim plugin of Codeium (better than the official one)
  {
    "monkoose/neocodeium",
    event = "VeryLazy",
    dependencies = {
      {
        "folke/which-key.nvim",
        opts = {
          spec = {
            { "<leader>a", group = "ai" },
          },
        },
      },
    },
    keys = {
      { "<leader>as", "<cmd>NeoCodeium enable<cr>", silent = true, noremap = true, desc = "Start NeoCodeium" },
      { "<leader>aS", "<cmd>NeoCodeium disable<cr>", silent = true, noremap = true, desc = "Stop NeoCodeium" },
      {
        "<C-e>",
        "<cmd>lua require('neocodeium').accept()<cr>",
        mode = "i",
        silent = true,
        desc = "Accept NeoCodeium suggestion",
      },
      {
        "<M-a>",
        "<cmd>lua require('neocodeium').accept_line()<cr>",
        mode = "i",
        silent = true,
        desc = "Accept NeoCodeium line suggestion",
      },
      {
        "<M-e>",
        "<cmd>lua require('neocodeium').cycle_or_complete()<cr>",
        mode = "i",
        silent = true,
        desc = "Cycle NeoCodeium suggestion",
      },
      { "<M-c>", "<cmd>lua require('neocodeium').clear()<cr>", mode = "i", silent = true, desc = "Clear NeoCodeium" },
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
        manual = true,
        -- Set to `true` to disable some non-important messages, like "NeoCodeium: server started..."
        silent = true,
        debounce = false,
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

      -- create an autocommand which closes cmp when ai completions are displayed
      vim.api.nvim_create_autocmd("User", {
        pattern = "NeoCodeiumCompletionDisplayed",
        callback = function()
          cmp.abort()
        end,
      })
    end,
  },
}
