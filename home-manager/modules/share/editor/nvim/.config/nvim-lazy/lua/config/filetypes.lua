-- Custom filetype detection rules.
-- Replaces ftdetect/*.vim — see: https://neovim.io/doc/user/lua.html#vim.filetype.add()
vim.filetype.add({
  extension = {
    avdl = "avdl",
    bats = "sh",
    mdc = "markdown",
  },
  filename = {
    Jenkinsfile = "groovy",
  },
})
