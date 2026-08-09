dofile((debug.getinfo(1, "S").source:sub(2):match("^(.*)/[^/]+$")) .. "/spec_helper.lua")
if type(describe) ~= "function" then
  require("busted.runner")()
end

local flowchart = require("functions.lang.mermaid.flowchart")

describe("mermaid.flowchart.render", function()
  it("GIVEN the README flowchart WHEN rendering THEN it returns a readable branch layout", function()
    local source = table.concat({
      "flowchart TD",
      "    A[Christmas] -->|Get money| B(Go shopping)",
      "    B --> C{Let me think}",
      "    C -->|One| D[Laptop]",
      "    C -->|Two| E[iPhone]",
      "    C -->|Three| F[fa:fa-car Car]",
    }, "\n")

    local actual = flowchart.render(source)
    local expected = {
      "[Christmas]",
      "`- Get money -> (Go shopping)",
      "   `- {Let me think}",
      "      |- One -> [Laptop]",
      "      |- Two -> [iPhone]",
      "      `- Three -> [fa:fa-car Car]",
    }

    assert.are.same(expected, actual)
  end)

  it("GIVEN partially supported flowchart syntax WHEN rendering THEN it keeps the readable graph and appends an unsupported note", function()
    local source = table.concat({
      "flowchart TD",
      "    A --> B",
      "    click A callback",
      "    B --> C",
    }, "\n")

    local actual = flowchart.render(source)
    local expected = {
      "[A]",
      "`- [B]",
      "   `- [C]",
      "",
      "[unsupported: click A callback]",
    }

    assert.are.same(expected, actual)
  end)
end)
