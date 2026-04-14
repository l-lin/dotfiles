if type(describe) ~= "function" then
  local spec_path = debug.getinfo(1, "S").source:sub(2)
  local lua_root = spec_path:match("^(.*)/plugins/") or spec_path:match("^(.*)/functions/")
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

local gh_pr_review_requested = require("plugins.first.snacks.gh_pr_review_requested")

describe("gh_pr_review_requested.build_args", function()
  it("GIVEN no live query WHEN building args THEN it searches open PRs requesting my review", function()
    local actual = gh_pr_review_requested.build_args(nil)
    local expected = {
      "search",
      "prs",
      "--review-requested",
      "@me",
      "--state",
      "open",
      "--json",
      "author,isDraft,labels,number,repository,state,title,updatedAt,url",
    }

    assert.are.same(expected, actual)
  end)

  it("GIVEN a live query WHEN building args THEN it adds the query before flags", function()
    local actual = gh_pr_review_requested.build_args("label:team-docs")
    local expected = {
      "search",
      "prs",
      "label:team-docs",
      "--review-requested",
      "@me",
      "--state",
      "open",
      "--json",
      "author,isDraft,labels,number,repository,state,title,updatedAt,url",
    }

    assert.are.same(expected, actual)
  end)

  it("GIVEN a repo name WHEN building args THEN it scopes the search to that repository", function()
    local actual = gh_pr_review_requested.build_args("label:team-docs", "doctolib/preventive-continuous-care")
    local expected = {
      "search",
      "prs",
      "label:team-docs",
      "--review-requested",
      "@me",
      "--state",
      "open",
      "--repo",
      "doctolib/preventive-continuous-care",
      "--json",
      "author,isDraft,labels,number,repository,state,title,updatedAt,url",
    }

    assert.are.same(expected, actual)
  end)
end)

describe("gh_pr_review_requested.finder", function()
  local original_proc_module
  local original_git_module
  local original_vim

  before_each(function()
    original_proc_module = package.loaded["snacks.picker.source.proc"]
    original_git_module = package.loaded["functions.git"]
    original_vim = _G.vim
  end)

  after_each(function()
    package.loaded["snacks.picker.source.proc"] = original_proc_module
    package.loaded["functions.git"] = original_git_module
    _G.vim = original_vim
  end)

  it(
    "GIVEN raw gh search JSON WHEN finder runs THEN it uses proc.proc with the provided repo scope and without querying git state",
    function()
      local captured_proc_opts = nil
      package.loaded["functions.git"] = {
        get_current_repo_name = function()
          error("finder must not query the current git repo")
        end,
      }
      package.loaded["snacks.picker.source.proc"] = {
        proc = function(opts)
          captured_proc_opts = opts
          return function(cb)
            cb({
              text = [[[{"author":{"login":"l-lin","isBot":false},"isDraft":false,"labels":[],"number":42,"repository":{"nameWithOwner":"doctolib/preventive-continuous-care"},"state":"OPEN","title":"Review me","updatedAt":"2026-04-13T01:02:03Z","url":"https://github.com/doctolib/preventive-continuous-care/pull/42"}]],
            })
          end
        end,
      }
      _G.vim = {
        json = {
          decode = function(text)
            assert.truthy(text:match('"Review me"'))
            return {
              {
                author = { login = "l-lin", isBot = false },
                isDraft = false,
                labels = {},
                number = 42,
                repository = { nameWithOwner = "doctolib/preventive-continuous-care" },
                state = "OPEN",
                title = "Review me",
                updatedAt = "2026-04-13T01:02:03Z",
                url = "https://github.com/doctolib/preventive-continuous-care/pull/42",
              },
            }
          end,
        },
      }

      local actual = {}
      gh_pr_review_requested.finder(
        { repo = "doctolib/preventive-continuous-care" },
        { filter = { search = "label:team-docs" } }
      )(function(item)
        table.insert(actual, item)
      end)

      assert.are.equal("gh", captured_proc_opts.cmd)
      assert.is_true(captured_proc_opts.raw)
      assert.are.same(
        gh_pr_review_requested.build_args(nil, "doctolib/preventive-continuous-care"),
        captured_proc_opts.args
      )
      assert.are.equal(1, #actual)
      assert.are.equal("pr", actual[1].type)
      assert.are.equal("doctolib/preventive-continuous-care", actual[1].repo)
      assert.are.equal(42, actual[1].number)
    end
  )

  it("GIVEN the same picker and repo WHEN finder runs multiple times THEN it reuses cached search results", function()
    local proc_call_count = 0
    package.loaded["snacks.picker.source.proc"] = {
      proc = function()
        proc_call_count = proc_call_count + 1
        return function(cb)
          cb({
            text = [[[{"author":{"login":"l-lin","isBot":false},"isDraft":false,"labels":[],"number":42,"repository":{"nameWithOwner":"doctolib/preventive-continuous-care"},"state":"OPEN","title":"Review me","updatedAt":"2026-04-13T01:02:03Z","url":"https://github.com/doctolib/preventive-continuous-care/pull/42"}]],
          })
        end
      end,
    }
    _G.vim = {
      json = {
        decode = function()
          return {
            {
              author = { login = "l-lin", isBot = false },
              isDraft = false,
              labels = {},
              number = 42,
              repository = { nameWithOwner = "doctolib/preventive-continuous-care" },
              state = "OPEN",
              title = "Review me",
              updatedAt = "2026-04-13T01:02:03Z",
              url = "https://github.com/doctolib/preventive-continuous-care/pull/42",
            },
          }
        end,
      },
    }

    local picker = {}
    local actual = {}

    gh_pr_review_requested.finder(
      { repo = "doctolib/preventive-continuous-care" },
      { picker = picker, filter = { search = "first" } }
    )(function(item)
      table.insert(actual, item)
    end)
    gh_pr_review_requested.finder(
      { repo = "doctolib/preventive-continuous-care" },
      { picker = picker, filter = { search = "second" } }
    )(function(item)
      table.insert(actual, item)
    end)

    assert.are.equal(1, proc_call_count)
    assert.are.equal(2, #actual)
  end)
end)

describe("gh_pr_review_requested.open", function()
  local original_git_module
  local original_snacks
  local original_vim

  before_each(function()
    original_git_module = package.loaded["functions.git"]
    original_snacks = _G.Snacks
    original_vim = _G.vim
  end)

  after_each(function()
    package.loaded["functions.git"] = original_git_module
    _G.Snacks = original_snacks
    _G.vim = original_vim
  end)

  it("GIVEN the current repo is known WHEN opening THEN it scopes the picker to that repo", function()
    local actual_opts = nil
    package.loaded["functions.git"] = {
      get_current_repo_name = function()
        return "doctolib/preventive-continuous-care"
      end,
    }
    _G.Snacks = {
      picker = {
        gh_pr_review_requested = function(opts)
          actual_opts = opts
        end,
      },
    }

    gh_pr_review_requested.open()

    assert.are.same({ repo = "doctolib/preventive-continuous-care" }, actual_opts)
  end)

  it("GIVEN all repos are requested WHEN opening THEN it skips repo lookup and opens an unscoped picker", function()
    local actual_opts = nil
    package.loaded["functions.git"] = {
      get_current_repo_name = function()
        error("open({ all_repos = true }) must not query the current git repo")
      end,
    }
    _G.Snacks = {
      picker = {
        gh_pr_review_requested = function(opts)
          actual_opts = opts
        end,
      },
    }

    gh_pr_review_requested.open({ all_repos = true })

    assert.are.same({}, actual_opts)
  end)

  it("GIVEN the current repo is unknown WHEN opening THEN it notifies and does not open the picker", function()
    local picker_called = false
    local notified_message = nil
    local notified_level = nil

    package.loaded["functions.git"] = {
      get_current_repo_name = function()
        return nil
      end,
    }
    _G.Snacks = {
      picker = {
        gh_pr_review_requested = function()
          picker_called = true
        end,
      },
    }
    _G.vim = {
      log = { levels = { ERROR = 1 } },
      notify = function(message, level)
        notified_message = message
        notified_level = level
      end,
    }

    gh_pr_review_requested.open()

    assert.is_false(picker_called)
    assert.are.equal("Not in a git repository", notified_message)
    assert.are.equal(1, notified_level)
  end)
end)

describe("gh_pr_review_requested.to_picker_item", function()
  it("GIVEN a search result WHEN converting THEN it matches the gh_pr picker shape", function()
    local actual = gh_pr_review_requested.to_picker_item({
      author = { login = "l-lin", isBot = false },
      isDraft = true,
      labels = {
        { name = "team-docs", color = "abcdef" },
      },
      number = 42,
      repository = { nameWithOwner = "doctolib/preventive-continuous-care" },
      state = "OPEN",
      title = "Tighten review flow",
      updatedAt = "2026-04-13T01:02:03Z",
      url = "https://github.com/doctolib/preventive-continuous-care/pull/42",
    })

    assert.are.equal("pr", actual.type)
    assert.are.equal("doctolib/preventive-continuous-care", actual.repo)
    assert.are.equal(42, actual.number)
    assert.are.equal("#42", actual.hash)
    assert.are.equal("team-docs", actual.label)
    assert.are.equal("open", actual.state)
    assert.are.equal("draft", actual.status)
    assert.is_true(actual.isDraft)
    assert.are.equal("l-lin", actual.author)
    assert.are.equal("gh://doctolib/preventive-continuous-care/pr/42", actual.file)
    assert.are.equal("gh://doctolib/preventive-continuous-care/pr/42", actual.uri)
    assert.are.equal("l-lin", actual.item.author.login)
    assert.is_false(actual.item.author.is_bot)
    assert.are.equal("team-docs", actual.item.labels[1].name)
    assert.truthy(actual.text:match("Tighten review flow"))
    assert.truthy(actual.text:match("team%-docs"))
    assert.truthy(actual.text:match("doctolib/preventive%-continuous%-care"))
  end)

  it("GIVEN a search result without a repository WHEN converting THEN it returns nil", function()
    local actual = gh_pr_review_requested.to_picker_item({ number = 42, title = "Broken" })

    assert.is_nil(actual)
  end)
end)

describe("gh_pr_review_requested.decode_search_results", function()
  local original_vim

  before_each(function()
    original_vim = _G.vim
  end)

  after_each(function()
    _G.vim = original_vim
  end)

  it("GIVEN invalid JSON WHEN decoding search results THEN it returns an empty list", function()
    _G.vim = {
      json = {
        decode = function()
          error("boom")
        end,
      },
    }

    local actual = gh_pr_review_requested.decode_search_results("not-json")

    assert.are.same({}, actual)
  end)
end)
