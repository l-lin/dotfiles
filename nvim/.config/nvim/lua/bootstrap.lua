local M = {}
local api = vim.api
local opt_local = vim.opt_local

local function echo(str)
  vim.cmd "redraw"
  vim.api.nvim_echo({ { str, "Bold" } }, true, {})
end

local function shell_call(args)
  local output = vim.fn.system(args)
  assert(vim.v.shell_error == 0, "External call failed with error code: " .. vim.v.shell_error .. "\n" .. output)
end

local function init_lazy(lazypath)
  vim.opt.rtp:prepend(lazypath)

  require("plugins")
end

local function display_note_at_screen()
  local text_on_screen = {
    "",
    "",
    "███╗   ██╗   ██████╗  ████████╗ ███████╗ ███████╗",
    "████╗  ██║  ██╔═══██╗ ╚══██╔══╝ ██╔════╝ ██╔════╝",
    "██╔██╗ ██║  ██║   ██║    ██║    █████╗   ███████╗",
    "██║╚██╗██║  ██║   ██║    ██║    ██╔══╝   ╚════██║",
    "██║ ╚████║  ╚██████╔╝    ██║    ███████╗ ███████║",
    "",
    "",
    "  Mason just downloads binaries",
    "",
    "Now quit nvim!",
  }

  local buf = api.nvim_create_buf(false, true)

  vim.opt_local.filetype = "post_bootstrap_window"
  api.nvim_buf_set_lines(buf, 0, -1, false, text_on_screen)

  local postscreen = api.nvim_create_namespace "postscreen"

  for i = 1, #text_on_screen do
    api.nvim_buf_add_highlight(buf, postscreen, "LazyCommit", i, 0, -1)
  end

  api.nvim_win_set_buf(0, buf)

  -- buf only options
  opt_local.buflisted = false
  opt_local.modifiable = false
  opt_local.number = false
  opt_local.list = false
  opt_local.relativenumber = false
  opt_local.wrap = false
  opt_local.cul = false
end

local function post_install()
  api.nvim_buf_delete(0, { force = true }) -- close previously opened lazy window

  vim.schedule(function()
    vim.cmd "MasonInstallAll"

    -- Keep track of which mason pkgs get installed
    local packages = table.concat(vim.g.mason_binaries_list, " ")

    require("mason-registry"):on("package:install:success", function(pkg)
      packages = string.gsub(packages, pkg.name:gsub("%-", "%%-"), "") -- rm package name

      -- run above screen func after all pkgs are installed.
      if packages:match "%S" == nil then
        vim.schedule(function()
          api.nvim_buf_delete(0, { force = true })
          vim.cmd "echo '' | redraw" -- clear cmdline
          display_note_at_screen()
        end)
      end
    end)
  end)
end

local function install_lazy_if_not_present(lazypath)
  if not vim.loop.fs_stat(lazypath) then
    echo("  Installing lazy.nvim & plugins...")

    local repo = "https://github.com/folke/lazy.nvim.git"
    shell_call { "git", "clone", "--filter=blob:none", "--branch=stable", repo, lazypath }

    post_install()
  end
end

M.setup = function()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

  install_lazy_if_not_present(lazypath)
  init_lazy(lazypath)
end

return M
