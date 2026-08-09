dofile((debug.getinfo(1, "S").source:sub(2):match("^(.*)/[^/]+$")) .. "/spec_helper.lua")
if type(describe) ~= "function" then
  require("busted.runner")()
end

local mermaid = require("functions.lang.mermaid")
local testdata = require("functions.lang.mermaid.testdata")

describe("mermaid.build_marks", function()
  it("GIVEN an indented Mermaid block WHEN building marks THEN it keeps the source visible and places the Unicode preview below the closing fence", function()
    local markdown_lines = {
      "  ```mermaid",
      "  graph LR",
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
              { "  ┌───┐     ┌───┐", "Normal" },
            },
            {
              { "  │   │     │   │", "Normal" },
            },
            {
              { "  │ A ├────►│ B │", "Normal" },
            },
            {
              { "  │   │     │   │", "Normal" },
            },
            {
              { "  └───┘     └───┘", "Normal" },
            },
          },
          virt_lines_above = true,
        },
      },
    }

    assert.are.same(expected, actual)
  end)

  it("GIVEN partially supported syntax WHEN building marks THEN it appends raw unsupported lines below the preview", function()
    local markdown_lines = {
      "```mermaid",
      "sequenceDiagram",
      "participant A",
      "participant B",
      "autonumber",
      "A->>B: Hello",
      "```",
    }

    local actual = mermaid.build_marks(markdown_lines)
    local expected = {
      {
        conceal = false,
        start_row = 6,
        start_col = 0,
        opts = {
          virt_lines = {
            {
              { " ┌───┐      ┌───┐", "Normal" },
            },
            {
              { " │ A │      │ B │", "Normal" },
            },
            {
              { " └─┬─┘      └─┬─┘", "Normal" },
            },
            {
              { "   │          │", "Normal" },
            },
            {
              { "   │  Hello   │", "Normal" },
            },
            {
              { "   │──────────▶", "Normal" },
            },
            {
              { "   │          │", "Normal" },
            },
            {
              { " ┌─┴─┐      ┌─┴─┐", "Normal" },
            },
            {
              { " │ A │      │ B │", "Normal" },
            },
            {
              { " └───┘      └───┘", "Normal" },
            },
            {
              { "", "Normal" },
            },
            {
              { "[unsupported: autonumber]", "Normal" },
            },
          },
        },
      },
    }

    assert.are.same(expected, actual)
  end)
end)

describe("mermaid.render", function()
  it("GIVEN an unsupported diagram family WHEN rendering THEN it falls back to raw source", function()
    local source = table.concat({
      "classDiagram",
      "  Animal <|-- Duck",
    }, "\n")

    local actual, reason = mermaid.render(source)

    assert.are.equal(nil, actual)
    assert.is_truthy(reason:match("unsupported"))
  end)
end)
