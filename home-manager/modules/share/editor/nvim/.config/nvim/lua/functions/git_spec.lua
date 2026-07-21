if type(describe) ~= "function" then
  local spec_path = debug.getinfo(1, "S").source:sub(2)
  local lua_root = spec_path:match("^(.*)/functions/")
  local busted_lua_root = "/opt/homebrew/opt/busted/libexec/share/lua/5.5"
  local busted_c_root = "/opt/homebrew/opt/busted/libexec/lib/lua/5.5"

  package.path = table.concat({
    lua_root .. "/?.lua",
    lua_root .. "/?/init.lua",
    busted_lua_root .. "/?.lua",
    busted_lua_root .. "/?/init.lua",
    package.path,
  }, ";")

  package.cpath = table.concat({
    busted_c_root .. "/?.so",
    package.cpath,
  }, ";")

  require("busted.runner")()
end

local git = require("functions.git")

describe("git.find_owner", function()
  local function owners(content, path)
    return git.find_owner(content, path)
  end

  describe("wildcard patterns", function()
    local cases = {
      { name = "* matches any file at root", content = "* @team", path = "foo.rb", expect = "@team" },
      { name = "* matches any nested file", content = "* @team", path = "src/foo.rb", expect = "@team" },
      { name = "*.rb matches .rb at root", content = "*.rb @team", path = "foo.rb", expect = "@team" },
      { name = "*.rb matches nested .rb", content = "*.rb @team", path = "src/foo.rb", expect = "@team" },
      { name = "*.rb does not match .js", content = "*.rb @team", path = "src/foo.js", expect = "" },
    }
    for _, case in ipairs(cases) do
      it(case.name, function()
        assert.are.equal(case.expect, owners(case.content, case.path))
      end)
    end
  end)

  describe("anchored path patterns", function()
    local cases = {
      {
        name = "/docs/*.md matches file in docs/",
        content = "/docs/*.md @team",
        path = "docs/readme.md",
        expect = "@team",
      },
      {
        name = "/docs/*.md does not match nested",
        content = "/docs/*.md @team",
        path = "src/docs/readme.md",
        expect = "",
      },
      { name = "src/*.rb matches file in src/", content = "src/*.rb @team", path = "src/foo.rb", expect = "@team" },
      { name = "src/*.rb does not match deeper", content = "src/*.rb @team", path = "src/lib/foo.rb", expect = "" },
    }
    for _, case in ipairs(cases) do
      it(case.name, function()
        assert.are.equal(case.expect, owners(case.content, case.path))
      end)
    end
  end)

  describe("directory patterns", function()
    local cases = {
      { name = "src/ matches file directly under src/", content = "src/ @team", path = "src/foo.rb", expect = "@team" },
      {
        name = "src/ matches deeply nested file",
        content = "src/ @team",
        path = "src/lib/util/foo.rb",
        expect = "@team",
      },
      { name = "src/ does not match sibling dir", content = "src/ @team", path = "test/foo.rb", expect = "" },
    }
    for _, case in ipairs(cases) do
      it(case.name, function()
        assert.are.equal(case.expect, owners(case.content, case.path))
      end)
    end
  end)

  describe("** patterns", function()
    local cases = {
      { name = "**/tests matches at root", content = "**/tests @team", path = "tests", expect = "@team" },
      { name = "**/tests matches one level deep", content = "**/tests @team", path = "src/tests", expect = "@team" },
      { name = "**/tests matches deeply nested", content = "**/tests @team", path = "a/b/c/tests", expect = "@team" },
      { name = "**/tests does not match partial name", content = "**/tests @team", path = "src/notests", expect = "" },
      {
        name = "src/**/*.rb matches direct child (zero intermediate dirs)",
        content = "src/**/*.rb @team",
        path = "src/foo.rb",
        expect = "@team",
      },
      {
        name = "src/**/*.rb matches nested .rb",
        content = "src/**/*.rb @team",
        path = "src/lib/foo.rb",
        expect = "@team",
      },
      {
        name = "src/**/*.rb matches deeply nested",
        content = "src/**/*.rb @team",
        path = "src/a/b/foo.rb",
        expect = "@team",
      },
    }
    for _, case in ipairs(cases) do
      it(case.name, function()
        assert.are.equal(case.expect, owners(case.content, case.path))
      end)
    end
  end)

  describe("last matching rule wins", function()
    local cases = {
      {
        name = "more specific rule overrides catch-all",
        content = "* @default\nsrc/*.rb @backend",
        path = "src/foo.rb",
        expect = "@backend",
      },
      {
        name = "catch-all applies when no specific rule matches",
        content = "* @default\nsrc/*.rb @backend",
        path = "docs/readme.md",
        expect = "@default",
      },
      {
        name = "last rule among multiple matches wins",
        content = "*.rb @first\nsrc/*.rb @second\nsrc/foo.rb @third",
        path = "src/foo.rb",
        expect = "@third",
      },
    }
    for _, case in ipairs(cases) do
      it(case.name, function()
        assert.are.equal(case.expect, owners(case.content, case.path))
      end)
    end
  end)

  describe("edge cases", function()
    local cases = {
      { name = "empty content returns empty", content = "", path = "src/foo.rb", expect = "" },
      {
        name = "comment lines are skipped",
        content = "# this is a comment\n*.rb @team",
        path = "foo.rb",
        expect = "@team",
      },
      { name = "blank lines are skipped", content = "\n\n*.rb @team\n\n", path = "foo.rb", expect = "@team" },
      { name = "no matching rule returns empty", content = "*.js @frontend", path = "src/foo.rb", expect = "" },
      {
        name = "pattern with no owners clears previous ownership",
        content = "* @default\n*.rb",
        path = "foo.rb",
        expect = "",
      },
      {
        name = "multiple owners are returned as-is",
        content = "*.rb @alice @bob",
        path = "foo.rb",
        expect = "@alice @bob",
      },
    }
    for _, case in ipairs(cases) do
      it(case.name, function()
        assert.are.equal(case.expect, owners(case.content, case.path))
      end)
    end
  end)
end)

describe("git.get_current_repo_name", function()
  local original_vim

  local function given_git_remote_url(remote_url, shell_error)
    _G.vim = {
      fn = {
        system = function(command)
          assert.are.equal("git remote get-url origin", command)
          return remote_url
        end,
      },
      v = { shell_error = shell_error or 0 },
    }
  end

  before_each(function()
    original_vim = _G.vim
  end)

  after_each(function()
    _G.vim = original_vim
  end)

  it("GIVEN an SSH origin URL WHEN get_current_repo_name runs THEN it returns owner/repo", function()
    given_git_remote_url("git@github.com:l-lin/dotfiles.git\n")

    local actual = git.get_current_repo_name()
    local expected = "l-lin/dotfiles"

    assert.are.equal(expected, actual)
  end)

  it("GIVEN an HTTPS origin URL WHEN get_current_repo_name runs THEN it returns owner/repo", function()
    given_git_remote_url("https://github.com/l-lin/dotfiles.git\n")

    local actual = git.get_current_repo_name()
    local expected = "l-lin/dotfiles"

    assert.are.equal(expected, actual)
  end)

  it("GIVEN git fails WHEN get_current_repo_name runs THEN it returns nil", function()
    given_git_remote_url("", 1)

    local actual = git.get_current_repo_name()

    assert.is_nil(actual)
  end)
end)

describe("git.list_changed_files", function()
  it(
    "GIVEN staged unstaged and untracked outputs WHEN listing changed files THEN it returns a unique sorted list",
    function()
      local actual = git.list_changed_files("b.txt\0a.txt\0", "a.txt\0c.txt\0", "z.txt\0a.txt\0")
      local expected = { "a.txt", "b.txt", "c.txt", "z.txt" }

      assert.are.same(expected, actual)
    end
  )

  it("GIVEN empty command outputs WHEN listing changed files THEN it returns an empty list", function()
    local actual = git.list_changed_files("", "", "")
    local expected = {}

    assert.are.same(expected, actual)
  end)
end)

describe("git.find_changed_file_target", function()
  it("GIVEN the current file is changed WHEN moving next THEN it returns the next changed file", function()
    local actual = git.find_changed_file_target({ "a.txt", "c.txt", "z.txt" }, "c.txt", "next")
    local expected = "z.txt"

    assert.are.equal(expected, actual)
  end)

  it("GIVEN the current file is changed WHEN moving previous THEN it returns the previous changed file", function()
    local actual = git.find_changed_file_target({ "a.txt", "c.txt", "z.txt" }, "c.txt", "prev")
    local expected = "a.txt"

    assert.are.equal(expected, actual)
  end)

  it(
    "GIVEN the current file is unchanged WHEN moving next THEN it returns the next lexicographic changed file",
    function()
      local actual = git.find_changed_file_target({ "a.txt", "c.txt", "z.txt" }, "b.txt", "next")
      local expected = "c.txt"

      assert.are.equal(expected, actual)
    end
  )

  it(
    "GIVEN the current file is unchanged WHEN moving previous THEN it returns the previous lexicographic changed file",
    function()
      local actual = git.find_changed_file_target({ "a.txt", "c.txt", "z.txt" }, "b.txt", "prev")
      local expected = "a.txt"

      assert.are.equal(expected, actual)
    end
  )

  it("GIVEN no current file WHEN moving next THEN it returns the first changed file", function()
    local actual = git.find_changed_file_target({ "a.txt", "c.txt", "z.txt" }, nil, "next")
    local expected = "a.txt"

    assert.are.equal(expected, actual)
  end)

  it("GIVEN no current file WHEN moving previous THEN it returns the last changed file", function()
    local actual = git.find_changed_file_target({ "a.txt", "c.txt", "z.txt" }, nil, "prev")
    local expected = "z.txt"

    assert.are.equal(expected, actual)
  end)

  it(
    "GIVEN the current file sorts after the last changed file WHEN moving next THEN it wraps to the first changed file",
    function()
      local actual = git.find_changed_file_target({ "a.txt", "c.txt", "z.txt" }, "zz.txt", "next")
      local expected = "a.txt"

      assert.are.equal(expected, actual)
    end
  )

  it(
    "GIVEN the current file sorts before the first changed file WHEN moving previous THEN it wraps to the last changed file",
    function()
      local actual = git.find_changed_file_target({ "a.txt", "c.txt", "z.txt" }, "0.txt", "prev")
      local expected = "z.txt"

      assert.are.equal(expected, actual)
    end
  )

  it("GIVEN no changed files WHEN finding a target THEN it returns nil", function()
    local actual = git.find_changed_file_target({}, "a.txt", "next")

    assert.is_nil(actual)
  end)
end)

describe("git.extract_repo_name_and_pr_id_from_url", function()
  local cases = {
    {
      name = "GIVEN a GitHub pull request URL WHEN extracting THEN it returns owner/repo and PR id",
      input = "https://github.com/doctolib/preventive-continuous-care/pull/1625",
      expect_repo_name = "doctolib/preventive-continuous-care",
      expect_pr_id = 1625,
    },
    {
      name = "GIVEN a GitHub pull request changes URL WHEN extracting THEN it returns owner/repo and PR id",
      input = "https://github.com/doctolib/preventive-continuous-care/pull/1625/changes",
      expect_repo_name = "doctolib/preventive-continuous-care",
      expect_pr_id = 1625,
    },
    {
      name = "GIVEN a non-pull-request URL WHEN extracting THEN it returns nil values",
      input = "https://github.com/doctolib/preventive-continuous-care/issues/1625",
      expect_repo_name = nil,
      expect_pr_id = nil,
    },
  }

  for _, case in ipairs(cases) do
    it(case.name, function()
      local actual_repo_name, actual_pr_id = git.extract_repo_name_and_pr_id_from_url(case.input)

      assert.are.equal(case.expect_repo_name, actual_repo_name)
      assert.are.equal(case.expect_pr_id, actual_pr_id)
    end)
  end
end)
