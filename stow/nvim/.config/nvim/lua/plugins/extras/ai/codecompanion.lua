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

  -- Embed images into any markup language, like LaTeX, Markdown or Typst
  {
    "HakonHarnes/img-clip.nvim",
    optional = true,
    opts = {
      filetypes = {
        codecompanion = {
          prompt_for_file_name = false,
          template = "[Image]($FILE_PATH)",
          use_absolute_path = true,
        },
      },
    },
  },

  -- ✨ AI-powered coding, seamlessly in Neovim.
  {
    "olimorris/codecompanion.nvim",
    cmd = {
      "CodeCompanion",
      "CodeCompanionChat",
      "CodeCompanionCmd",
      "CodeCompanionActions",
    },
    keys = {
      { "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
      {
        "<leader>aa",
        "<cmd>'<,'>CodeCompanionChat Add<cr>",
        silent = true,
        mode = "x",
        noremap = true,
        desc = "CodeCompanionChat Add",
      },
      {
        "<leader>at",
        "<cmd>CodeCompanionChat toggle<cr>",
        silent = true,
        mode = { "n", "v" },
        noremap = true,
        desc = "CodeCompanionChat Toggle",
      },
      {
        "<leader>an",
        "<cmd>CodeCompanionChat<cr>",
        silent = true,
        mode = { "n", "v" },
        noremap = true,
        desc = "CodeCompanionChat New",
      },
      {
        "<leader>ac",
        "<cmd>CodeCompanionActions<cr>",
        silent = true,
        mode = { "n", "v" },
        noremap = true,
        desc = "CodeCompanionActions",
      },
    },
    config = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- 📄 Utility extension to get all project files for your AI assistant
      { "banjo/contextfiles.nvim" },
      -- History chat management
      { "ravitemer/codecompanion-history.nvim" },
    },
    opts = function ()
      -- Open CodeCompanion in full screen/buffer, to provide the same
      -- experience as the other TUI tools.
      -- src: https://github.com/olimorris/codecompanion.nvim/discussions/1828
      local layout = vim.env.CC_LAYOUT_OVERRIDE or "vertical"
      return {
        strategies = {
          chat = {
            adapter = "copilot_custom",
            keymaps = {
              -- Changing `q` to `<C-c>` so that `q` just close the window.
              stop = {
                modes = { n = "<C-c>", i = "<C-c>" },
                callback = "keymaps.stop",
                description = "Stop Request",
              },
              -- `<C-c>` was used to close the chat. And I cannot disabled it, so using a keymap I'm never using.
              close = {
                modes = { n = "gc" },
                callback = "keymaps.close",
                description = "Close Chat",
              },
              codeblock = {
                modes = { i = "<A-c>" },
                callback = "keymaps.codeblock",
                description = "Insert Codeblock",
              },
            },
            roles = {
              ---@type string|fun(adapter: CodeCompanion.Adapter): string
              llm = function(adapter)
                local model_name = adapter.model.name or ""
                if model_name ~= "" then
                  model_name = " (" .. model_name .. ")"
                end
                return adapter.formatted_name .. model_name
              end,
              ---@type string
              user = "" .. os.getenv("USER"),
            },
            slash_commands = require("plugins.custom.ai.codecompanion.slash-commands"),
            tools = {
              default_tools = { "insert_edit_into_file" },
              opts = {
                -- Send any errors to the LLM automatically
                auto_submit_errors = true,
                -- Send any successful output to the LLM automatically
                auto_submit_success = true,
              },
              plan = {
                callback = require("plugins.custom.ai.codecompanion.tools.plan"),
                description = "Manage an internal todo list",
              },
            },
          },
          inline = { adapter = "copilot" },
        },
        display = {
          chat = {
            intro_message = "Press ? for options.",
            start_in_insert_mode = false,
            window = { layout = layout }
          },
        },
        opts = { system_prompt = require("plugins.custom.ai.prompts.system-prompt").get() },

        --
        -- An adapter is what connects Neovim to an LLM. It's the interface that allows data to be sent, received and processed and there are a multitude of ways to customize them.
        -- src: https://codecompanion.olimorris.dev/configuration/adapters.html
        --
        adapters = require("plugins.custom.ai.codecompanion.adapters"),

        --
        -- Custom prompts to add to the Action Palette.
        -- src: https://codecompanion.olimorris.dev/configuration/prompt-library.html
        --
        prompt_library = require("plugins.custom.ai.codecompanion.prompts-library"),

        --
        -- Extensions that add functionalities to the plugin.
        -- src: https://codecompanion.olimorris.dev/configuration/extensions.html
        --
        extensions = {
          mcphub = {
            callback = "mcphub.extensions.codecompanion",
            opts = {
              show_result_in_chat = true,
              make_vars = true,
              make_slash_commands = true,
            },
          },
          contextfiles = {
            opts = {},
          },
          history = {
            enabled = true,
            opts = {
              picker = "snacks",
            },
          },
          ["chat-edit-live"] = {},
        },
      }
    end,
    init = function()
      require("plugins.custom.ai.codecompanion.noice").init()
      -- Expand 'cc' into 'CodeCompanion' in the command line
      vim.cmd([[cab cc CodeCompanion]])
      vim.cmd([[cab ccc CodeCompanionChat]])
    end,
  },

  -- Hide the XML tag in the context section.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      overrides = {
        filetype = {
          codecompanion = {
            heading = {
              icons = { "󰎤 ", "   ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
              custom = {
                codecompanion_input = {
                  pattern = "^## " .. os.getenv("USER") .. "$",
                  icon = " ",
                },
              },
            },
            html = {
              tag = {
                buf = {
                  icon = "󰌹 ",
                  highlight = "Comment",
                },
                file = {
                  icon = "󰨸 ",
                  highlight = "Comment",
                },
                group = {
                  icon = "󰡉 ",
                  highlight = "Comment",
                },
                image = {
                  icon = "󰥶 ",
                  highlight = "Comment",
                },
                role = {
                  icon = "󱢙 ",
                  highlight = "Comment",
                },
                tool = {
                  icon = " ",
                  highlight = "Comment",
                },
                url = {
                  icon = " ",
                  highlight = "Comment",
                },
              },
            },
          },
        },
      },
    },
  },
}
