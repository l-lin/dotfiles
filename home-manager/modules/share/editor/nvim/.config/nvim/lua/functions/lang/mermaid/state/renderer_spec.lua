local state_renderer = require("functions.lang.mermaid.state.renderer")
local testdata = require("functions.lang.mermaid.testdata")

describe("mermaid.state.renderer", function()
  local upstream_fixtures = {
    "state_basic",
    "state_cjk",
    "state_composite_lr",
  }

  for _, fixture_name in ipairs(upstream_fixtures) do
    it(
      string.format("GIVEN upstream fixture `%s` WHEN rendering THEN output matches the Unicode snapshot", fixture_name),
      function()
        local fixture = testdata.load_golden(fixture_name)

        local actual_lines = assert(state_renderer.render(fixture.mermaid))
        local actual = table.concat(actual_lines, "\n")
        local expected = fixture.expected

        assert.are.equal(testdata.normalize_whitespace(expected), testdata.normalize_whitespace(actual))
      end
    )
  end

  it(
    "GIVEN a simple lifecycle WHEN rendering state pseudostates THEN start and end stay round circles instead of boxed nodes",
    function()
      local source = table.concat({
        "stateDiagram-v2",
        "  [*] --> Still",
        "  Still --> [*]",
      }, "\n")

      local actual = assert(state_renderer.render(source))
      local expected = { "●", "◉" }

      assert.are.same(expected[1], actual[1]:gsub("^%s+", ""))
      assert.are.same(expected[2], actual[#actual]:gsub("^%s+", ""))
    end
  )

  it(
    "GIVEN unsupported state note syntax WHEN rendering THEN it preserves the supported state graph and appends raw unsupported lines",
    function()
      local source = table.concat({
        "stateDiagram-v2",
        "  [*] --> Paid",
        "  Paid --> [*]",
        "  note right of Paid",
        "    Payment can be card",
        "  end note",
      }, "\n")

      local actual = assert(state_renderer.render(source))
      local expected = {
        "   ●",
        "    │",
        "    │",
        "    │",
        "    │",
        "    │",
        "    ▼",
        "╭──────╮",
        "│      │",
        "│ Paid │",
        "│      │",
        "╰───┬──╯",
        "    │",
        "    │",
        "    │",
        "    │",
        "    │",
        "    ▼",
        "   ◉",
        "",
        "[unsupported: note right of Paid]",
        "[unsupported: Payment can be card]",
        "[unsupported: end note]",
      }

      assert.are.equal(
        testdata.normalize_whitespace(table.concat(expected, "\n")),
        testdata.normalize_whitespace(table.concat(actual, "\n"))
      )
    end
  )
end)
