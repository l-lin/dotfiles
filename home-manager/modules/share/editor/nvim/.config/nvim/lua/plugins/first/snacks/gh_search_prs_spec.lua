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

local gh_search_prs = require("plugins.first.snacks.gh_search_prs")

describe("gh_search_prs.gh_actions", function()
  local original_api_module
  local original_gh_source_module

  before_each(function()
    original_api_module = package.loaded["snacks.gh.api"]
    original_gh_source_module = package.loaded["snacks.picker.source.gh"]
  end)

  after_each(function()
    package.loaded["snacks.gh.api"] = original_api_module
    package.loaded["snacks.picker.source.gh"] = original_gh_source_module
  end)

  it("GIVEN a search-based PR item WHEN opening gh actions THEN it hydrates the full gh item before delegating", function()
    local actual_api_item = nil
    local actual_api_opts = nil
    local actual_forwarded_item = nil
    local expected_gh_item = {
      repo = "acme/widgets",
      number = 42,
      type = "pr",
      headRefOid = "abc123",
      pendingReview = { id = "review-id" },
    }

    package.loaded["snacks.gh.api"] = {
      get = function(item, opts)
        actual_api_item = item
        actual_api_opts = opts
        return expected_gh_item
      end,
    }
    package.loaded["snacks.picker.source.gh"] = {
      actions = {
        gh_actions = {
          action = function(picker, item)
            actual_forwarded_item = item
          end,
        },
      },
    }

    local item = {
      repo = "acme/widgets",
      number = 42,
      type = "pr",
      state = "open",
    }

    gh_search_prs.gh_actions({}, item, {})

    assert.are.same({ repo = "acme/widgets", number = 42, type = "pr" }, actual_api_item)
    assert.are.same({ fields = { "comments" } }, actual_api_opts)
    assert.are.equal(expected_gh_item, item.gh_item)
    assert.are.equal(item, actual_forwarded_item)
  end)
end)
