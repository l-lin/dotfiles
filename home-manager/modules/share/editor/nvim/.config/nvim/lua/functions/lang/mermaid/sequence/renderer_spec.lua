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
    "sequence_activation_alt",
    "sequence_activation_self_nested",
    "sequence_activation_mixed",
  }

  for _, fixture_name in ipairs(upstream_fixtures) do
    it(
      string.format("GIVEN upstream fixture `%s` WHEN rendering THEN output matches the Unicode snapshot", fixture_name),
      function()
        then_rendered_output_matches_fixture(fixture_name)
      end
    )
  end

  it(
    "GIVEN activation syntax WHEN rendering THEN supported activation lines stop warning while unrelated unsupported lines remain",
    function()
      local source = table.concat({
        "sequenceDiagram",
        "  participant A",
        "  participant B",
        "  autonumber",
        "  A->>+B: Hello",
        "  activate B",
        "  B-->>-A: Hi",
        "  deactivate B",
      }, "\n")

      local actual = assert(sequence.render(source))
      local normalized = testdata.normalize_whitespace(table.concat(actual, "\n"))

      assert.is_truthy(normalized:find("%[unsupported: autonumber%]", 1, false))
      assert.is_nil(normalized:find("activate B", 1, true))
      assert.is_nil(normalized:find("deactivate B", 1, true))
    end
  )
end)
