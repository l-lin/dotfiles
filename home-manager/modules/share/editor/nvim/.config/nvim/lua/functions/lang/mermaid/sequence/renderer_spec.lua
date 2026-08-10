local sequence = require("functions.lang.mermaid.sequence.renderer")
local testdata = require("functions.lang.mermaid.testdata")

local function then_rendered_output_matches_fixture(fixture_name)
  local fixture = testdata.load_golden(fixture_name)

  local actual_lines = assert(sequence.render(fixture.mermaid))
  local actual = table.concat(actual_lines, "\n")
  local expected = fixture.expected

  assert.are.equal(testdata.normalize_whitespace(expected), testdata.normalize_whitespace(actual))
end

describe("mermaid.sequence.render", function()
  local upstream_fixtures = {
    "seq_basic",
    "seq_multiple_messages",
    "seq_self_message",
    "sequence_multiline",
  }

  for _, fixture_name in ipairs(upstream_fixtures) do
    it(string.format("GIVEN upstream fixture `%s` WHEN rendering THEN output matches the Unicode snapshot", fixture_name), function()
      then_rendered_output_matches_fixture(fixture_name)
    end)
  end

  it("GIVEN explicit activation syntax outside the upstream subset WHEN rendering THEN it preserves supported messages and appends raw unsupported lines", function()
    local source = table.concat({
      "sequenceDiagram",
      "  participant A",
      "  participant B",
      "  autonumber",
      "  A->>B: Hello",
      "  activate B",
      "  B-->>A: Hi",
      "  deactivate B",
    }, "\n")

    local actual = assert(sequence.render(source))
    local expected = {
      " ┌───┐      ┌───┐",
      " │ A │      │ B │",
      " └─┬─┘      └─┬─┘",
      "   │          │",
      "   │  Hello   │",
      "   │──────────▶",
      "   │          │",
      "   │   Hi     │",
      "   ◀╌╌╌╌╌╌╌╌╌╌│",
      "   │          │",
      " ┌─┴─┐      ┌─┴─┐",
      " │ A │      │ B │",
      " └───┘      └───┘",
      "",
      "[unsupported: autonumber]",
      "[unsupported: activate B]",
      "[unsupported: deactivate B]",
    }

    assert.are.equal(testdata.normalize_whitespace(table.concat(expected, "\n")), testdata.normalize_whitespace(table.concat(actual, "\n")))
  end)
end)
