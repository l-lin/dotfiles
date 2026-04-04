local repo_parser = require("helpers.repo_parser")

describe("repo_parser.is_repo_pattern", function()
  local cases = {
    { name = "simple user/repo", input = "torvalds/linux", expect = true },
    { name = "user repo with dots", input = "saghen/blink.cmp", expect = true },
    { name = "dashes, underscores numbers", input = "foo-bar_hi/my-repo_123", expect = true },
    { name = "leading dash invalid", input = "-bad/repo", expect = false },
    { name = "trailing slash invalid", input = "user/repo/", expect = false },
    { name = "contains space invalid", input = "user name/repo", expect = false },
    { name = "single segment invalid", input = "justusername", expect = false },
  }

  for _, case in ipairs(cases) do
    it(case.name, function()
      local actual = repo_parser.is_repo_pattern(case.input)
      assert.are.equal(case.expect, actual)
    end)
  end
end)
