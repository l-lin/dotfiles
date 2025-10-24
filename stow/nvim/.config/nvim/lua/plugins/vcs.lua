-- From: https://github.com/tpope/vim-fugitive/issues/1274#issuecomment-1748183602
local toggle_fugitive = function()
  local winids = vim.api.nvim_list_wins()
  for _, id in pairs(winids) do
    local status = pcall(vim.api.nvim_win_get_var, id, "fugitive_status")
    if status then
      vim.api.nvim_win_close(id, false)
      return
    end
  end
  vim.cmd("Git")

  -- directly goes to the first changed file line, which is located at line 6!
  local line_count = vim.api.nvim_buf_line_count(0)
  if line_count >= 6 then
    vim.api.nvim_win_set_cursor(0, { 6, 0 })
  end
end

return {
  -- #######################
  -- override default config
  -- #######################

  -- git modifications explorer/handler
  {
    "lewis6991/gitsigns.nvim",
    optional = true,
    keys = {
      { "<M-C-G>", "<cmd>Gitsigns preview_hunk_inline<cr>", desc = "Preview Hunk inline (Ctrl+Alt+g)" },
      { "<M-C-Z>", "<cmd>Gitsigns reset_hunk<cr>", mode = { "n", "v" }, desc = "Reset hunk (Ctrl+Alt+z)" },
    },
  },
  {
    "nvim-mini/mini.diff",
    optional = true,
    keys = {
      { "<M-C-G>", function() require("mini.diff").toggle_overlay(0) end, desc = "Preview Hunk inline (Ctrl+Alt+g)" },
    },
    init = function()
      -- Not sure why, but I cannot configure it at `keys` level...
      vim.keymap.set("n", "<M-C-Z>", function() return MiniDiff.operator("reset") .. "gh" end, { expr = true, remap = true })
    end,
  },

  -- use snacks.picker for git status
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>gb", function() Snacks.picker.git_log_line({ current_line = true, current_file = true, follow = true }) end, desc = "Git Blame Line" },
      {
        "<leader>gs",
        function()
          Snacks.picker.git_status({
            layout = "sidebar",
            win = {
              list = {
                keys = {
                  ["<space>"] = "git_stage",
                },
              },
            },
          })
        end,
        desc = "Git Status",
      },
      { "<leader>gl", function() Snacks.picker.git_log({ cwd = LazyVim.root.git() }) end, desc = "Git Log" },
      { "<leader>gL", function() Snacks.picker.git_log() end, desc = "Git Log (cwd)" },
      { "<M-9>", function() Snacks.picker.git_log({ current_file = true, follow = true }) end, noremap = true, silent = true, desc = "Check current file git history (Alt+9)" },
    }
  },

 -- git integration
 {
   "tpope/vim-fugitive",
   keys = {
     { "<leader>gc", "<cmd>G commit --no-verify<cr>", desc = "git commit" },
     { "<leader>gF", "<cmd>G push --force-with-lease<cr>", desc = "git push --force-with-lease" },
     -- useful for creating new PR/MR where the url is displayed in the git push message
     { "<leader>gO", "<cmd>G -p push<cr>", desc = "git push and display git message" },
     { "<leader>gp", "<cmd>G pull<cr>", desc = "git pull" },
     { "<leader>gP", "<cmd>G push<cr>", desc = "git push" },
     { "<M-0>", toggle_fugitive, desc = "git status (Alt+0)" },
   },
 },

  -- add keymaps to which-key
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        {
          "<M-)>",
          function() Snacks.lazygit( { cwd = LazyVim.root.git() }) end,
          desc = "LazyGit",
          mode = { "n" },
          noremap = true,
        },
      },
    },
  },
}
