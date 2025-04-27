local coding_convention_file = vim.env.HOME .. "/.config/ai/conventions/code.md"

return {
  -- A code repository indexing tool to supercharge your LLM experience.
  {
    "Davidyz/VectorCode",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "VectorCode",
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
        ["English Improver"] = {
          strategy = "inline",
          description = "Improve English wording and grammar",
          opts = {
            modes = { "v" },
            short_name = "improve_english",
            auto_submit = false,
            stop_context_insertion = true,
            user_prompt = false,
            adapter = { name = "copilot" },
          },
          prompts = {
            {
              role = "system",
              content = require("plugins.custom.ai.prompts").english,
            },
            {
              role = "user",
              content = function(context)
                local text = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
                return string.format(
                  [[Please improve the following text:
```
%s
```
]],
                  text
                )
              end,
            },
          },
        },
        ["Review"] = {
          strategy = "chat",
          description = "Review the provided code snippet.",
          opts = {
            modes = { "v" },
            short_name = "review",
            auto_submit = true,
            user_prompt = false,
            stop_context_insertion = true,
          },
          prompts = {
            {
              role = "system",
              content = require("plugins.custom.ai.prompts").review,
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
                return string.format(
                  [[Please review the following code and provide suggestions for improvement then refactor the following code to improve its clarity and readability:

```%s
%s
```
]],
                  context.filetype,
                  code
                )
              end,
              opts = { contains_code = true },
            },
          },
        },
        ["Refactor"] = {
          strategy = "inline",
          description = "Refactor the provided code snippet.",
          opts = {
            modes = { "v" },
            short_name = "refactor",
            auto_submit = true,
            user_prompt = false,
            stop_context_insertion = true,
          },
          prompts = {
            {
              role = "system",
              content = require("plugins.custom.ai.prompts").refactor,
              opts = { visible = false },
            },
            {
              role = "user",
              content = function(context)
                local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)

                return string.format(
                  [[Please refactor the following code to improve its clarity and readability:
```%s
%s
```
]],
                  context.filetype,
                  code
                )
              end,
              opts = { contains_code = true },
            },
          },
        },
        ["Naming"] = {
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
              role = "system",
              content = require("plugins.custom.ai.prompts").review,
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

                return string.format(
                  [[Take all variable and function names, and provide only a list with suggestions with improved naming.:
```%s
%s
```
]],
                  context.filetype,
                  code
                )
              end,
            },
          },
        },
        ["Java Unit Tests"] = {
          strategy = "chat",
          description = "Generate Java unit tests for the selected code",
          opts = {
            is_slash_cmd = false,
            modes = { "v" },
            short_name = "java-tests",
            auto_submit = false,
            user_prompt = false,
            stop_context_insertion = true,
          },
          prompts = {
            {
              role = "system",
              content = require("plugins.custom.ai.prompts").java_test,
              opts = { visible = false },
            },
            {
              role = "user",
              content = function(context)
                local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)

                return string.format(
                  [[Please generate Java unit tests for this code from #buffer:

```%s
%s
```

Use the @files tool to create or edit the test file in the file `%s/%s`.
]],
                  context.filetype,
                  code,
                  vim.fn.getcwd(),
                  require("plugins.custom.coding.subject").find_subject()
                )
              end,
              opts = { contains_code = true },
            },
          },
        },
        ["Feature workflow"] = {
          strategy = "workflow",
          description = "Use a workflow to guide an LLM in writing code to implement a feature",
          opts = { short_name = "fw" },
          references = {
            {
              type = "file",
              path = coding_convention_file,
            },
          },
          prompts = {
            {
              {
                role = "system",
                content = function()
                  return [[You carefully provide accurate, factual, thoughtful, nuanced answers, and are brilliant at reasoning.
If you think there might not be a correct answer, you say so.
Always spend a few sentences explaining background context, assumptions, and step-by-step thinking BEFORE you try to answer a question.
Don't be verbose in your answers, but do provide details and examples where it might help the explanation.
You are an expert software engineer.]]
                end,
                opts = { visible = false },
              },
              {
                role = "user",
                content = function()
                  vim.g.codecompanion_auto_tool_mode = true
                  return string.format(
                    [[### Requirements
#### General overview

TODO

#### Coding convention

Please follow the coding convention at: %s.

### Steps to Follow

You are required to write code following the instructions provided above and test the correctness. Follow these steps exactly:

1. Ask up to 3 questions you need to clarify the requirements
2. Once you are ready, use the @full_stack_dev tool to implement the requirements
  - Create/update/delete files only on the project directory %s
  - Be sure to follow the coding conventions when implementing the requirements
3. Then use the @cmd_runner tool to run the test suite with `<test_cmd>` (do this after you have updated the code)

Ensure no deviations from these steps.]],
                    coding_convention_file,
                    vim.fn.getcwd()
                  )
                end,
                opts = {
                  auto_submit = false,
                },
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
