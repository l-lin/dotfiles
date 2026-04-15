dofile((debug.getinfo(1, "S").source:sub(2):match("^(.*)/[^/]+$")) .. "/spec_helper.lua")
if type(describe) ~= "function" then
  require("busted.runner")()
end

describe("gh_pr_story.data.fetch_pr_metadata", function()
  local original_data_module
  local original_util_module
  local original_story_module
  local original_vim
  local original_table_unpack

  before_each(function()
    original_data_module = package.loaded["plugins.first.snacks.gh_pr_story.data"]
    original_util_module = package.loaded["plugins.first.snacks.gh_pr_story.util"]
    original_story_module = package.loaded["plugins.first.snacks.gh_pr_story.story"]
    original_vim = _G.vim
    original_table_unpack = table.unpack

    package.loaded["plugins.first.snacks.gh_pr_story.data"] = nil
    package.loaded["plugins.first.snacks.gh_pr_story.story"] = {}
  end)

  after_each(function()
    package.loaded["plugins.first.snacks.gh_pr_story.data"] = original_data_module
    package.loaded["plugins.first.snacks.gh_pr_story.util"] = original_util_module
    package.loaded["plugins.first.snacks.gh_pr_story.story"] = original_story_module
    _G.vim = original_vim
    table.unpack = original_table_unpack
  end)

  it("GIVEN Lua without table.unpack WHEN fetching PR metadata THEN it still passes flattened gh args", function()
    local actual_args = nil
    package.loaded["plugins.first.snacks.gh_pr_story.util"] = {
      run_command = function(args)
        actual_args = args
        return [[{"number":42,"title":"Epic change","body":"Story mode","author":{"login":"l-lin"},"baseRefName":"main","headRefName":"chapter-mode","url":"https://github.com/acme/widgets/pull/42","additions":10,"deletions":4,"changedFiles":2}]], nil
      end,
    }
    _G.vim = {
      json = {
        decode = function()
          return {
            number = 42,
            title = "Epic change",
            body = "Story mode",
            author = { login = "l-lin" },
            baseRefName = "main",
            headRefName = "chapter-mode",
            url = "https://github.com/acme/widgets/pull/42",
            additions = 10,
            deletions = 4,
            changedFiles = 2,
          }
        end,
      },
    }
    table.unpack = nil

    local data = require("plugins.first.snacks.gh_pr_story.data")
    local actual, actual_error = data.fetch_pr_metadata({ pr = 42, repo = "acme/widgets" })

    assert.is_nil(actual_error)
    assert.are.same({
      "gh",
      "pr",
      "view",
      "42",
      "--json",
      "additions,author,baseRefName,body,changedFiles,deletions,headRefName,number,title,url",
      "--repo",
      "acme/widgets",
    }, actual_args)
    assert.are.equal(42, actual.number)
    assert.are.equal("Epic change", actual.title)
  end)
end)

describe("gh_pr_story.data.get_review_data", function()
  local original_data_module
  local original_util_module
  local original_story_module
  local original_diff_module
  local original_api_module
  local original_render_module
  local original_vim

  before_each(function()
    original_data_module = package.loaded["plugins.first.snacks.gh_pr_story.data"]
    original_util_module = package.loaded["plugins.first.snacks.gh_pr_story.util"]
    original_story_module = package.loaded["plugins.first.snacks.gh_pr_story.story"]
    original_diff_module = package.loaded["snacks.picker.source.diff"]
    original_api_module = package.loaded["snacks.gh.api"]
    original_render_module = package.loaded["snacks.gh.render"]
    original_vim = _G.vim

    package.loaded["plugins.first.snacks.gh_pr_story.data"] = nil
  end)

  after_each(function()
    package.loaded["plugins.first.snacks.gh_pr_story.data"] = original_data_module
    package.loaded["plugins.first.snacks.gh_pr_story.util"] = original_util_module
    package.loaded["plugins.first.snacks.gh_pr_story.story"] = original_story_module
    package.loaded["snacks.picker.source.diff"] = original_diff_module
    package.loaded["snacks.gh.api"] = original_api_module
    package.loaded["snacks.gh.render"] = original_render_module
    _G.vim = original_vim
  end)

  local function given_ctx()
    return {
      async = {
        schedule = function(_, fn)
          return fn()
        end,
      },
      git_root = function()
        return "/repo"
      end,
      opts = function(_, opts)
        return opts
      end,
    }
  end

  local function given_pr_json_decode(text)
    if text:match('"Epic change"') then
      return {
        number = 42,
        title = "Epic change",
        body = "Story mode",
        author = { login = "l-lin" },
        baseRefName = "main",
        headRefName = "chapter-mode",
        url = "https://github.com/acme/widgets/pull/42",
        additions = 10,
        deletions = 4,
        changedFiles = 1,
      }
    end
    error("unexpected decode input")
  end

  it("GIVEN PI generation fails WHEN building review data THEN it schedules a warning without calling vim.notify", function()
    local actual_notifications = {}

    package.loaded["plugins.first.snacks.gh_pr_story.util"] = {
      run_command = function(args)
        if args[3] == "diff" then
          return "diff --git a/lua/a.lua b/lua/a.lua", nil
        end
        return [[{"number":42,"title":"Epic change","body":"Story mode","author":{"login":"l-lin"},"baseRefName":"main","headRefName":"chapter-mode","url":"https://github.com/acme/widgets/pull/42","additions":10,"deletions":4,"changedFiles":1}]], nil
      end,
      schedule_notify = function(message, level)
        table.insert(actual_notifications, { message = message, level = level })
      end,
    }
    package.loaded["plugins.first.snacks.gh_pr_story.story"] = {
      generate_story = function()
        return nil, "Failed to spawn pi"
      end,
      fallback_story = function(diff_items, reason)
        return {
          summary = reason,
          chapters = {
            {
              id = "chapter-1",
              title = "Entire Diff",
              narrative = reason,
              files = { diff_items[1].file },
            },
          },
        }
      end,
      normalize_story = function(chapters)
        return chapters
      end,
    }
    package.loaded["snacks.gh.api"] = {
      get = function(item)
        return { repo = item.repo, number = item.number, type = item.type }
      end,
    }
    package.loaded["snacks.gh.render"] = {
      annotations = function()
        return {}
      end,
    }
    package.loaded["snacks.picker.source.diff"] = {
      diff = function()
        return function(cb)
          cb({ file = "lua/a.lua", cwd = "/repo", status = "M", diff = "diff a", pos = { 10, 0 } })
        end
      end,
    }
    _G.vim = {
      json = { decode = given_pr_json_decode },
      log = { levels = { WARN = 2 } },
      notify = function()
        error("get_review_data must not call vim.notify")
      end,
    }

    local data = require("plugins.first.snacks.gh_pr_story.data")
    local actual = data.get_review_data({ pr = 42, repo = "acme/widgets", previewers = { diff = {} } }, given_ctx())

    assert.are.equal("Failed to spawn pi", actual.story.summary)
    assert.are.same({
      {
        message = "gh_pr_story: Failed to spawn pi. Falling back to a single chapter.",
        level = 2,
      },
    }, actual_notifications)
  end)

  it("GIVEN an existing pending review WHEN building diff items THEN it requests comments so snacks can detect pendingReview", function()
    local actual_api_opts = nil

    package.loaded["plugins.first.snacks.gh_pr_story.util"] = {
      run_command = function(args)
        if args[3] == "diff" then
          return "diff --git a/lua/a.lua b/lua/a.lua", nil
        end
        return [[{"number":42,"title":"Epic change","body":"Story mode","author":{"login":"l-lin"},"baseRefName":"main","headRefName":"chapter-mode","url":"https://github.com/acme/widgets/pull/42","additions":10,"deletions":4,"changedFiles":1}]], nil
      end,
      schedule_notify = function()
      end,
    }
    package.loaded["plugins.first.snacks.gh_pr_story.story"] = {
      generate_story = function()
        return {
          summary = "A guided arc",
          chapters = {
            {
              id = "chapter-1",
              title = "Entire Diff",
              narrative = "Review it.",
              files = { "lua/a.lua" },
            },
          },
        }, nil
      end,
      fallback_story = function()
        error("happy path must not fall back")
      end,
      normalize_story = function(chapters)
        return chapters
      end,
    }
    package.loaded["snacks.gh.api"] = {
      get = function(item, opts)
        actual_api_opts = opts
        return {
          repo = item.repo,
          number = item.number,
          type = item.type,
          pendingReview = { id = "review-id" },
        }
      end,
    }
    package.loaded["snacks.gh.render"] = {
      annotations = function()
        return {}
      end,
    }
    package.loaded["snacks.picker.source.diff"] = {
      diff = function()
        return function(cb)
          cb({ file = "lua/a.lua", cwd = "/repo", status = "M", diff = "diff a", pos = { 10, 0 } })
        end
      end,
    }
    _G.vim = {
      json = { decode = given_pr_json_decode },
      log = { levels = { WARN = 2 } },
      notify = function()
        error("get_review_data must not call vim.notify")
      end,
    }

    local data = require("plugins.first.snacks.gh_pr_story.data")
    local actual = data.get_review_data({ pr = 42, repo = "acme/widgets", previewers = { diff = {} } }, given_ctx())

    assert.are.same({ "comments" }, actual_api_opts.fields)
    assert.are.same({ id = "review-id" }, actual.diff_items[1].gh_item.pendingReview)
  end)
end)
