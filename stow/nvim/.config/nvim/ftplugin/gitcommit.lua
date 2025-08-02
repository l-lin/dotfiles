vim.keymap.set("i", "<M-c>", require("plugins.custom.lang.markdown").insert_codeblock, { buffer = true, desc = "Add codeblock" })
