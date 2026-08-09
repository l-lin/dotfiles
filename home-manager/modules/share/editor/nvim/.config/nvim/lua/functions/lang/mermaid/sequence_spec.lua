dofile((debug.getinfo(1, "S").source:sub(2):match("^(.*)/[^/]+$")) .. "/spec_helper.lua")
if type(describe) ~= "function" then
  require("busted.runner")()
end

local sequence = require("functions.lang.mermaid.sequence")

describe("mermaid.sequence.render", function()
  local function then_actual_contains_line(actual, expected_line)
    for _, line in ipairs(actual) do
      if line == expected_line then
        return
      end
    end
    error("missing expected line: " .. expected_line)
  end

  it("GIVEN a simple sequence WHEN rendering THEN it keeps the preview diagram-like", function()
    local source = table.concat({
      "sequenceDiagram",
      "    participant John",
      "    participant Alice",
      "    John -->> Alice: Hi Alice, I can hear you!",
      "    John -->> Alice: I feel great!",
    }, "\n")

    local actual = sequence.render(source)
    local expected = {
      "+------+     +-------+",
      "| John |     | Alice |",
      "+--+---+     +---+---+",
      "   |             |",
      "   | Hi Alice, I can hear you!",
      "   +............>|",
      "   |             |",
      "   | I feel great!",
      "   +............>|",
      "   |             |",
    }

    assert.are.same(expected, actual)
  end)

  it("GIVEN a checkout sequence with aliases and activations WHEN rendering THEN it shows numbered messages, fragment labels, and activation lanes", function()
    local source = table.concat({
      "sequenceDiagram",
      "    autonumber",
      "    actor Customer",
      "    participant Shop as Web Shop",
      "    participant Pay as Payment Service",
      "    participant Bank",
      "",
      "    Customer->>Shop: Place order",
      "    activate Shop",
      "    Shop->>Pay: Create payment request",
      "    activate Pay",
      "    Pay->>Bank: Authorize card",
      "    Bank-->>Pay: Authorization result",
      "    alt Payment approved",
      "        Pay-->>Shop: Payment confirmed",
      "        Shop-->>Customer: Show receipt",
      "    else Payment declined",
      "        Pay-->>Shop: Payment failed",
      "        Shop-->>Customer: Ask for another card",
      "    end",
      "    deactivate Pay",
      "    deactivate Shop",
    }, "\n")

    local actual = sequence.render(source)

    then_actual_contains_line(actual, "+----------+     +----------+     +-----------------+     +------+")
    then_actual_contains_line(actual, "| Customer |     | Web Shop |     | Payment Service |     | Bank |")
    then_actual_contains_line(actual, "[alt] Payment approved")
    then_actual_contains_line(actual, "[else] Payment declined")
    then_actual_contains_line(actual, "     |                !                    !                 |")
    assert.is_nil(table.concat(actual, "\n"):match("%[unsupported:"))
  end)
end)
