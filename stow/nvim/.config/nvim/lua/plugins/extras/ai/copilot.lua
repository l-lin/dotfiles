
return {
  -- #######################
  -- override default config
  -- #######################
  {
    "zbirenbaum/copilot.lua",
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
    copilot_model = "claude-3.7-sonnet",
    init = function()
      -- Disable copilot by default, only enable when needed.
      vim.cmd("silent! Copilot disable")
    end,
  },
}
