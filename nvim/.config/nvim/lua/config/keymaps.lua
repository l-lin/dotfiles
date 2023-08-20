local map = vim.keymap.set

-- buffer
map("n", "<F28>", "<cmd>bd<CR>", { noremap = true, silent = true, desc = "Close current buffer" })

-- editing
map("n", "<C-y>", "dd", { noremap = true, desc = "Delete line" })

-- use different buffer for delete and paste
map("n", "d", '"_d', { noremap = true })
map("v", "d", '"_d', { noremap = true })
map("v", "p", '"_dP', { noremap = true })

-- go to first character in line (need to stretch my left hand to type ^)
map("x", "0", "^")
map("n", "0", "^")
