dofile((debug.getinfo(1, "S").source:sub(2):match("^(.*)/[^/]+$")) .. "/spec_helper.lua")
if type(describe) ~= "function" then
  require("busted.runner")()
end

describe("gh_pr_story.util.run_command", function()
  local original_util_module
  local original_async_module
  local original_spawn_module
  local original_vim

  before_each(function()
    original_util_module = package.loaded["plugins.first.snacks.gh_pr_story.util"]
    original_async_module = package.loaded["snacks.picker.util.async"]
    original_spawn_module = package.loaded["snacks.util.spawn"]
    original_vim = _G.vim
    package.loaded["plugins.first.snacks.gh_pr_story.util"] = nil
  end)

  after_each(function()
    package.loaded["plugins.first.snacks.gh_pr_story.util"] = original_util_module
    package.loaded["snacks.picker.util.async"] = original_async_module
    package.loaded["snacks.util.spawn"] = original_spawn_module
    _G.vim = original_vim
  end)

  it("GIVEN a snacks async context WHEN running a command THEN it uses snacks.spawn with a merged uv env instead of vim.system", function()
    local actual_spawn_opts = nil

    package.loaded["snacks.picker.util.async"] = {
      running = function()
        return {}
      end,
    }
    package.loaded["snacks.util.spawn"] = {
      new = function(opts)
        actual_spawn_opts = opts
        return {
          wait = function(self)
            return self
          end,
          out = function()
            return "chapter json"
          end,
          err = function()
            return ""
          end,
          failed = function()
            return false
          end,
        }
      end,
    }
    _G.vim = {
      fn = {
        environ = function()
          return {
            HOME = "/Users/l-lin",
            PATH = "/usr/local/bin:/bin",
          }
        end,
      },
      log = { levels = { ERROR = 4, WARN = 3, INFO = 2 } },
      system = function()
        error("async finder path must not call vim.system")
      end,
      trim = function(value)
        return (value:gsub("^%s+", ""):gsub("%s+$", ""))
      end,
    }

    local util = require("plugins.first.snacks.gh_pr_story.util")
    local actual_stdout, actual_error = util.run_command({ "pi", "-p", "prompt" }, {
      cwd = "/repo",
      env = { PI_CODING_AGENT_DIR = "/tmp/pi" },
      timeout_ms = 123,
    })

    local actual_env = {}
    for _, entry in ipairs(actual_spawn_opts.env or {}) do
      local key, value = entry:match("^([^=]+)=(.*)$")
      actual_env[key] = value
    end

    assert.are.equal("chapter json", actual_stdout)
    assert.is_nil(actual_error)
    assert.are.same({ "-p", "prompt" }, actual_spawn_opts.args)
    assert.are.equal("pi", actual_spawn_opts.cmd)
    assert.are.equal("/repo", actual_spawn_opts.cwd)
    assert.are.equal(123, actual_spawn_opts.timeout)
    assert.are.same({
      HOME = "/Users/l-lin",
      PATH = "/usr/local/bin:/bin",
      PI_CODING_AGENT_DIR = "/tmp/pi",
    }, actual_env)
  end)

  it("GIVEN no snacks async context WHEN running a command THEN it falls back to vim.system", function()
    local actual_args = nil
    local actual_opts = nil

    package.loaded["snacks.picker.util.async"] = {
      running = function()
        return nil
      end,
    }
    package.loaded["snacks.util.spawn"] = {
      new = function()
        error("non-async path must not use snacks.spawn")
      end,
    }
    _G.vim = {
      log = { levels = { ERROR = 4, WARN = 3, INFO = 2 } },
      system = function(args, opts)
        actual_args = args
        actual_opts = opts
        return {
          wait = function()
            return {
              code = 0,
              stdout = "diff text",
              stderr = "",
            }
          end,
        }
      end,
      trim = function(value)
        return (value:gsub("^%s+", ""):gsub("%s+$", ""))
      end,
    }

    local util = require("plugins.first.snacks.gh_pr_story.util")
    local actual_stdout, actual_error = util.run_command({ "gh", "pr", "diff", "42" }, {
      cwd = "/repo",
      env = { GH_TOKEN = "secret" },
      timeout_ms = 456,
    })

    assert.are.equal("diff text", actual_stdout)
    assert.is_nil(actual_error)
    assert.are.same({ "gh", "pr", "diff", "42" }, actual_args)
    assert.are.same({
      cwd = "/repo",
      env = { GH_TOKEN = "secret" },
      text = true,
      timeout = 456,
    }, actual_opts)
  end)
end)

describe("gh_pr_story.util.schedule_notify", function()
  local original_util_module
  local original_vim

  before_each(function()
    original_util_module = package.loaded["plugins.first.snacks.gh_pr_story.util"]
    original_vim = _G.vim
    package.loaded["plugins.first.snacks.gh_pr_story.util"] = nil
  end)

  after_each(function()
    package.loaded["plugins.first.snacks.gh_pr_story.util"] = original_util_module
    _G.vim = original_vim
  end)

  it("GIVEN a warning message WHEN scheduling notify THEN it uses nvim_echo instead of vim.notify", function()
    local actual_chunks = nil
    local actual_history = nil
    local actual_opts = nil
    local actual_scheduled = false

    _G.vim = {
      api = {
        nvim_echo = function(chunks, history, opts)
          actual_chunks = chunks
          actual_history = history
          actual_opts = opts
        end,
      },
      log = { levels = { ERROR = 4, WARN = 3, INFO = 2 } },
      notify = function()
        error("schedule_notify must not call vim.notify")
      end,
      schedule = function(fn)
        actual_scheduled = true
        fn()
      end,
      trim = function(value)
        return (value:gsub("^%s+", ""):gsub("%s+$", ""))
      end,
    }

    local util = require("plugins.first.snacks.gh_pr_story.util")
    util.schedule_notify("warning text", _G.vim.log.levels.WARN)

    assert.is_true(actual_scheduled)
    assert.are.same({ { "warning text", "WarningMsg" } }, actual_chunks)
    assert.is_true(actual_history)
    assert.are.same({}, actual_opts)
  end)
end)
