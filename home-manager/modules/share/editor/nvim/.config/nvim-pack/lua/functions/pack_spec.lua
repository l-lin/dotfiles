local array = require("functions.array")

describe("array.flatten", function()
  local function given_plugin_spec(src, data)
    local plugin_spec = { src = src }
    if data ~= nil then
      plugin_spec.data = data
    end
    return plugin_spec
  end

  it("returns a flat plugin spec list unchanged", function()
    -- GIVEN
    local expected = {
      given_plugin_spec("https://github.com/example/one"),
      given_plugin_spec("https://github.com/example/two"),
    }

    -- WHEN
    local actual = array.flatten(expected)

    -- THEN
    assert.are.same(expected, actual)
  end)

  it("flattens nested plugin groups that mix plugin arrays and plugin specs", function()
    -- GIVEN
    local emoji_dependencies = {
      given_plugin_spec("https://github.com/nvim-lua/plenary.nvim"),
      given_plugin_spec("https://github.com/l-lin/emoji.nvim"),
    }
    local mini_files = given_plugin_spec("https://github.com/nvim-mini/mini.files", {
      setup = function() end,
    })
    local expected = {
      emoji_dependencies[1],
      emoji_dependencies[2],
      mini_files,
    }

    -- WHEN
    local actual = array.flatten({
      emoji_dependencies,
      mini_files,
    })

    -- THEN
    assert.are.same(expected, actual)
  end)

  it("does not add duplicate plugin specs with the same src", function()
    -- GIVEN
    local first_plenary = given_plugin_spec("https://github.com/nvim-lua/plenary.nvim", {
      priority = "first",
    })
    local duplicated_plenary = given_plugin_spec("https://github.com/nvim-lua/plenary.nvim", {
      priority = "second",
    })
    local emoji = given_plugin_spec("https://github.com/l-lin/emoji.nvim")
    local expected = {
      first_plenary,
      emoji,
    }

    -- WHEN
    local actual = array.flatten({
      { first_plenary, emoji },
      duplicated_plenary,
      first_plenary,
    })

    -- THEN
    assert.are.same(expected, actual)
  end)
end)
