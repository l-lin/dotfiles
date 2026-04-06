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
      setup_dap = function() end,
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

describe("pack.group_plugin_names", function()
  local function given_plugin_info(name, is_active)
    return {
      active = is_active,
      spec = { name = name },
    }
  end

  it("groups installed plugins into active and inactive lists", function()
    -- GIVEN
    local plugin_infos = {
      given_plugin_info("snacks.nvim", true),
      given_plugin_info("blink.cmp", true),
      given_plugin_info("nvim-dap-ui", false),
    }
    local expected = {
      installed = { "blink.cmp", "nvim-dap-ui", "snacks.nvim" },
      active = { "blink.cmp", "snacks.nvim" },
      inactive = { "nvim-dap-ui" },
    }

    -- WHEN
    local actual = pack.group_plugin_names(plugin_infos)

    -- THEN
    assert.are.same(expected, actual)
  end)

  it("deduplicates plugin names and ignores entries without a resolved name", function()
    -- GIVEN
    local plugin_infos = {
      given_plugin_info("blink.cmp", true),
      given_plugin_info("blink.cmp", false),
      { active = false, spec = {} },
      { active = true },
    }
    local expected = {
      installed = { "blink.cmp" },
      active = { "blink.cmp" },
      inactive = {},
    }

    -- WHEN
    local actual = pack.group_plugin_names(plugin_infos)

    -- THEN
    assert.are.same(expected, actual)
  end)
end)

describe("pack.plugin_report_lines", function()
  local function given_plugin_info(name, src, is_active)
    return {
      active = is_active,
      spec = { name = name, src = src },
    }
  end

  it("formats installed plugins into a single markdown list with status icons", function()
    -- GIVEN
    local plugin_infos = {
      given_plugin_info("snacks.nvim", "https://github.com/folke/snacks.nvim", true),
      given_plugin_info("blink.cmp", "https://github.com/saghen/blink.cmp", true),
      given_plugin_info("nvim-dap-ui", "https://github.com/rcarriga/nvim-dap-ui", false),
    }
    local expected = {
      "# nvim-pack plugins",
      "",
      "- Installed directory: `~/.local/share/nvim-pack/site/pack/core/opt`",
      "- Installed: 3",
      "- Active: 2",
      "- Inactive: 1",
      "",
      "## Plugins (3)",
      "-  [blink.cmp](https://github.com/saghen/blink.cmp)",
      "-  [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui)",
      "-  [snacks.nvim](https://github.com/folke/snacks.nvim)",
    }

    -- WHEN
    local actual = pack.plugin_report_lines(plugin_infos, "~/.local/share/nvim-pack/site/pack/core/opt")

    -- THEN
    assert.are.same(expected, actual)
  end)

  it("falls back to the plugin name when the source URL is missing", function()
    -- GIVEN
    local plugin_infos = {
      given_plugin_info("blink.cmp", nil, true),
    }
    local expected = {
      "# nvim-pack plugins",
      "",
      "- Installed directory: `~/.local/share/nvim-pack/site/pack/core/opt`",
      "- Installed: 1",
      "- Active: 1",
      "- Inactive: 0",
      "",
      "## Plugins (1)",
      "-  blink.cmp",
    }

    -- WHEN
    local actual = pack.plugin_report_lines(plugin_infos, "~/.local/share/nvim-pack/site/pack/core/opt")

    -- THEN
    assert.are.same(expected, actual)
  end)
end)
