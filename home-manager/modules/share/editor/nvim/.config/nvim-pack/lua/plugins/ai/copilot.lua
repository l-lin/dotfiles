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
end

---@param map fun(mode: string|string[], lhs: string, rhs: string|function, opts?: table)
local function keymaps(map)
  map("n", "<leader>ad", "<cmd>Copilot disable<cr>", {
    desc = "Disable (Copilot)",
    silent = true,
  })
  map("n", "<leader>ae", "<cmd>Copilot enable<cr>", {
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
  {
    src = "https://github.com/zbirenbaum/copilot.lua",
    data = {
      setup = setup,
      keymaps = keymaps,
    },
  },
}
