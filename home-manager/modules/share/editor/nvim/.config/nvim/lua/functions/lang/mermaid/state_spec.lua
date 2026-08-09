dofile((debug.getinfo(1, "S").source:sub(2):match("^(.*)/[^/]+$")) .. "/spec_helper.lua")
if type(describe) ~= "function" then
  require("busted.runner")()
end

local state = require("functions.lang.mermaid.state")
local testdata = require("functions.lang.mermaid.testdata")

local function then_rendered_output_matches_fixture(fixture_name)
  local fixture = testdata.load_golden(fixture_name)

  local actual_lines = assert(state.render(fixture.mermaid))
  local actual = table.concat(actual_lines, "\n")
  local expected = fixture.expected

  assert.are.equal(testdata.normalize_whitespace(expected), testdata.normalize_whitespace(actual))
end

describe("mermaid.state.render", function()
  local upstream_fixtures = {
    "state_basic",
    "state_cjk",
    "state_composite_lr",
  }

  for _, fixture_name in ipairs(upstream_fixtures) do
    it(string.format("GIVEN upstream fixture `%s` WHEN rendering THEN output matches the Unicode snapshot", fixture_name), function()
      then_rendered_output_matches_fixture(fixture_name)
    end)
  end

  it("GIVEN unsupported state note syntax WHEN rendering THEN it preserves the supported state graph and appends raw unsupported lines", function()
    local source = table.concat({
      "stateDiagram-v2",
      "  [*] --> Paid",
      "  Paid --> [*]",
      "  note right of Paid",
      "    Payment can be card",
      "  end note",
    }, "\n")

    local actual = assert(state.render(source))
    local expected = {
      "●──────●",
      "│      │",
      "●──────●",
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
      "    ▼",
      "╔══════╗",
      "║      ║",
      "╚══════╝",
      "",
      "[unsupported: note right of Paid]",
      "[unsupported: Payment can be card]",
      "[unsupported: end note]",
    }

    assert.are.equal(testdata.normalize_whitespace(table.concat(expected, "\n")), testdata.normalize_whitespace(table.concat(actual, "\n")))
  end)
end)
