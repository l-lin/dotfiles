return {

  -- #######################
  -- override default config
  -- #######################
  --  Edit and review GitHub issues and pull requests from the comfort of your favorite editor
  {
    "pwntester/octo.nvim",
    keys = {
      { "<leader>gp", false },
      { "<leader>gP", false },
      { "<leader>gr", false },
      { "<leader>gS", false },

      { "<leader>gm", "<cmd>Octo pr list<CR>", desc = "List PRs (Octo)" },
    },
    opts = {
      review_diff = {
        submit_review = { lhs = "<leader>mS", desc = "submit review" },
        discard_review = { lhs = "<leader>md", desc = "discard review" },
        add_review_comment = { lhs = "<leader>mc", desc = "add a new review comment" },
        add_review_suggestion = { lhs = "<leader>ms", desc = "add a new review suggestion" },
        focus_files = { lhs = "<leader>me", desc = "move focus to changed file panel" },
        toggle_files = { lhs = "<leader>mb", desc = "hide/show changed files panel" },
        next_thread = { lhs = "]t", desc = "move to next thread" },
        prev_thread = { lhs = "[t", desc = "move to previous thread" },
        select_next_entry = { lhs = "]q", desc = "move to next changed file" },
        select_prev_entry = { lhs = "[q", desc = "move to previous changed file" },
        select_first_entry = { lhs = "[Q", desc = "move to first changed file" },
        select_last_entry = { lhs = "]Q", desc = "move to last changed file" },
        close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
        toggle_viewed = { lhs = "<leader>mt", desc = "toggle viewer viewed state" },
        goto_file = { lhs = "gf", desc = "go to file" },
      },
    },
  },
}
