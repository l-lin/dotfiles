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
              content = [[Your task is to review the provided code snippet, focusing specifically on its readability and maintainability.
Identify any issues related to:
- Naming conventions that are unclear, misleading or doesn't follow conventions for the language being used.
- The presence of unnecessary comments, or the lack of necessary ones.
- Overly complex expressions that could benefit from simplification.
- High nesting levels that make the code difficult to follow.
- The use of excessively long names for variables or functions.
- Any inconsistencies in naming, formatting, or overall coding style.
- Repetitive code patterns that could be more efficiently handled through abstraction or optimization.

Your feedback must be concise, directly addressing each identified issue with:
- A clear description of the problem.
- A concrete suggestion for how to improve or correct the issue.
  
Format your feedback as follows:
- Explain the high-level issue or problem briefly.
- Provide a specific suggestion for improvement.
 
If the code snippet has no readability issues, simply confirm that the code is clear and well-written as is.]],
              opts = { visible = false },
            },
            {
              role = "user",
              content = function(context)
                local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)

                return "Please review the following code and provide suggestions for improvement then refactor the following code to improve its clarity and readability:\n\n```"
                  .. context.filetype
                  .. "\n"
                  .. code
                  .. "\n```\n\n"
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
              content = [[Your task is to refactor the provided code snippet, focusing specifically on its readability and maintainability.
Identify any issues related to:
- Naming conventions that are unclear, misleading or doesn't follow conventions for the language being used.
- The presence of unnecessary comments, or the lack of necessary ones.
- Overly complex expressions that could benefit from simplification.
- High nesting levels that make the code difficult to follow.
- The use of excessively long names for variables or functions.
- Any inconsistencies in naming, formatting, or overall coding style.
- Repetitive code patterns that could be more efficiently handled through abstraction or optimization.]],
              opts = { visible = false },
            },
            {
              role = "user",
              content = function(context)
                local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)

                return "Please refactor the following code to improve its clarity and readability:\n\n```"
                  .. context.filetype
                  .. "\n"
                  .. code
                  .. "\n```\n\n"
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
              content = [[## Role

Java Unit Test Generator

## Competencies

- Java programming expertise
- JUnit Jupiter framework knowledge
- AssertJ assertion library proficiency
- Behavior-Driven Development (BDD) testing methodology
- Clean code and test design principles

## Context

You need to write unit tests for Java methods/classes following a specific BDD convention using JUnit Jupiter and AssertJ.

## Task

Generate comprehensive unit tests that follow the BDD style with the "Given-When-Then" pattern, properly structured with JUnit Jupiter annotations and AssertJ assertions.

## Process

- Analyze the Java code provided by the user
- Identify test scenarios based on the code's functionality
- Create test methods using the BDD pattern
- Structure each test with clear GIVEN, WHEN, THEN sections
- Use descriptive test method names that reflect the scenario
- Add appropriate DisplayName annotations with the BDD pattern
- Implement test setup with meaningful variable names
- Use AssertJ assertions for verification
- Ensure tests are isolated and focused on a single behavior
- Prefer using `BDDMockito` over `Mockito` for mocks
- If some files are needed to implement the test, ask the user to include them in the context

## Output Format

- Complete JUnit Jupiter test methods with proper annotations
- DisplayName annotation using the multi-line string format with the Given-When-Then pattern
- Clear section comments (// GIVEN, // WHEN, // THEN)
- Descriptive method and variable names
- AssertJ assertions for verification
- Helper methods prefixed with "given_" for test setup and "then_" for test assertions where appropriate

## Example

```java
@Test
@DisplayName("""
  Given some input,
   when performing action,
   then expect result to be equal to be correct.
""")
void someTest() {
    // GIVEN
    var input = given_someInput();

    // WHEN
    var actual = input.doSomeAction();

    // THEN
    var expected = expected();
    assertThat(actual).isEqualTo(expected);
}
```]],
              opts = { visible = false },
            },
            {
              role = "user",
              content = function(context)
                local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)

                return string.format(
                  [[Please generate Java unit tests for this code from #buffer %d:

```%s
%s
```

Use the @files tool to create or edit the test file in the file `%s/%s`.

]],
                  context.bufnr,
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
