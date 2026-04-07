local markdown_link_parser = require("helpers.markdown_link_parser")

describe("markdown_link_parser.extract_url_at_cursor", function()
  local cases = {
    {
      name = "cursor on opening bracket",
      line = "[foo](https://example.org)",
      col = 1,
      expect = "https://example.org",
    },
    {
      name = "cursor on link text",
      line = "[foo](https://example.org)",
      col = 3,
      expect = "https://example.org",
    },
    {
      name = "cursor on closing bracket",
      line = "[foo](https://example.org)",
      col = 5,
      expect = "https://example.org",
    },
    {
      name = "cursor on opening paren",
      line = "[foo](https://example.org)",
      col = 6,
      expect = "https://example.org",
    },
    {
      name = "cursor on URL",
      line = "[foo](https://example.org)",
      col = 15,
      expect = "https://example.org",
    },
    {
      name = "cursor on closing paren",
      line = "[foo](https://example.org)",
      col = 26,
      expect = "https://example.org",
    },
    {
      name = "cursor after link",
      line = "[foo](https://example.org) text",
      col = 28,
      expect = nil,
    },
    {
      name = "cursor before link",
      line = "text [foo](https://example.org)",
      col = 3,
      expect = nil,
    },
    {
      name = "multiple links, cursor on first",
      line = "[first](https://one.com) [second](https://two.com)",
      col = 10,
      expect = "https://one.com",
    },
    {
      name = "multiple links, cursor on second",
      line = "[first](https://one.com) [second](https://two.com)",
      col = 30,
      expect = "https://two.com",
    },
    {
      name = "no markdown link",
      line = "just plain text",
      col = 5,
      expect = nil,
    },
    {
      name = "incomplete markdown link",
      line = "[foo](incomplete",
      col = 3,
      expect = nil,
    },
  }

  for _, case in ipairs(cases) do
    it(case.name, function()
      local actual = markdown_link_parser.extract_url_at_cursor(case.line, case.col)
      assert.are.equal(case.expect, actual)
    end)
  end
end)
