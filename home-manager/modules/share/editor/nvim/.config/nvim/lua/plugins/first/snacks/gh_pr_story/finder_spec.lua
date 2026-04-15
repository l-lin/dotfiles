dofile((debug.getinfo(1, "S").source:sub(2):match("^(.*)/[^/]+$")) .. "/spec_helper.lua")
if type(describe) ~= "function" then
  require("busted.runner")()
end

local gh_pr_story = require("plugins.first.snacks.gh_pr_story")

describe("gh_pr_story.finder", function()
  local original_diff_module
  local original_api_module
  local original_render_module
  local original_vim

  before_each(function()
    original_diff_module = package.loaded["snacks.picker.source.diff"]
    original_api_module = package.loaded["snacks.gh.api"]
    original_render_module = package.loaded["snacks.gh.render"]
    original_vim = _G.vim
  end)

  after_each(function()
    package.loaded["snacks.picker.source.diff"] = original_diff_module
    package.loaded["snacks.gh.api"] = original_api_module
    package.loaded["snacks.gh.render"] = original_render_module
    _G.vim = original_vim
  end)

  it("GIVEN a PR story picker WHEN finder runs twice THEN it builds the chapter split once with pi and reuses the cached story", function()
    local temp_index = 0
    local system_calls = {}
    local prompt_text = nil
    local tmp_root = os.getenv("TMPDIR") or "/tmp"
    local temp_paths_by_fd = {}
    local created_directories = {}

    package.loaded["snacks.gh.api"] = {
      get = function(item)
        return {
          repo = item.repo,
          number = item.number,
          type = item.type,
        }
      end,
    }
    package.loaded["snacks.gh.render"] = {
      annotations = function()
        return {}
      end,
    }
    package.loaded["snacks.picker.source.diff"] = {
      diff = function(opts)
        assert.are.equal("fancy", opts.previewers.diff.style)
        return function(cb)
          cb({ file = "lua/a.lua", cwd = "/repo", status = "M", diff = "diff a", pos = { 10, 0 } })
          cb({ file = "lua/b.lua", cwd = "/repo", status = "A", diff = "diff b", pos = { 20, 0 } })
        end
      end,
    }
    _G.vim = {
      system = function(args, opts)
        table.insert(system_calls, { args = args, opts = opts })

        return {
          wait = function()
            if args[1] == "gh" and args[2] == "pr" and args[3] == "view" then
              return {
                code = 0,
                stdout = [[{"number":42,"title":"Epic change","body":"Add a story review mode.","author":{"login":"l-lin"},"baseRefName":"main","headRefName":"feature/story-review","url":"https://github.com/acme/widgets/pull/42","additions":10,"deletions":4,"changedFiles":2}]],
                stderr = "",
              }
            end

            if args[1] == "gh" and args[2] == "pr" and args[3] == "diff" then
              return {
                code = 0,
                stdout = [[diff --git a/lua/a.lua b/lua/a.lua
--- a/lua/a.lua
+++ b/lua/a.lua
@@ -1,1 +1,1 @@
-old
+new]],
                stderr = "",
              }
            end

            if args[1]:match("/pi$") or args[1] == "pi" then
              assert.are.equal("--models", args[2])
              assert.are.equal("anthropic/claude-sonnet-4-6", args[3])
              assert.are.equal("-p", args[5])
              assert.truthy(args[6]:match("^@"))
              assert.truthy(opts.env.PI_CODING_AGENT_DIR:match("/gh_pr_story_pi$"))

              local prompt_file = assert(io.open(args[6]:sub(2), "r"))
              prompt_text = prompt_file:read("*a")
              prompt_file:close()

              return {
                code = 0,
                stdout = [[{"summary":"A guided arc","chapters":[{"id":"chapter-1","title":"Opening move","narrative":"Set the board before the sparks fly.","files":["lua/a.lua"]},{"id":"chapter-2","title":"The turn","narrative":"Then inspect the new behavior.","files":["lua/b.lua"]}]}]],
                stderr = "",
              }
            end

            error("unexpected command: " .. table.concat(args, " "))
          end,
        }
      end,
      json = {
        decode = function(text)
          if text:match('"Epic change"') then
            return {
              number = 42,
              title = "Epic change",
              body = "Add a story review mode.",
              author = { login = "l-lin" },
              baseRefName = "main",
              headRefName = "feature/story-review",
              url = "https://github.com/acme/widgets/pull/42",
              additions = 10,
              deletions = 4,
              changedFiles = 2,
            }
          end

          return {
            summary = "A guided arc",
            chapters = {
              {
                id = "chapter-1",
                title = "Opening move",
                narrative = "Set the board before the sparks fly.",
                files = { "lua/a.lua" },
              },
              {
                id = "chapter-2",
                title = "The turn",
                narrative = "Then inspect the new behavior.",
                files = { "lua/b.lua" },
              },
            },
          }
        end,
      },
      uv = {
        fs_close = function(fd)
          assert.is_truthy(temp_paths_by_fd[fd])
          return true
        end,
        fs_mkdir = function(path)
          created_directories[path] = true
          assert.truthy(path:match("/gh_pr_story_pi$"))
          return true
        end,
        fs_mkstemp = function(template)
          assert.truthy(template:match("gh_pr_story_prompt%.XXXXXX$"))
          temp_index = temp_index + 1
          local path = string.format("%s/gh_pr_story_spec_%d", tmp_root, temp_index)
          temp_paths_by_fd[temp_index] = path
          local handle = assert(io.open(path, "w"))
          handle:close()
          return temp_index, path
        end,
        fs_stat = function(path)
          if created_directories[path] then
            return { type = "directory" }
          end
          return nil
        end,
        fs_write = function(fd, data)
          local handle = assert(io.open(temp_paths_by_fd[fd], "w"))
          handle:write(data)
          handle:close()
          return #data
        end,
        os_tmpdir = function()
          return tmp_root
        end,
      },
      trim = function(text)
        return (text:gsub("^%s+", ""):gsub("%s+$", ""))
      end,
      notify = function()
        error("finder happy path must not notify")
      end,
      log = { levels = { WARN = 2 } },
    }

    local picker = { matcher = { opts = {} } }
    local ctx = {
      picker = picker,
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

    local actual = {}
    gh_pr_story.finder({ pr = 42, repo = "acme/widgets", previewers = { diff = {} } }, ctx)(function(item)
      table.insert(actual, item)
    end)
    gh_pr_story.finder({ pr = 42, repo = "acme/widgets", previewers = { diff = {} } }, ctx)(function(item)
      table.insert(actual, item)
    end)

    local pi_call_count = 0
    for _, call in ipairs(system_calls) do
      if call.args[1]:match("/pi$") or call.args[1] == "pi" then
        pi_call_count = pi_call_count + 1
      end
    end

    assert.is_true(picker.matcher.opts.keep_parents)
    assert.truthy(prompt_text:match("Sanderson%-adjacent"))
    assert.truthy(prompt_text:match("diff %-%-git a/lua/a.lua b/lua/a.lua"))
    assert.are.equal(1, pi_call_count)
    assert.are.equal(8, #actual)
    assert.are.equal("chapter://chapter-1", actual[1].file)
    assert.are.equal("lua/a.lua", actual[2].file)
    assert.are.equal("chapter://chapter-2", actual[3].file)
    assert.are.equal("lua/b.lua", actual[4].file)
  end)
end)
