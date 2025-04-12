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
        "<leader>an",
        "<cmd>CodeCompanionChat<cr>",
        silent = true,
        mode = "n",
        noremap = true,
        desc = "New CodeCompanionChat",
      },
      {
        "<leader>ac",
        "<cmd>CodeCompanionActions<cr>",
        silent = true,
        mode = { "n", "v" },
        noremap = true,
        desc = "Toggle CodeCompanionActions",
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
          adapter = "copilot_claude_sonnet_3_7",
          keymaps = {
            stop = {
              modes = { n = "<C-c>" },
            },
          },
        },
        inline = {
          adapter = "copilot_claude_sonnet_3_7",
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
        -- GITHUB COPILOT
        copilot_claude_sonnet_3_7 = function()
          return require("codecompanion.adapters").extend("copilot", {
            name = "copilot_claude_sonnet_3_7",
            schema = {
              model = { default = "claude-3.7-sonnet" },
            },
          })
        end,
        -- OLLAMA
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
              model = { default = "deepseek-r1:7b" },
            },
          })
        end,
        gemma3 = function()
          return require("codecompanion.adapters").extend("ollama", {
            name = "gemma3",
            schema = {
              model = { default = "gemma3:4b" },
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
              model = { default = "qwen2.5:7b" },
            },
          })
        end,
        qwen2_5_coder = function()
          return require("codecompanion.adapters").extend("ollama", {
            name = "qwen2_5_coder",
            schema = {
              model = { default = "qwen2.5-coder:7b" },
            },
          })
        end,
      },
      prompt_library = {
        ["English Improver"] = {
          strategy = "inline",
          description = "Improve English wording and grammar",
          opts = {
            modes = { "v" },
            short_name = "improve_english",
            auto_submit = false,
            stop_context_insertion = true,
            user_prompt = false,
          },
          prompts = {
            {
              role = "system",
              content = "Act as an English language expert. Your task is to improve the wording and grammar of the provided text while preserving its original meaning.",
            },
            {
              role = "user",
              content = function(context)
                local text = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)

                return "Please improve the following text:\n\n" .. text .. "\n\n"
              end,
            },
          },
        },
        ["Suggest better names"] = {
          strategy = "chat",
          description = "Suggest better name",
          opts = {
            modes = { "v" },
            short_name = "suggest_better_name",
            auto_submit = true,
            stop_context_insertion = true,
            user_prompt = false,
          },
          prompts = {
            {
              role = "user",
              content = function(context)
                local text = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)

                return string.format(
                  [[Take all variable and function names, and provide only a list with suggestions with improved naming.:
```%s
%s
```
]],
                  context.filetype,
                  text
                )
              end,
            },
          },
        },
      },
    },
    init = function()
      require("plugins.custom.ai.codecompanion-noice").init()
      -- Expand 'cc' into 'CodeCompanion' in the command line
      vim.cmd([[cab cc CodeCompanion]])
      vim.cmd([[cab ccc CodeCompanionChat]])
    end,
  },
}
