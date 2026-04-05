vim.g.copilot_nes_debounce = 300

--
-- Fully featured & enhanced replacement for copilot.vim complete with API for interacting with Github Copilot.
--
vim.cmd("silent! Copilot disable")

--
-- Setup
--
require("copilot").setup({
  filetypes = {
    help = false,
    markdown = false,
  },
  nes = {
    enabled = true,
    keymap = {
      accept = false,
      accept_and_goto = "<C-e>",
      dismiss = "<Esc>",
    },
  },
  panel = { enabled = false },
  server_opts_overrides = {
    settings = {
      telemetry = {
        telemetryLevel = "off",
      },
    },
  },
  suggestion = { enabled = false },
})

--
-- Keymaps
--
local map = vim.keymap.set
map("n", "<leader>ad", "<cmd>Copilot disable<cr>", {
  desc = "Disable (Copilot)",
  silent = true,
})
map("n", "<leader>ae", "<cmd>Copilot enable<cr>", {
  desc = "Enable (Copilot)",
  silent = true,
})
