return {
  {
    "l-lin/jira.nvim",
    cmd = { "JiraIssues", "JiraEpic", "JiraStartWorkingOn" },
    keys = {
      { "<leader>ji", "<cmd>JiraIssues<cr>" },
      { "<leader>je", "<cmd>JiraEpic<cr>" },
      { "<leader>j1", "<cmd>JiraEpic P3C-5771<cr>" },
      { "<leader>j2", "<cmd>JiraEpic P3C-6006<cr>" },
      { "<leader>j3", "<cmd>JiraEpic P3C-5857<cr>" },
    },
    opts = {
      cli = {
        issues = {
          prefill_search = "Louis",
        },
      },
    },
  },
}
