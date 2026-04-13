---@type vim.lsp.Config
return {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
  root_markers = { ".git" },
  before_init = function(_, new_config)
    new_config.settings = new_config.settings or {}
    new_config.settings.yaml = new_config.settings.yaml or {}
    local has_schemastore, schemastore = pcall(require, "schemastore")
    if has_schemastore and schemastore.yaml ~= nil and type(schemastore.yaml.schemas) == "function" then
      new_config.settings.yaml.schemas = vim.tbl_deep_extend(
        "force",
        new_config.settings.yaml.schemas or {},
        schemastore.yaml.schemas()
      )
    end
  end,
  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = true
  end,
  capabilities = {
    textDocument = {
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      },
    },
  },
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      format = { enable = true },
      keyOrdering = false,
      schemaStore = {
        enable = false,
        url = "",
      },
      validate = true,
    },
  },
}
