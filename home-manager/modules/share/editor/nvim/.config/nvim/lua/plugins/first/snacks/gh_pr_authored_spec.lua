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

local gh_pr_authored = require("plugins.first.snacks.gh_pr_authored")

describe("gh_pr_authored.build_args", function()
  it("GIVEN the default limit WHEN building args THEN it searches open PRs authored by me across all repos", function()
    local actual = gh_pr_authored.build_args(nil, nil, gh_pr_authored.DEFAULT_LIMIT)
    local expected = {
      "search",
      "prs",
      "--author",
      "@me",
      "--state",
      "open",
      "--limit",
      tostring(gh_pr_authored.DEFAULT_LIMIT),
      "--json",
      "author,isDraft,labels,number,repository,state,title,updatedAt,url",
    }

    assert.are.same(expected, actual)
  end)

  it("GIVEN a live query and repo override WHEN building args THEN it adds both before the JSON fields", function()
    local actual = gh_pr_authored.build_args("label:team-docs", "doctolib/preventive-continuous-care", 42)
    local expected = {
      "search",
      "prs",
      "label:team-docs",
      "--author",
      "@me",
      "--state",
      "open",
      "--repo",
      "doctolib/preventive-continuous-care",
      "--limit",
      "42",
      "--json",
      "author,isDraft,labels,number,repository,state,title,updatedAt,url",
    }

    assert.are.same(expected, actual)
  end)
end)

describe("gh_pr_authored.finder", function()
  local original_proc_module
  local original_vim

  before_each(function()
    original_proc_module = package.loaded["snacks.picker.source.proc"]
    original_vim = _G.vim
  end)

  after_each(function()
    package.loaded["snacks.picker.source.proc"] = original_proc_module
    _G.vim = original_vim
  end)

  it("GIVEN raw gh search JSON WHEN finder runs THEN it searches authored PRs across all repos with the configured limit", function()
    local captured_proc_opts = nil
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
    gh_pr_authored.finder(
      { limit = gh_pr_authored.DEFAULT_LIMIT },
      { filter = { search = "label:team-docs" } }
    )(function(item)
      table.insert(actual, item)
    end)

    assert.are.equal("gh", captured_proc_opts.cmd)
    assert.is_true(captured_proc_opts.raw)
    assert.are.same(gh_pr_authored.build_args(nil, nil, gh_pr_authored.DEFAULT_LIMIT), captured_proc_opts.args)
    assert.are.equal(1, #actual)
    assert.are.equal("pr", actual[1].type)
    assert.are.equal("doctolib/preventive-continuous-care", actual[1].repo)
    assert.are.equal(42, actual[1].number)
  end)

  it("GIVEN the same picker and limit WHEN finder runs multiple times THEN it reuses cached search results", function()
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

    gh_pr_authored.finder(
      { limit = gh_pr_authored.DEFAULT_LIMIT },
      { picker = picker, filter = { search = "first" } }
    )(function(item)
      table.insert(actual, item)
    end)
    gh_pr_authored.finder(
      { limit = gh_pr_authored.DEFAULT_LIMIT },
      { picker = picker, filter = { search = "second" } }
    )(function(item)
      table.insert(actual, item)
    end)

    assert.are.equal(1, proc_call_count)
    assert.are.equal(2, #actual)
  end)
end)

describe("gh_pr_authored.open", function()
  local original_snacks

  before_each(function()
    original_snacks = _G.Snacks
  end)

  after_each(function()
    _G.Snacks = original_snacks
  end)

  it("GIVEN no overrides WHEN opening THEN it opens the authored picker across all repos with the default limit", function()
    local actual_opts = nil
    _G.Snacks = {
      picker = {
        gh_pr_authored = function(opts)
          actual_opts = opts
        end,
      },
    }

    gh_pr_authored.open()

    assert.are.same({ limit = gh_pr_authored.DEFAULT_LIMIT }, actual_opts)
  end)

  it("GIVEN repo and limit overrides WHEN opening THEN it forwards them to the picker", function()
    local actual_opts = nil
    _G.Snacks = {
      picker = {
        gh_pr_authored = function(opts)
          actual_opts = opts
        end,
      },
    }

    gh_pr_authored.open({ repo = "doctolib/preventive-continuous-care", limit = 42 })

    assert.are.same({ repo = "doctolib/preventive-continuous-care", limit = 42 }, actual_opts)
  end)
end)
