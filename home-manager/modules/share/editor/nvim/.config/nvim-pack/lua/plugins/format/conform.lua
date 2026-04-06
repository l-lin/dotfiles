local supported_prettier_filetypes = {
  "css",
  "graphql",
  "handlebars",
  "html",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "less",
  "markdown",
  "markdown.mdx",
  "scss",
  "typescript",
  "typescriptreact",
  "vue",
  "yaml",
}

---@param ctx { buf: integer, filename: string, dirname: string }
local function has_prettier_config(ctx)
  vim.fn.system({ "prettier", "--find-config-path", ctx.filename })
  return vim.v.shell_error == 0
end

---@param ctx { buf: integer, filename: string, dirname: string }
local function has_prettier_parser(ctx)
  local filetype = vim.bo[ctx.buf].filetype
  if vim.tbl_contains(supported_prettier_filetypes, filetype) then
    return true
  end

  local result = vim.fn.system({ "prettier", "--file-info", ctx.filename })
  local ok, parser = pcall(function()
    return vim.fn.json_decode(result).inferredParser
  end)
  return ok and parser and parser ~= vim.NIL
end

local function setup()
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
      prettier = {
        condition = function(_, ctx)
          local requires_config = vim.g.nvim_pack_prettier_needs_config == true
          return has_prettier_parser(ctx) and (not requires_config or has_prettier_config(ctx))
        end,
      },
    },
    formatters_by_ft = {
      bash = { "shfmt" },
      css = { "prettier" },
      fish = { "fish_indent" },
      graphql = { "prettier" },
      handlebars = { "prettier" },
      html = { "prettier" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
      less = { "prettier" },
      lua = { "stylua" },
      markdown = { "prettier" },
      ["markdown.mdx"] = { "prettier" },
      nix = { "nixfmt" },
      python = { "ruff_format" },
      scss = { "prettier" },
      sh = { "shfmt" },
      toml = { "taplo" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      vue = { "prettier" },
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
end

---@type vim.pack.Spec
return {
  src = "https://github.com/stevearc/conform.nvim",
  data = { setup = setup },
}
