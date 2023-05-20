local wilder = require('wilder')
wilder.setup({
  modes = { ':', '/', '?' },
  next_key = '<C-n>',
  previous_key = '<C-p>',
  accept_key = '<Tab>'
})
wilder.set_option('renderer', wilder.popupmenu_renderer({
  highlighter = wilder.basic_highlighter(),
  left = { ' ', wilder.popupmenu_devicons() },
  right = { ' ', wilder.popupmenu_scrollbar() },
}))
