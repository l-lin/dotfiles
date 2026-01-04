vim.keymap.set("i", "<M-c>", require("helpers.lang.markdown").insert_codeblock, { buffer = true, desc = "Add codeblock" })
