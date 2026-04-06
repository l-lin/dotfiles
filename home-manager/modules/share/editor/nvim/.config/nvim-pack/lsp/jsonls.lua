return {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  init_options = {
    provideFormatter = true,
  },
  root_markers = { ".git" },
  before_init = function(_, new_config)
    new_config.settings = new_config.settings or {}
    new_config.settings.json = new_config.settings.json or {}
    new_config.settings.json.schemas = new_config.settings.json.schemas or {}

    local has_schemastore, schemastore = pcall(require, "schemastore")
    if has_schemastore then
      vim.list_extend(new_config.settings.json.schemas, schemastore.json.schemas())
    end
  end,
  settings = {
    json = {
      format = { enable = true },
      validate = { enable = true },
    },
  },
}
