local localSettingsFirenvim = {
    [".*"] = {
        cmdline = 'neovim',
        takeover = 'never'
    }
}
vim.g.firenvim_config = {
    localSettings = localSettingsFirenvim
}
