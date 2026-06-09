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

describe("functions.gitbrowse", function()
  local gitbrowse
  local original_vim

  local function given_stubbed_vim()
    _G.vim = {
      uv = {
        fs_stat = function()
          return nil
        end,
      },
      tbl_deep_extend = function(_, base, overrides)
        local actual = {}
        for key, value in pairs(base) do
          actual[key] = value
        end
        for key, value in pairs(overrides or {}) do
          actual[key] = value
        end
        return actual
      end,
      deepcopy = function(value)
        if type(value) ~= "table" then
          return value
        end
        local actual = {}
        for key, item in pairs(value) do
          actual[key] = _G.vim.deepcopy(item)
        end
        return actual
      end,
      split = function(value, separator)
        local actual = {}
        local pattern = string.format("([^%s]+)", separator)
        for item in value:gmatch(pattern) do
          table.insert(actual, item)
        end
        return actual
      end,
      trim = function(value)
        return (value:gsub("^%s+", ""):gsub("%s+$", ""))
      end,
      fs = {
        normalize = function(path)
          return path
        end,
      },
      fn = {
        system = function()
          return ""
        end,
        setreg = function() end,
        getcwd = function()
          return "/tmp"
        end,
        expand = function()
          return "not-a-commit"
        end,
        fnamemodify = function(path, modifier)
          assert.are.equal(":h", modifier)
          return path:match("^(.*)/")
        end,
      },
      api = {
        nvim_get_current_buf = function()
          return 7
        end,
        nvim_buf_get_mark = function(_, mark)
          if mark == "<" then
            return { 0, 0 }
          end
          return { 0, 0 }
        end,
        nvim_buf_get_name = function()
          return ""
        end,
      },
      ui = {
        select = function(items, _, on_choice)
          on_choice(items[1])
        end,
        open = function() end,
      },
      v = { shell_error = 0 },
      notify = function() end,
      log = { levels = { INFO = 2, ERROR = 4 } },
    }
  end

  before_each(function()
    original_vim = _G.vim
    given_stubbed_vim()
    package.loaded["functions.gitbrowse"] = nil
    gitbrowse = require("functions.gitbrowse")
  end)

  after_each(function()
    package.loaded["functions.gitbrowse"] = nil
    _G.vim = original_vim
  end)

  it("GIVEN the module WHEN required THEN it only exposes branch selection entrypoint", function()
    local expected = gitbrowse.browse_with_branch_select

    assert.is_function(expected)
    assert.is_nil(gitbrowse.open)
    assert.is_nil(gitbrowse.get_url)
    assert.is_nil(gitbrowse.handle_url)
  end)

  it("GIVEN the current branch is main WHEN yanking a branch URL THEN it copies the URL to the clipboard", function()
    local actual = {}
    _G.vim.fn.system = function(command)
      if command == "git rev-parse --abbrev-ref HEAD" then
        return "main\n"
      end
      if type(command) == "table" then
        local joined = table.concat(command, " ")
        if joined == "git -C /tmp rev-parse --abbrev-ref HEAD" then
          return "main\n"
        end
        if joined == "git -C /tmp remote -v" then
          return "origin git@github.com:l-lin/dotfiles.git (fetch)\n"
        end
      end
      return ""
    end
    _G.vim.fn.setreg = function(register, value)
      actual.register = register
      actual.value = value
    end

    gitbrowse.browse_with_branch_select({ yank = true })

    local expected = {
      register = "+",
      value = "https://github.com/l-lin/dotfiles/tree/main",
    }

    assert.are.same(expected, actual)
  end)

  it(
    "GIVEN a visual selection on a feature branch WHEN opening the main branch URL THEN it opens the file URL with selected lines",
    function()
      local actual
      _G.vim.uv.fs_stat = function(path)
        return path == "/tmp/lua/functions/gitbrowse.lua" and { type = "file" } or nil
      end
      _G.vim.api.nvim_buf_get_name = function()
        return "/tmp/lua/functions/gitbrowse.lua"
      end
      _G.vim.api.nvim_buf_get_mark = function(_, mark)
        if mark == "<" then
          return { 9, 0 }
        end
        return { 3, 0 }
      end
      _G.vim.ui.select = function(items, context, on_choice)
        if context.prompt == "Open Git URL - Select Branch" then
          on_choice(items[2])
          return
        end
        on_choice(items[1])
      end
      _G.vim.ui.open = function(url)
        actual = url
      end
      _G.vim.fn.system = function(command)
        if command == "git rev-parse --abbrev-ref HEAD" then
          return "feature/test\n"
        end
        if command == "git show-ref --verify --quiet refs/heads/main && echo 1 || echo 0" then
          return "1\n"
        end
        if type(command) == "table" then
          local joined = table.concat(command, " ")
          if joined == "git -C /tmp/lua/functions rev-parse --abbrev-ref HEAD" then
            return "feature/test\n"
          end
          if joined == "git -C /tmp/lua/functions ls-files --full-name /tmp/lua/functions/gitbrowse.lua" then
            return "lua/functions/gitbrowse.lua\n"
          end
          if joined == "git -C /tmp/lua/functions remote -v" then
            return "origin git@github.com:l-lin/dotfiles.git (fetch)\n"
          end
        end
        return ""
      end

      gitbrowse.browse_with_branch_select({ visual = true })

      local expected = "https://github.com/l-lin/dotfiles/blob/main/lua/functions/gitbrowse.lua#L3-L9"

      assert.are.equal(expected, actual)
    end
  )
end)
