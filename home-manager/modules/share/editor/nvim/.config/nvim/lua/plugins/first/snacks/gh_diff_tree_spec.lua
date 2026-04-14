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

local gh_diff_tree = require("plugins.first.snacks.gh_diff_tree")

describe("snacks_gh_diff_tree.to_tree_items", function()
  it("GIVEN a single nested directory chain WHEN building tree items THEN it compacts intermediate directories", function()
    local actual = gh_diff_tree.to_tree_items({
      { file = "lua/plugins/first/snacks.lua", cwd = "/repo", status = "M", diff = "snacks diff" },
    })

    local actual_dir = actual[1]
    local actual_file = actual[2]

    assert.are.equal("lua/plugins/first", actual_dir.file)
    assert.are.equal("lua/plugins/first", actual_dir.display_name)
    assert.is_true(actual_dir.dir)
    assert.are.equal("lua/plugins/first/snacks.lua", actual_file.file)
    assert.are.equal("lua/plugins/first", actual_file.parent.file)
  end)

  it("GIVEN branching directories WHEN building tree items THEN it keeps the branching parent visible", function()
    local actual = gh_diff_tree.to_tree_items({
      { file = "lua/functions/git.lua", cwd = "/repo", status = "M", diff = "git diff" },
      { file = "lua/plugins/first/snacks.lua", cwd = "/repo", status = "M", diff = "snacks diff" },
    })

    local expected = {
      { file = "lua", dir = true, display_name = "lua" },
      { file = "lua/functions", dir = true, display_name = "functions" },
      { file = "lua/functions/git.lua", dir = false },
      { file = "lua/plugins/first", dir = true, display_name = "plugins/first" },
      { file = "lua/plugins/first/snacks.lua", dir = false },
    }

    for index, item in ipairs(actual) do
      assert.are.equal(expected[index].file, item.file)
      assert.are.equal(expected[index].dir, item.dir == true)
      if expected[index].display_name then
        assert.are.equal(expected[index].display_name, item.display_name)
      end
    end
  end)

  it("GIVEN a closed compact directory WHEN building tree items THEN it hides descendants until reopened", function()
    local actual = gh_diff_tree.to_tree_items({
      { file = "lua/plugins/first/snacks.lua", cwd = "/repo", status = "M", diff = "snacks diff" },
    }, { ["lua/plugins/first"] = false })

    assert.are.equal(1, #actual)
    assert.are.equal("lua/plugins/first", actual[1].file)
    assert.is_true(actual[1].dir)
    assert.is_false(actual[1].open)
  end)

  it("GIVEN diff items with preview metadata WHEN building tree items THEN leaf items keep that metadata", function()
    local actual = gh_diff_tree.to_tree_items({
      {
        file = "lua/functions/git.lua",
        cwd = "/repo",
        status = "R",
        diff = "renamed diff",
        rename = "lua/functions/old_git.lua",
        pos = { 12, 0 },
      },
    })

    local actual_leaf = actual[#actual]

    assert.are.equal("lua/functions/git.lua", actual_leaf.file)
    assert.are.equal("R", actual_leaf.status)
    assert.are.equal("renamed diff", actual_leaf.diff)
    assert.are.equal("lua/functions/old_git.lua", actual_leaf.rename)
    assert.are.same({ 12, 0 }, actual_leaf.pos)
  end)
end)

local function given_item_by_file(items, path)
  for _, item in ipairs(items) do
    if item.file == path then
      return item
    end
  end

  error("missing item: " .. path)
end

local function given_picker(items, refreshed_items)
  local actual_index = nil
  local actual_target = nil
  local actual_opts = nil
  local current_items = items

  return {
    list = {
      set_target = function() end,
      view = function(_, index)
        actual_index = index
      end,
    },
    find = function(_, opts)
      current_items = refreshed_items or current_items
      if opts.on_done then
        opts.on_done()
      end
    end,
    focus = function(_, target, opts)
      actual_target = target
      actual_opts = opts
    end,
    iter = function()
      local index = 0

      return function()
        index = index + 1
        local item = current_items[index]
        if item then
          return item, index
        end
      end
    end,
  }, {
    viewed_index = function()
      return actual_index
    end,
    focused_target = function()
      return actual_target
    end,
    focused_opts = function()
      return actual_opts
    end,
  }
end

describe("snacks_gh_diff_tree.open", function()
  it("GIVEN a file item WHEN open runs THEN it focuses the preview window", function()
    local picker, actual = given_picker({})

    gh_diff_tree.open(picker, { dir = false, file = "lua/functions/git.lua" })

    assert.are.equal("preview", actual.focused_target())
    assert.are.same({ show = true }, actual.focused_opts())
  end)

  it("GIVEN a closed directory WHEN open runs THEN it moves the cursor to the first child", function()
    local diff_items = {
      { file = "lua/functions/git.lua", cwd = "/repo", status = "M", diff = "git diff" },
      { file = "lua/plugins/first/snacks.lua", cwd = "/repo", status = "M", diff = "snacks diff" },
    }
    local items = gh_diff_tree.to_tree_items(diff_items, { ["lua"] = false })
    local refreshed_items = gh_diff_tree.to_tree_items(diff_items)
    local picker, actual = given_picker(items, refreshed_items)

    gh_diff_tree.open(picker, given_item_by_file(items, "lua"))

    assert.are.equal(2, actual.viewed_index())
  end)
end)

describe("snacks_gh_diff_tree.close", function()
  it("GIVEN a nested directory WHEN close runs THEN it moves the cursor to the parent directory", function()
    local items = gh_diff_tree.to_tree_items({
      { file = "lua/functions/git.lua", cwd = "/repo", status = "M", diff = "git diff" },
      { file = "lua/plugins/first/snacks.lua", cwd = "/repo", status = "M", diff = "snacks diff" },
    })
    local picker, actual = given_picker(items)

    gh_diff_tree.close(picker, given_item_by_file(items, "lua/plugins/first"))

    assert.are.equal(1, actual.viewed_index())
  end)
end)
