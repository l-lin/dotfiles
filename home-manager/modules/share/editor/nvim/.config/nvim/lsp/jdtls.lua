local has_jdtls, jdtls = pcall(require, "jdtls")
if not has_jdtls then
  return {}
end

local common = require("config.lsp.common")
local java_config = require("config.lsp.java")

jdtls.extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

---@type vim.lsp.Config
return {
  cmd = java_config.create_cmd(),
  filetypes = { "java" },
  init_options = java_config.create_init_options(),
  root_dir = function(bufnr, on_dir)
    vim.api.nvim_buf_call(bufnr, function()
      on_dir(require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew" }))
    end)
  end,
  settings = java_config.create_settings(),

  flags = { allow_incremental_sync = true },
  workspace_required = true,

  capabilities = vim.tbl_deep_extend("force", common.create_capabilities(), java_config.capabilities or {}),
  on_attach = function(client, bufnr)
    common.on_attach(client, bufnr)
    java_config.on_attach(client, bufnr)
  end,
}
