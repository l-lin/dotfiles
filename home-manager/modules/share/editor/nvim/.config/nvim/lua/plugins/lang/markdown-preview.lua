local function install_dependencies(plugin_path)
  -- The server preloads msgpack-lite, but upstream only declares it in the root package.json.
  local result = vim.system({
    "npm",
    "install",
    "--omit=dev",
    "--no-save",
    "--no-package-lock",
    "--no-audit",
    "--no-fund",
    "msgpack-lite@^0.1.26",
  }, { cwd = plugin_path .. "/app", text = true }):wait()
  if result.code ~= 0 then
    error("markdown-preview.nvim: npm install failed\n" .. result.stderr)
  end
end

-- Register before vim.pack.add so the first install is built too.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(event)
    local name = event.data.spec.name
    local kind = event.data.kind
    if name == "markdown-preview.nvim" and (kind == "install" or kind == "update") then
      install_dependencies(event.data.path)
    end
  end,
})

local function setup()
  local plugin_path = vim.pack.get({ "markdown-preview.nvim" }, { info = false })[1].path
  -- Existing installs will not emit PackChanged; load the server's dependencies to detect a missing build.
  local result = vim.system({ "node", plugin_path .. "/app/index.js", "--version" }, { text = true }):wait()
  if result.code ~= 0 then
    install_dependencies(plugin_path)
  end

  vim.keymap.set("n", "<leader>oO", "<cmd>MarkdownPreviewToggle<cr>", {
    desc = "Markdown Preview",
    noremap = true,
  })
end

---@type vim.pack.Spec
return
-- markdown preview plugin for (neo)vim
{
  src = "https://github.com/iamcco/markdown-preview.nvim",
  data = { setup = setup },
}
