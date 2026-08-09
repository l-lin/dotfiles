dofile((debug.getinfo(1, "S").source:sub(2):match("^(.*)/[^/]+$")) .. "/spec_helper.lua")
if type(describe) ~= "function" then
  require("busted.runner")()
end

local state = require("functions.lang.mermaid.state")

describe("mermaid.state.render", function()
  it("GIVEN a simple state machine WHEN rendering THEN it keeps repeated transitions readable", function()
    local source = table.concat({
      "stateDiagram-v2",
      "    [*] --> Still",
      "    Still --> [*]",
      "    Still --> Moving",
      "    Moving --> Still",
      "    Moving --> Crash",
      "    Crash --> [*]",
    }, "\n")

    local actual = state.render(source)
    local expected = {
      "(*)",
      "`- [Still]",
      "   |- (*)",
      "   `- [Moving]",
      "      `- [Crash]",
      "         `- (*)",
      "",
      "[extra]",
      "[Moving] -> [Still]",
    }

    assert.are.same(expected, actual)
  end)

  it("GIVEN the checkout state diagram WHEN rendering THEN it honors direction, keeps the nested state, and shows the note", function()
    local source = table.concat({
      "stateDiagram-v2",
      "    direction LR",
      "    [*] --> Placed",
      "    Placed --> Paid : payment received",
      "    Placed --> Cancelled : customer cancels",
      "    Paid --> Fulfilment",
      "",
      "    state Fulfilment {",
      "        [*] --> Packing",
      "        Packing --> Shipped : handed to courier",
      "        Shipped --> [*]",
      "    }",
      "",
      "    Fulfilment --> Delivered : courier confirms",
      "    Delivered --> [*]",
      "    Cancelled --> [*]",
      "",
      "    note right of Paid",
      "        Payment can be card,",
      "        wallet, or bank transfer",
      "    end note",
    }, "\n")

    local actual = state.render(source)
    local expected = {
      "[Fulfilment]",
      "  (*) -> [Packing] -handed to courier-> [Shipped] -> (*)",
      "",
      "(*) -> [Placed]",
      "           |- payment received -> [Paid] -> [Fulfilment] -courier confirms-> [Delivered] -> (*)",
      "           `- customer cancels -> [Cancelled] -> (*)",
      "",
      "[note right of Paid]",
      "  Payment can be card,",
      "  wallet, or bank transfer",
    }

    assert.are.same(expected, actual)
  end)
end)
