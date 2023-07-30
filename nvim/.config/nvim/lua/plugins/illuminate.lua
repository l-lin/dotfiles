require('illuminate').configure({
  delay = 0,
})
-- if you want to display in highlight instead of underline
-- /!\ you will not be able to see the difference with visual selection
-- vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "Visual" })
-- vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "Visual" })
-- vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "Visual" })
