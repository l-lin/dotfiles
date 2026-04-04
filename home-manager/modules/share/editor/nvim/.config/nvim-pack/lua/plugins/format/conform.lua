--
-- Lightweight yet powerful formatter plugin for Neovim
--

require("conform").setup({
  default_format_opts = {
    async = false,
    lsp_format = "fallback",
    quiet = false,
    timeout_ms = 3000,
  },
  formatters = {
    shfmt = {
      prepend_args = { "-i", "2", "-ci" },
    },
  },
  formatters_by_ft = {
    bash = { "shfmt" },
    css = { "prettier" },
    fish = { "fish_indent" },
    html = { "prettier" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    less = { "prettier" },
    lua = { "stylua" },
    markdown = { "prettier" },
    python = { "ruff_format" },
    scss = { "prettier" },
    sh = { "shfmt" },
    toml = { "taplo" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    yaml = { "prettier" },
  },
})

vim.keymap.set({ "n", "x" }, "<leader>cf", function()
  require("conform").format({ async = false, lsp_format = "fallback" }, function(err)
    if not err then
      vim.notify("File formatted", vim.log.levels.INFO)
    else
      vim.notify("No formatter available for this filetype", vim.log.levels.WARN)
    end
  end)
end, { desc = "Format" })
