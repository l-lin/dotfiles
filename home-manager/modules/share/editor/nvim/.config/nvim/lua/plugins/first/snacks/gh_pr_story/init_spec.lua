dofile((debug.getinfo(1, "S").source:sub(2):match("^(.*)/[^/]+$")) .. "/spec_helper.lua")
if type(describe) ~= "function" then
  require("busted.runner")()
end

local gh_pr_story = require("plugins.first.snacks.gh_pr_story")

describe("gh_pr_story.normalize_story", function()
  it("GIVEN duplicate and unknown files WHEN normalizing THEN it keeps real files once and appends unassigned changes", function()
    local actual = gh_pr_story.normalize_story({
      summary = "A guided arc",
      chapters = {
        {
          id = "chapter-1",
          title = "Opening move",
          narrative = "Look at the setup first.",
          files = { "lua/a.lua", "lua/ghost.lua", "lua/a.lua" },
        },
      },
    }, {
      { file = "lua/a.lua", diff = "diff a", status = "M", pos = { 10, 0 } },
      { file = "lua/b.lua", diff = "diff b", status = "A", pos = { 20, 0 } },
    })

    assert.are.equal(2, #actual.chapters)
    assert.are.same({ "lua/a.lua" }, actual.chapters[1].files)
    assert.are.equal("Unassigned Changes", actual.chapters[2].title)
    assert.are.same({ "lua/b.lua" }, actual.chapters[2].files)
  end)

  it("GIVEN no diff items and a fallback chapter WHEN normalizing THEN it preserves a chapter so the picker can explain the failure", function()
    local actual = gh_pr_story.normalize_story({
      summary = "Automatic chaptering failed: boom",
      chapters = {
        {
          id = "chapter-1",
          title = "Entire Diff",
          narrative = "Automatic chaptering failed: boom Review the raw file diff directly.",
          files = {},
        },
      },
    }, {})

    assert.are.equal(1, #actual.chapters)
    assert.are.equal("Entire Diff", actual.chapters[1].title)
    assert.are.same({}, actual.chapters[1].files)
  end)
end)

describe("gh_pr_story.open_from_clipboard", function()
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

  it("GIVEN a PR URL in the clipboard WHEN opening THEN it updates the target and opens the story picker", function()
    local actual_target = nil
    local actual_picker_opts = nil
    package.loaded["functions.git"] = {
      extract_repo_name_and_pr_id_from_url = function(input)
        assert.are.equal("https://github.com/acme/widgets/pull/42", input)
        return "acme/widgets", 42
      end,
    }
    _G.Snacks = {
      picker = {
        gh_pr_story = function(opts)
          actual_picker_opts = opts
        end,
      },
    }
    _G.vim = {
      fn = {
        getreg = function(register)
          assert.are.equal("+", register)
          return "https://github.com/acme/widgets/pull/42\n"
        end,
      },
      notify = function()
        error("valid clipboard content must not notify")
      end,
      log = { levels = { ERROR = 1 } },
    }

    gh_pr_story.open_from_clipboard(function(repo, pr)
      actual_target = { repo = repo, pr = pr }
    end)

    assert.are.same({ repo = "acme/widgets", pr = 42 }, actual_target)
    assert.are.same({ repo = "acme/widgets", pr = 42 }, actual_picker_opts)
  end)

  it("GIVEN a non-PR URL in the clipboard WHEN opening THEN it notifies and does not open the picker", function()
    local actual_notified = nil
    package.loaded["functions.git"] = {
      extract_repo_name_and_pr_id_from_url = function()
        return nil, nil
      end,
    }
    _G.Snacks = {
      picker = {
        gh_pr_story = function()
          error("invalid clipboard content must not open the picker")
        end,
      },
    }
    _G.vim = {
      fn = {
        getreg = function()
          return "https://example.com/nope"
        end,
      },
      notify = function(message, level)
        actual_notified = { message = message, level = level }
      end,
      log = { levels = { ERROR = 9 } },
    }

    gh_pr_story.open_from_clipboard()

    assert.are.same({
      message = "Clipboard does not contain a pull request URL",
      level = 9,
    }, actual_notified)
  end)
end)

describe("gh_pr_story.build_pi_command", function()
  local original_vim

  before_each(function()
    original_vim = _G.vim
  end)

  after_each(function()
    _G.vim = original_vim
  end)

  it("GIVEN pi is on PATH WHEN building the command THEN it uses exepath instead of a machine-specific path", function()
    _G.vim = {
      fn = {
        exepath = function(command)
          assert.are.equal("pi", command)
          return "/opt/bin/pi"
        end,
      },
    }

    local actual = gh_pr_story.build_pi_command("/tmp/story-prompt")

    assert.are.same({
      "/opt/bin/pi",
      "--models",
      gh_pr_story.STORY_MODEL,
      "--no-session",
      "-p",
      "@/tmp/story-prompt",
    }, actual)
  end)
end)
