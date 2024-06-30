local function nvim_lspconfig_init()
  -- keymaps for lspconfig must be set in init function: https://www.lazyvim.org/plugins/lsp#%EF%B8%8F-customizing-lsp-keymaps
  local keys = require("lazyvim.plugins.lsp.keymaps").get()

  -- disable code action keymaps (conflict with Diffview merge tool)
  keys[#keys + 1] = { "<leader>ca", false }
  keys[#keys + 1] = { "<leader>cA", false }

  keys[#keys + 1] = {
    "<C-b>",
    function()
      require("telescope.builtin").lsp_definitions({ reuse_win = true })
    end,
    noremap = true,
    silent = true,
    desc = "Goto definition (Ctrl+b)",
  }
  keys[#keys + 1] = {
    "<M-&>",
    function()
      require("telescope.builtin").lsp_references({ show_line = false })
    end,
    noremap = true,
    desc = "LSP references (Ctrl+Shift+7)",
  }
  keys[#keys + 1] = { "<F18>", vim.lsp.buf.rename, noremap = true, desc = "Rename" }
  keys[#keys + 1] = { "<M-CR>", vim.lsp.buf.code_action, noremap = true, desc = "Code action" }
  keys[#keys + 1] = {
    "<M-C-B>",
    function()
      require("telescope.builtin").lsp_implementations({ reuse_win = true, show_line = false })
    end,
    "Goto implementation (Ctrl+Alt+b)",
  }
end

return {
  -- easily config neovim lsp
  {
    "neovim/nvim-lspconfig",
    init = nvim_lspconfig_init,
    opts = {
      inlay_hints = {
        enabled = true,
      },
    },
  },
  -- easily install/update lsp servers directly from neovim
  {
    "williamboman/mason.nvim",
    cmd = { "MasonInstall", "MasonInstallAll" },
    keys = {
      { "<leader>vm", "<cmd>Mason<cr>", noremap = true, desc = "Open Mason" },
    },
  },
}
