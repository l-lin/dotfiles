local M = {}

M.attach_keymaps = function()
  local map = require("mapper").map
  local bufopts = { noremap = true, silent = true }

  map({ "n", "x", "o" }, "s", require("flash").jump, bufopts, "Flash")
  map({ "n", "x", "o" }, "<leader>nf", require("flash").jump, bufopts, "Flash (or use s)")
  map({ "n", "o", "x" }, "S", require("flash").treesitter, bufopts, "Flash treesitter")
  map({ "n", "o", "x" }, "<leader>nt", require("flash").treesitter, bufopts, "Flash treesitter (or use S)")
  map({ "o" }, "r", require("flash").remote, bufopts, "Remote Flash")
  map({ "o", "x" }, "R", require("flash").treesitter_search, bufopts, "Treesitter Search")
  map({ "c" }, "<C-s>", require("flash").toggle, bufopts, "Toggle Flash Search")
end

M.setup = function()
  local config = {
    search = {
      mode = "search",
    },
    label = {
      rainbow = {
        enabled = true,
      }
    }
  }
  require("flash").setup(config)

  M.attach_keymaps()
end

return M
