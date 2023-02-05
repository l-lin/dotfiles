local wk = require('which-key')
wk.register({
    f = {
        name = "find"
    }
}, { prefix = "<leader>" })
wk.register({
    c = {
        name = "code"
    }
}, { prefix = "<leader>" })
wk.register({
    l = {
        name = "language"
    }
}, { prefix = "<leader>" })
wk.register({
    c = {
        name = "check spelling"
    }
}, { prefix = "<leader>l" })
wk.register({
    s = {
        name = "shell (toggleterm)"
    }
}, { prefix = "<leader>" })
wk.register({
    S = {
        name = "shell (native)"
    }
}, { prefix = "<leader>" })
wk.register({
    w = {
        name = "whitespace"
    }
}, { prefix = "<leader>" })
wk.register({
    x = {
        name = "trouble"
    }
}, { prefix = "<leader>" })
wk.register({
    g = {
        name = "git"
    }
}, { prefix = "<leader>" })
wk.register({
    p = {
        name = "plugin"
    }
}, { prefix = "<leader>" })
--wk.setup {
--    disable = {
--        filetypes = { 'TelescopePrompt', 'dashboard' }
--    }
--}
