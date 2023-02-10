require('bufferline').setup {
    options = {
        show_close_icon = false,
        show_buffer_close_icons = false,
        color_icons = true,
        always_show_bufferline = false,
        diagnostics = 'nvim_lsp',
    },
    highlights = {
        fill = {
            bg = '#3c3836'
        },
        background = {
            bg = '#282828'
        },
    },
}
