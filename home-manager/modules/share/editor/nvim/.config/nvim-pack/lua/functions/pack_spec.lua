local pack = require("functions.pack")

describe("pack.to_pack_specs", function()
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
    local actual = pack.to_pack_specs(expected)

    -- THEN
    assert.are.same(expected, actual)
  end)

  it("unwraps helper-backed plugin modules and ignores helper-only modules", function()
    -- GIVEN
    local blink_sources = given_plugin_spec("https://github.com/example/friendly-snippets")
    local blink = given_plugin_spec("https://github.com/example/blink.cmp", {
      setup = function() end,
    })
    local emoji = given_plugin_spec("https://github.com/example/emoji.nvim")
    local helper_backed_module = {
      spec = {
        blink_sources,
        blink,
      },
      add_provider = function() end,
    }
    local helper_only_module = {
      setup = function() end,
    }
    local expected = {
      blink_sources,
      blink,
      emoji,
    }

    -- WHEN
    local actual = pack.to_pack_specs({
      helper_backed_module,
      helper_only_module,
      emoji,
    })

    -- THEN
    assert.are.same(expected, actual)
  end)

  it("does not add duplicate plugin specs across helper modules and nested groups", function()
    -- GIVEN
    local schemastore = given_plugin_spec("https://github.com/b0o/SchemaStore.nvim")
    local json = given_plugin_spec("https://github.com/example/json-plugin")
    local yaml = given_plugin_spec("https://github.com/example/yaml-plugin")
    local expected = {
      schemastore,
      json,
      yaml,
    }

    -- WHEN
    local actual = pack.to_pack_specs({
      {
        { spec = { schemastore, json } },
        { spec = { given_plugin_spec("https://github.com/b0o/SchemaStore.nvim"), yaml } },
      },
    })

    -- THEN
    assert.are.same(expected, actual)
  end)
end)
