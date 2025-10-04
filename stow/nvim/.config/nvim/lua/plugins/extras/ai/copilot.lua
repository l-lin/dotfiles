return {
  -- #######################
  -- override default config
  -- #######################
  {
    "zbirenbaum/copilot.lua",
    dependencies = {
      -- Enable Copilot Next Edit Suggestions.
      "copilotlsp-nvim/copilot-lsp",
      init = function()
        vim.g.copilot_nes_debounce = 300
      end,
    },
    cmd = "Copilot",
    keys = {
      {
        "<leader>ad",
        "<cmd>Copilot disable<cr>",
        silent = true,
        mode = "n",
        desc = "Disable (Copilot)",
      },
      {
        "<leader>ae",
        "<cmd>Copilot enable<cr>",
        silent = true,
        mode = "n",
        desc = "Enable (Copilot)",
      },
    },
    filetypes = {
      markdown = false,
      help = false,
    },
    copilot_model = "gpt-4.1",
    init = function()
      -- Disable copilot by default, only enable when needed.
      vim.cmd("silent! Copilot disable")
    end,
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      server_opts_overrides = {
        settings = {
          telemetry = {
            telemetryLevel = "off",
          },
        },
      },
      nes = {
        enabled = true,
        keymap = {
          accept_and_goto = "<C-e>",
          accept = false,
          dismiss = "<Esc>",
        },
      },
    },
  },

  -- #######################
  -- add new plugins
  -- #######################

  -- ⚙️ Configurable GitHub Copilot blink.cmp source for Neovim.
  -- Give more suggestions than blink-cmp-copilot
  {
    "giuxtaposition/blink-cmp-copilot",
    enabled = false,
  },
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "fang2hou/blink-copilot" },
    opts = {
      sources = {
        providers = {
          copilot = {
            module = "blink-copilot",
          },
        },
      },
    },
  },
}
