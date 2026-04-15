dofile((debug.getinfo(1, "S").source:sub(2):match("^(.*)/[^/]+$")) .. "/spec_helper.lua")
if type(describe) ~= "function" then
  require("busted.runner")()
end

local gh_pr_story = require("plugins.first.snacks.gh_pr_story")

describe("gh_pr_story.to_tree_items", function()
  it("GIVEN story chapters WHEN building tree items THEN it nests file diff items under each chapter", function()
    local actual = gh_pr_story.to_tree_items({
      { file = "lua/a.lua", cwd = "/repo", status = "M", diff = "diff a", pos = { 10, 0 } },
      { file = "lua/b.lua", cwd = "/repo", status = "A", diff = "diff b", pos = { 20, 0 } },
    }, {
      summary = "A guided arc",
      chapters = {
        {
          id = "chapter-1",
          title = "Opening move",
          narrative = "Look at the setup first.",
          files = { "lua/a.lua" },
        },
        {
          id = "chapter-2",
          title = "The turn",
          narrative = "Then inspect the behavior.",
          files = { "lua/b.lua" },
        },
      },
    })

    assert.are.equal(4, #actual)
    assert.is_true(actual[1].dir)
    assert.are.equal("chapter://chapter-1", actual[1].file)
    assert.are.equal("Opening move", actual[1].display_name)
    assert.are.equal(1, actual[1].chapter_index)
    assert.are.equal("lua/a.lua", actual[2].file)
    assert.are.equal("chapter://chapter-1", actual[2].parent.file)
    assert.are.equal("M", actual[2].status)
    assert.are.same({ 10, 0 }, actual[2].pos)
    assert.is_true(actual[2].last)
    assert.are.equal("chapter://chapter-2", actual[3].file)
    assert.are.equal("lua/b.lua", actual[4].file)
    assert.are.equal("chapter://chapter-2", actual[4].parent.file)
  end)

  it("GIVEN a closed chapter WHEN building tree items THEN it hides that chapter's files", function()
    local actual = gh_pr_story.to_tree_items({
      { file = "lua/a.lua", cwd = "/repo", status = "M", diff = "diff a", pos = { 10, 0 } },
      { file = "lua/b.lua", cwd = "/repo", status = "A", diff = "diff b", pos = { 20, 0 } },
    }, {
      summary = "A guided arc",
      chapters = {
        {
          id = "chapter-1",
          title = "Opening move",
          narrative = "Look at the setup first.",
          files = { "lua/a.lua" },
        },
        {
          id = "chapter-2",
          title = "The turn",
          narrative = "Then inspect the behavior.",
          files = { "lua/b.lua" },
        },
      },
    }, { ["chapter-1"] = false })

    assert.are.equal(3, #actual)
    assert.are.equal("chapter://chapter-1", actual[1].file)
    assert.is_false(actual[1].open)
    assert.are.equal("chapter://chapter-2", actual[2].file)
    assert.are.equal("lua/b.lua", actual[3].file)
  end)
end)

describe("gh_pr_story.preview", function()
  local original_preview_module
  local original_gh_source
  local original_vim

  before_each(function()
    original_preview_module = package.loaded["snacks.picker.preview"]
    original_gh_source = package.loaded["snacks.picker.source.gh"]
    original_vim = _G.vim
  end)

  after_each(function()
    package.loaded["snacks.picker.preview"] = original_preview_module
    package.loaded["snacks.picker.source.gh"] = original_gh_source
    _G.vim = original_vim
  end)

  it("GIVEN a chapter item WHEN preview runs THEN it renders markdown commentary", function()
    local actual_ctx = nil
    package.loaded["snacks.picker.preview"] = {
      preview = function(ctx)
        actual_ctx = ctx
        return "chapter-preview"
      end,
    }
    package.loaded["snacks.picker.source.gh"] = {
      preview_diff = function()
        error("chapter preview must not delegate to gh diff")
      end,
    }
    _G.vim = {
      b = setmetatable({}, { __index = function(t, key)
        local value = {}
        rawset(t, key, value)
        return value
      end }),
    }

    local actual = gh_pr_story.preview({
      buf = 7,
      item = {
        dir = true,
        chapter_index = 2,
        story_summary = "A guided arc",
        chapter = {
          title = "The turn",
          narrative = "Then inspect the behavior.",
          files = { "lua/b.lua" },
        },
      },
    })

    assert.are.equal("chapter-preview", actual)
    assert.are.equal("markdown", actual_ctx.item.preview.ft)
    assert.truthy(actual_ctx.item.preview.text:match("## Chapter 2 — The turn"))
    assert.truthy(actual_ctx.item.preview.text:match("Then inspect the behavior"))
    assert.truthy(actual_ctx.item.preview.text:match("lua/b.lua"))
    assert.is_nil(_G.vim.b[7].snacks_gh)
  end)

  it("GIVEN a file item WHEN preview runs THEN it delegates to the gh diff preview", function()
    local actual_ctx = nil
    package.loaded["snacks.picker.preview"] = {
      preview = function()
        error("file preview must not use plain text preview")
      end,
    }
    package.loaded["snacks.picker.source.gh"] = {
      preview_diff = function(ctx)
        actual_ctx = ctx
        return "diff-preview"
      end,
    }
    _G.vim = { b = {} }

    local ctx = { item = { file = "lua/b.lua", dir = false } }
    local actual = gh_pr_story.preview(ctx)

    assert.are.equal("diff-preview", actual)
    assert.are.equal(ctx, actual_ctx)
  end)
end)

describe("gh_pr_story.gh_actions", function()
  local original_gh_source
  local original_vim

  before_each(function()
    original_gh_source = package.loaded["snacks.picker.source.gh"]
    original_vim = _G.vim
  end)

  after_each(function()
    package.loaded["snacks.picker.source.gh"] = original_gh_source
    _G.vim = original_vim
  end)

  it("GIVEN a chapter row WHEN requesting gh actions THEN it schedules a plain message instead of calling vim.notify", function()
    local actual_chunks = nil
    local actual_history = nil
    local actual_opts = nil
    local actual_scheduled = false

    package.loaded["snacks.picker.source.gh"] = {
      actions = {},
    }
    _G.vim = {
      api = {
        nvim_echo = function(chunks, history, opts)
          actual_chunks = chunks
          actual_history = history
          actual_opts = opts
        end,
      },
      log = { levels = { INFO = 2 } },
      notify = function()
        error("chapter rows must not call vim.notify")
      end,
      schedule = function(fn)
        actual_scheduled = true
        fn()
      end,
    }

    gh_pr_story.gh_actions({}, { dir = true }, {})

    assert.is_true(actual_scheduled)
    assert.are.same({ { "Select a file inside a chapter first", "None" } }, actual_chunks)
    assert.is_true(actual_history)
    assert.are.same({}, actual_opts)
  end)
end)
