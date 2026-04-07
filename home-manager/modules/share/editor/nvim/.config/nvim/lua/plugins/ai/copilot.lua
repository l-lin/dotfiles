local function setup()
  vim.g.copilot_nes_debounce = 300

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

  vim.cmd("silent! Copilot disable")

  vim.keymap.set("n", "<leader>ad", "<cmd>Copilot disable<cr>", {
    desc = "Disable (Copilot)",
    silent = true,
  })
  vim.keymap.set("n", "<leader>ae", "<cmd>Copilot enable<cr>", {
    desc = "Enable (Copilot)",
    silent = true,
  })
end

---@type vim.pack.Spec[]
return {
  -- For NES functionality
  {
    src = "https://github.com/copilotlsp-nvim/copilot-lsp",
  },
  -- Fully featured & enhanced replacement for copilot.vim complete with API for interacting with Github Copilot
  {
    src = "https://github.com/zbirenbaum/copilot.lua",
    data = {
      setup = function()
        vim.schedule(setup)
      end,
    },
  },
}
