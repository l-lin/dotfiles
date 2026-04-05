local function debounce(ms, callback)
  local timer = vim.uv.new_timer()
  return function(...)
    if timer == nil then
      return
    end

    local argv = { ... }
    timer:start(ms, 0, function()
      timer:stop()
      vim.schedule(function()
        callback(unpack(argv))
      end)
    end)
  end
end

local function run_lint()
  local lint = require("lint")
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

local function setup()
  local lint = require("lint")
  lint.linters_by_ft = {
    bash = { "shellcheck" },
    lua = { "selene" },
    markdown = { "markdownlint" },
    nix = { "statix" },
    yaml = { "yamllint" },
  }
  lint.linters.markdownlint.args = {
    "--disable",
    "MD013",
    "--",
  }
  lint.linters.yamllint.args = {
    "-d",
    "{extends: default, rules: {line-length: {max: 120}}}",
    "-f",
    "parsable",
    "-",
  }
end

---@param create_autocmd fun(event: string|string[], opts: table)
local function autocmds(create_autocmd)
  create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
    group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
    callback = debounce(100, run_lint),
  })
end

---@type vim.pack.Spec
return {
  src = "https://github.com/mfussenegger/nvim-lint",
  data = {
    setup = setup,
    autocmds = autocmds,
  },
}
