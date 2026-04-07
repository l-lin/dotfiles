return {
  {
    "tigion/nvim-asciidoc-preview",
    cmd = {
      "AsciiDocPreview"
    },
    ft = { "asciidoc" },
    build = "cd server && npm install",
    keys = {
      { "<leader>ca", "<cmd>AsciiDocPreview<cr>", noremap = true, desc = "Start Asciidoc preview and open in web browser" },
    }
  },
}
