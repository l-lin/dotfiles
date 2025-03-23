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
          adapter = "gemma3",
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
          adapter = "qwen2_5_coder",
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
              model = { default = "codellama:7b-instruct-q2_K" },
            },
          })
        end,
        deepseek_r1 = function()
          return require("codecompanion.adapters").extend("ollama", {
            name = "deepseek",
            schema = {
              model = { default = "deepseek-r1:1.5b" },
            },
          })
        end,
        gemma3 = function()
          return require("codecompanion.adapters").extend("ollama", {
            name = "gemma3",
            schema = {
              model = { default = "gemma3:1b" },
            },
          })
        end,
        phi3 = function()
          return require("codecompanion.adapters").extend("ollama", {
            name = "phi3",
            schema = {
              model = { default = "phi3:3.8b-mini-4k-instruct-q4_0" },
            },
          })
        end,
        phi3_5 = function()
          return require("codecompanion.adapters").extend("ollama", {
            name = "phi3_5",
            schema = {
              model = { default = "phi3.5:3.8b-mini-instruct-q4_0" },
            },
          })
        end,
        qwen2_5 = function()
          return require("codecompanion.adapters").extend("ollama", {
            name = "qwen2_5",
            schema = {
              model = { default = "qwen2.5:1.5b" },
            },
          })
        end,
        qwen2_5_coder = function()
          return require("codecompanion.adapters").extend("ollama", {
            name = "qwen2_5_coder",
            schema = {
              model = { default = "qwen2.5-coder:1.5b" },
            },
          })
        end,
      },
    },
    init = function()
      require("plugins.custom.ai.codecompanion-noice").init()
      -- Expand 'cc' into 'CodeCompanion' in the command line
      vim.cmd([[cab cc CodeCompanion]])
    end,
  },
}
