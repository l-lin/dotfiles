vim.keymap.set(
  "n",
  "<leader>fxx",
  function()
    require("functions.file").execute_bash_script()
  end,
  { buffer = true, desc = "Execute bash script" }
)
