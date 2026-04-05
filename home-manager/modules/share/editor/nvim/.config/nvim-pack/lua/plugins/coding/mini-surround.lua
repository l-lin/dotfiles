---@type vim.pack.Spec
return {
  src = "https://github.com/nvim-mini/mini.surround",
  data = {
    setup = function()
      require("mini.surround").setup({
        mappings = {
          add = "gsa",
          delete = "gsd",
          find = "gsf",
          find_left = "gsF",
          highlight = "gsh",
          replace = "gsr",
          update_n_lines = "gsn",
        },
      })
    end,
  },
}
