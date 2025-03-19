return {
  {
    "olimorris/codecompanion.nvim",
    cmd = {
      "CodeCompanion",
      "CodeCompanionChat",
      "CodeCompanionCmd",
      "CodeCompanionActions",
    },
    keys = {
      {
        "<leader>at",
        "<cmd>CodeCompanionChat toggle<cr>",
        silent = true,
        mode = { "n", "v" },
        noremap = true,
        desc = "Toggle CodeCompanionChat",
      },
      {
        "<leader>ac",
        "<cmd>CodeCompanionActions<cr>",
        silent = true,
        mode = { "n", "v" },
        noremap = true,
        desc = "Toggle CodeCompanionChat",
      },
    },
    config = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      strategies = {
        chat = {
          adapter = "deepseek",
          keymaps = {
            close = {
              modes = { n = "q" },
            },
            stop = {
              modes = { n = "<C-c>" },
            },
          },
        },
        inline = {
          adapter = "deepseek",
          keymaps = {
            accept_change = {
              modes = { n = "ga" },
              description = "Accept the suggested change",
            },
            reject_change = {
              modes = { n = "gr" },
              description = "Reject the suggested change",
            },
          },
        },
      },
      adapters = {
        codellama = function()
          return require("codecompanion.adapters").extend("ollama", {
            name = "codellama",
            schema = {
              model = {
                default = "codellama:7b-instruct-q2_K",
              },
            },
          })
        end,
        deepseek = function()
          return require("codecompanion.adapters").extend("ollama", {
            name = "deepseek",
            schema = {
              model = {
                default = "deepseek-r1:1.5b",
              },
            },
          })
        end,
        qwen = function()
          return require("codecompanion.adapters").extend("ollama", {
            name = "qwen",
            schema = {
              model = {
                default = "qwen2.5:1.5b",
              },
            },
          })
        end,
      },
    },
    init = function()
      require("plugins.custom.ai.codecompanion_noice").init()
      -- Expand 'cc' into 'CodeCompanion' in the command line
      vim.cmd([[cab cc CodeCompanion]])
    end,
  },
}
