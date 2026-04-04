--
-- An asynchronous linter plugin for Neovim complementary to the built-in Language Server Protocol support.
--

--
-- Setup
--
local lint = require("lint")
lint.linters_by_ft = {
  bash = { 'shellcheck' },
  lua = { 'selene' },
  markdown = { 'markdownlint' },
  yaml = { 'yamllint' },
}
-- Disable line-length rule
lint.linters.markdownlint.args = {
  '--disable',
  'MD013',
  '--',
}
-- Custom yamllint config
lint.linters.yamllint.args = {
  '-d',
  '{extends: default, rules: {line-length: {max: 120}}}',
  '-f',
  'parsable',
  '-',
}

--
-- Autocmds
--
--
local function debounce(ms, fn)
  local timer = vim.uv.new_timer()
  return function(...)
    if timer == nil then
      return
    end

    local argv = { ... }
    timer:start(ms, 0, function()
      timer:stop()
      vim.schedule(function()
        fn(unpack(argv))
      end)
    end)
  end
end

local function run_lint()
  local names = lint._resolve_linter_by_ft(vim.bo.filetype)
  names = vim.list_extend({}, names)
  if #names == 0 then
    vim.list_extend(names, lint.linters_by_ft._ or {})
  end
  vim.list_extend(names, lint.linters_by_ft["*"] or {})

  local ctx = { filename = vim.api.nvim_buf_get_name(0) }
  ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
  names = vim.tbl_filter(function(name)
    local linter = lint.linters[name]
    return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
  end, names)

  if #names > 0 then
    lint.try_lint(names)
  end
end

vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
  group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
  callback = debounce(100, run_lint),
})
