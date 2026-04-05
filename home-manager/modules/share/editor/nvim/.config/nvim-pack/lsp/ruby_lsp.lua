return {
  cmd = function(dispatchers, config)
    return vim.lsp.rpc.start(
      { "ruby-lsp" },
      dispatchers,
      config and config.root_dir and { cwd = config.cmd_cwd or config.root_dir }
    )
  end,
  filetypes = { "ruby", "eruby" },
  init_options = {
    formatter = "auto",
  },
  reuse_client = function(client, config)
    config.cmd_cwd = config.root_dir
    return client.config.cmd_cwd == config.cmd_cwd
  end,
  root_markers = { "Gemfile", ".git" },
}
