local M = {}

local function echo(str)
  vim.cmd "redraw"
  vim.api.nvim_echo({ { str, "Bold" } }, true, {})
end

local function shell_call(args)
  local output = vim.fn.system(args)
  assert(vim.v.shell_error == 0, "External call failed with error code: " .. vim.v.shell_error .. "\n" .. output)
end

local function install_lazy_if_not_present(lazypath)
  if not vim.loop.fs_stat(lazypath) then
    echo("  Installing lazy.nvim & plugins...")

    local repo = "https://github.com/folke/lazy.nvim.git"
    shell_call { "git", "clone", "--filter=blob:none", "--branch=stable", repo, lazypath }
  end
end

local function init_lazy(lazypath)
  vim.opt.rtp:prepend(lazypath)

  require("plugins")
end

M.setup = function()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

  install_lazy_if_not_present(lazypath)
  init_lazy(lazypath)
end

return M
