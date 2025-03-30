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
      prompt_library = {
        ["Code Expert"] = {
          strategy = "chat",
          description = "Get some special advice from an LLM",
          opts = {
            modes = { "v" },
            short_name = "code_expert",
            auto_submit = false,
            stop_context_insertion = true,
            user_prompt = true,
          },
          prompts = {
            {
              role = "system",
              content = function(context)
                return "I want you to act as a senior "
                  .. context.filetype
                  .. " developer. I will ask you specific questions and I want you to return concise explanations and codeblock examples."
              end,
            },
            {
              role = "user",
              content = function(context)
                local text = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)

                return "I have the following code:\n\n```" .. context.filetype .. "\n" .. text .. "\n```\n\n"
              end,
              opts = {
                contains_code = true,
              },
            },
          },
        },
        ["English Improver"] = {
          strategy = "chat",
          description = "Improve English wording and grammar",
          opts = {
            modes = { "v" },
            short_name = "improve_english",
            auto_submit = false,
            stop_context_insertion = true,
            user_prompt = true,
          },
          prompts = {
            {
              role = "system",
              content = "I want you to act as an English language expert. Your task is to improve the wording and grammar of the provided text while maintaining its original meaning.",
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
      },
    },
    init = function()
      require("plugins.custom.ai.codecompanion-noice").init()
      -- Expand 'cc' into 'CodeCompanion' in the command line
      vim.cmd([[cab cc CodeCompanion]])
    end,
  },
}
