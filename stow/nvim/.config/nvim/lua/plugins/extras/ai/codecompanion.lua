-- Starting index from 30 so that all my custom prompts are at the bottom.
local idx = 30
local function index()
  idx = idx + 1
  return idx
end

return {
  -- A powerful Neovim plugin for managing MCP (Model Context Protocol) servers: https://github.com/ravitemer/mcphub.nvim#installation
  {
    "ravitemer/mcphub.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "MCPHub",
    keys = {
      { "<leader>am", "<cmd>MCPHub<cr>", silent = true, mode = "n", noremap = true, desc = "Toggle MCPHub" },
    },
    build = "bundled_build.lua",
    opts = {
      use_bundled_binary = true,
    },
  },

  --  ✨ AI-powered coding, seamlessly in Neovim.
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
        mode = { "n", "v" },
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
      -- A code repository indexing tool to supercharge your LLM experience.
      { "Davidyz/VectorCode" },
    },
    opts = {
      strategies = {
        chat = {
          adapter = "copilot_o3_mini",
          keymaps = {
            -- Changing `q` to `C-c` so that `q` just close the window.
            stop = {
              modes = { n = "<C-c>" },
              callback = "keymaps.stop",
              description = "Stop Request",
            },
          },
        },
        inline = { adapter = "copilot" },
      },
      display = {
        chat = {
          start_in_insert_mode = true,
        },
      },

      --
      -- An adapter is what connects Neovim to an LLM. It's the interface that allows data to be sent, received and processed and there are a multitude of ways to customize them.
      -- src: https://codecompanion.olimorris.dev/configuration/adapters.html
      --
      adapters = {
        -- GITHUB COPILOT
        copilot_claude_sonnet_3_5 = function()
          return require("codecompanion.adapters").extend("copilot", {
            name = "copilot_claude_sonnet_3_5",
            schema = {
              model = { default = "claude-3.5-sonnet" },
            },
          })
        end,
        copilot_o3_mini = function()
          return require("codecompanion.adapters").extend("copilot", {
            name = "copilot_o3_mini",
            schema = {
              model = { default = "o3-mini" },
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

      --
      -- Custom prompts to add temp to the Action Palette.
      -- src: https://codecompanion.olimorris.dev/configuration/prompt-library.html
      --
      prompt_library = {
        --
        -- LANGUAGE
        --

        ["inline@improve-english"] = {
          strategy = "inline",
          description = "Improve English wording and grammar",
          opts = {
            index = index(),
            modes = { "v" },
            ignore_system_prompt = true,
            short_name = "inline-improve-english",
            auto_submit = false,
            stop_context_insertion = true,
            user_prompt = false,
            adapter = { name = "copilot" },
          },
          prompts = {
            {
              role = "system",
              content = require("plugins.custom.ai.prompts").improve_english.system,
            },
            {
              role = "user",
              content = function(context)
                local text = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
                return require("plugins.custom.ai.prompts").improve_english.user(text)
              end,
            },
          },
        },
        ["chat@improve-english"] = {
          strategy = "chat",
          description = "Improve English wording and grammar",
          opts = {
            index = index(),
            modes = { "n", "v" },
            ignore_system_prompt = true,
            short_name = "chat-improve-english",
            auto_submit = false,
            stop_context_insertion = true,
            user_prompt = false,
            adapter = { name = "copilot" },
          },
          prompts = {
            {
              role = "system",
              content = require("plugins.custom.ai.prompts").improve_english.system,
            },
            {
              role = "user",
              content = function(context)
                local text = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
                return require("plugins.custom.ai.prompts").improve_english.user(text)
              end,
            },
          },
        },

        --
        -- CODE
        --

        ["chat@review"] = {
          strategy = "chat",
          description = "Review the provided code snippet.",
          opts = {
            index = index(),
            modes = { "v" },
            short_name = "chat-review",
            auto_submit = true,
            user_prompt = false,
            stop_context_insertion = true,
          },
          prompts = {
            {
              role = "system",
              content = require("plugins.custom.ai.prompts").review.system,
              opts = { visible = false },
            },
            {
              role = "user",
              content = function(context)
                local code = require("codecompanion.helpers.actions").get_code(
                  context.start_line,
                  context.end_line,
                  { show_line_numbers = true }
                )
                return require("plugins.custom.ai.prompts").review.user(context.filetype, code)
              end,
              opts = { contains_code = true },
            },
          },
        },
        ["inline@refactor"] = {
          strategy = "inline",
          description = "Refactor the provided code snippet.",
          opts = {
            index = index(),
            modes = { "v" },
            short_name = "inline-refactor",
            auto_submit = true,
            user_prompt = false,
            stop_context_insertion = true,
          },
          prompts = {
            {
              role = "system",
              content = require("plugins.custom.ai.prompts").refactor.system,
              opts = { visible = false },
            },
            {
              role = "user",
              content = function(context)
                local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
                return require("plugins.custom.ai.prompts").refactor.user(context.filetype, code)
              end,
              opts = { contains_code = true },
            },
          },
        },
        ["chat@suggest-better-name"] = {
          strategy = "chat",
          description = "Suggest better name",
          opts = {
            index = index(),
            modes = { "v" },
            short_name = "chat-naming",
            auto_submit = true,
            stop_context_insertion = true,
            user_prompt = false,
          },
          prompts = {
            {
              role = "system",
              content = require("plugins.custom.ai.prompts").suggest_better_name.system,
              opts = { visible = false },
            },
            {
              role = "user",
              content = function(context)
                local code = require("codecompanion.helpers.actions").get_code(
                  context.start_line,
                  context.end_line,
                  { show_line_numbers = true }
                )
                return require("plugins.custom.ai.prompts").suggest_better_name.user(context.filetype, code)
              end,
            },
          },
        },
        ["chat@implement-java-unit-tests"] = {
          strategy = "chat",
          description = "Implement Java unit tests for the selected code.",
          opts = {
            index = index(),
            is_slash_cmd = false,
            modes = { "v" },
            short_name = "chat-implement-java-unit-tests",
            auto_submit = false,
            user_prompt = false,
            stop_context_insertion = true,
          },
          prompts = {
            {
              role = "system",
              content = require("plugins.custom.ai.prompts").implement_java_tests.system,
              opts = { visible = false },
            },
            {
              role = "user",
              content = function(context)
                local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
                return require("plugins.custom.ai.prompts").implement_java_tests.user(code)
              end,
              opts = { contains_code = true },
            },
          },
        },
        ["chat@implement"] = {
          strategy = "chat",
          description = "Implement a feature or a bugfix.",
          opts = {
            index = index(),
            is_slash_cmd = false,
            modes = { "n" },
            short_name = "chat-implement",
            auto_submit = false,
            user_prompt = false,
            stop_context_insertion = true,
          },
          references = {
            {
              type = "file",
              path = require("plugins.custom.ai.prompts").coding_convention_file,
            },
          },
          prompts = {
            {
              role = "system",
              content = require("plugins.custom.ai.prompts").implement.system,
              opts = { visible = false },
            },
            {
              role = "user",
              content = require("plugins.custom.ai.prompts").implement.user(),
              opts = { contains_code = false },
            },
          },
        },
        ["workflow@implement"] = {
          strategy = "workflow",
          description = "Use a workflow to guide an LLM in writing code to implement a feature or a bugfix",
          opts = {
            index = index(),
            short_name = "workflow-implement",
          },
          references = {
            {
              type = "file",
              path = require("plugins.custom.ai.prompts").coding_convention_file,
            },
          },
          prompts = {
            {
              {
                role = "system",
                content = require("plugins.custom.ai.prompts").implement_workflow.system,
                opts = { visible = false },
              },
              {
                role = "user",
                content = function()
                  vim.g.codecompanion_auto_tool_mode = true
                  return require("plugins.custom.ai.prompts").implement_workflow.user()
                end,
                opts = { auto_submit = false },
              },
            },
            {
              {
                role = "user",
                content = "Great. Now let's consider your code. I'd like you to check it carefully for correctness, style, and efficiency, and give constructive criticism for how to improve it.",
                opts = { auto_submit = true },
              },
            },
            {
              {
                role = "user",
                content = "Thanks. Now let's revise the code based on the feedback, without additional explanations.",
                opts = { auto_submit = true },
              },
            },
          },
        },

        --
        -- PROJECT
        --

        ["chat@write-specifications"] = {
          strategy = "chat",
          description = "Chat with the LLM to brainstorm ideas and write specifications.",
          opts = {
            index = index(),
            is_slash_cmd = false,
            modes = { "n" },
            short_name = "chat-write-specifications",
            auto_submit = false,
            user_prompt = false,
            stop_context_insertion = true,
            ignore_system_prompt = true,
          },
          prompts = {
            {
              role = "system",
              content = require("plugins.custom.ai.prompts").write_specifications.system,
              opts = { visible = false },
            },
            {
              role = "user",
              content = require("plugins.custom.ai.prompts").write_specifications.user,
              opts = { contains_code = false },
            },
          },
        },
        ["chat@write-prompt-plans"] = {
          strategy = "chat",
          description = "Write the prompt plans and todo.",
          opts = {
            index = index(),
            is_slash_cmd = false,
            modes = { "n" },
            short_name = "plans",
            auto_submit = false,
            user_prompt = false,
            stop_context_insertion = true,
            ignore_system_prompt = true,
          },
          prompts = {
            {
              role = "system",
              content = require("plugins.custom.ai.prompts").write_prompt_plans.system,
              opts = { visible = false },
            },
            {
              role = "user",
              content = require("plugins.custom.ai.prompts").write_prompt_plans.user,
              opts = { contains_code = false },
            },
          },
        },
        ["chat@brainstorm"] = {
          strategy = "chat",
          description = "Brainstorm ideas for your project.",
          opts = {
            index = index(),
            is_slash_cmd = true,
            modes = { "n" },
            short_name = "brainstorm",
            auto_submit = false,
            user_prompt = false,
            stop_context_insertion = true,
            ignore_system_prompt = true,
          },
          prompts = {
            {
              role = "system",
              content = require("plugins.custom.ai.prompts").write_brainstorm.system,
              opts = { visible = false },
            },
            {
              role = "user",
              content = require("plugins.custom.ai.prompts").write_brainstorm.user(),
              opts = { contains_code = false },
            },
          },
        },
        ["chat@generate-session-summary"] = {
          strategy = "chat",
          description = "Generate session summary",
          opts = {
            index = index(),
            is_slash_cmd = true,
            short_name = "scession-summary",
            auto_submit = false,
          },
          prompts = {
            {
              role = "user",
              content = require("plugins.custom.ai.prompts").generate_session_summary.user(),
              opts = { contains_code = false },
            },
          },
        },
      },

      --
      -- Extensions that add functionalities to the plugin.
      -- src: https://codecompanion.olimorris.dev/configuration/extensions.html
      --
      extensions = {
        vectorcode = {
          opts = { add_tools = true, add_slash_command = true },
        },
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            show_result_in_chat = true,
            make_vars = true,
            make_slash_commands = true,
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
