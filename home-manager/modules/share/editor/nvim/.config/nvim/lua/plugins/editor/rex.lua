if not vim.env.REX_BLOCK then
  return {}
end

-- Rex reports the TUI process, not the embedded Neovim server.
local function start_server(info)
  local client = info.client
  if info.stream ~= "stdio" or not client or client.name ~= "nvim-tui" then
    return false
  end

  local pid = client.attributes and client.attributes.pid
  if type(pid) ~= "number" then
    return false
  end

  local directory = vim.fn.expand("~/.cache/rex/nvim")
  vim.fn.mkdir(directory, "p", "448")
  assert(vim.uv.fs_chmod(directory, 448))
  local block = vim.env.REX_BLOCK:gsub("^block:", "")
  vim.fn.serverstart(("%s/%s-%d.sock"):format(directory, block, pid))
  return true
end

-- The TUI can identify itself before this module loads.
for _, info in ipairs(vim.api.nvim_list_chans()) do
  if start_server(info) then
    return {}
  end
end

vim.api.nvim_create_autocmd("ChanInfo", {
  callback = function()
    return start_server(vim.v.event.info)
  end,
})

return {}
