dofile((debug.getinfo(1, "S").source:sub(2):match("^(.*)/[^/]+$")) .. "/spec_helper.lua")
if type(describe) ~= "function" then
  require("busted.runner")()
end

local mermaid = require("functions.lang.mermaid")

describe("mermaid.build_marks", function()
  it("GIVEN an indented mermaid block WHEN building marks THEN it leaves source visible and adds preview below the closing fence", function()
    local markdown_lines = {
      "  ```mermaid",
      "  flowchart TD",
      "  A --> B",
      "  ```",
      "  after",
    }

    local actual = mermaid.build_marks(markdown_lines)
    local expected = {
      {
        conceal = false,
        start_row = 4,
        start_col = 0,
        opts = {
          virt_lines = {
            {
              { "  [A]", "Normal" },
            },
            {
              { "  `- [B]", "Normal" },
            },
          },
          virt_lines_above = true,
        },
      },
    }

    assert.are.same(expected, actual)
  end)

  it("GIVEN partially supported flowchart syntax WHEN building marks THEN it appends an unsupported-syntax note below the preview", function()
    local markdown_lines = {
      "```mermaid",
      "flowchart TD",
      "A --> B",
      "click A callback",
      "B --> C",
      "```",
    }

    local actual = mermaid.build_marks(markdown_lines)
    local expected = {
      {
        conceal = false,
        start_row = 5,
        start_col = 0,
        opts = {
          virt_lines = {
            {
              { "[A]", "Normal" },
            },
            {
              { "`- [B]", "Normal" },
            },
            {
              { "   `- [C]", "Normal" },
            },
            {
              { "", "Normal" },
            },
            {
              { "[unsupported: click A callback]", "Normal" },
            },
          },
        },
      },
    }

    assert.are.same(expected, actual)
  end)
end)

describe("mermaid.render", function()
  it("GIVEN an unsupported diagram kind WHEN rendering THEN it falls back to raw source", function()
    local source = table.concat({
      "classDiagram",
      "    Animal <|-- Duck",
    }, "\n")

    local actual, reason = mermaid.render(source)

    assert.are.equal(nil, actual)
    assert.is_truthy(reason:match("unsupported"))
  end)
end)
