local text = require("functions.lang.mermaid.text")

describe("mermaid.text trimming helpers", function()
  it("GIVEN surrounding mixed whitespace WHEN trimming THEN each helper removes only its intended side", function()
    local value = " \t\n hello world \r\n "

    assert.are.equal("hello world", text.trim(value))
    assert.are.equal("hello world \r\n ", text.ltrim(value))
    assert.are.equal(" \t\n hello world", text.rtrim(value))
  end)

  it("GIVEN whitespace-only input WHEN trimming THEN it returns an empty string", function()
    local value = " \t\r\n "

    assert.are.equal("", text.trim(value))
    assert.are.equal("", text.ltrim(value))
    assert.are.equal("", text.rtrim(value))
  end)
end)

describe("mermaid.text.split_lines", function()
  it(
    "GIVEN empty and newline-terminated strings WHEN splitting THEN it preserves logical blank lines including a trailing one",
    function()
      assert.are.same({ "" }, text.split_lines(""))
      assert.are.same({ "one", "", "two", "" }, text.split_lines("one\n\ntwo\n"))
      assert.are.same({ "one", "two" }, text.split_lines("one\ntwo"))
    end
  )
end)

describe("mermaid.text UTF-8 helpers", function()
  it(
    "GIVEN ASCII multibyte and NUL bytes WHEN enumerating characters THEN utf8 helpers treat each codepoint-sized chunk as one character",
    function()
      local value = "A你🙂\0B"
      local actual_chars = text.utf8_chars(value)

      assert.are.same({ "A", "你", "🙂", "\0", "B" }, actual_chars)
      assert.are.equal(5, text.char_len(value))
      assert.are.equal(text.UTF8_CHAR_PATTERN, "[%z\1-\127\194-\244][\128-\191]*")
    end
  )

  it("GIVEN an empty string WHEN counting characters THEN the result is zero", function()
    assert.are.same({}, text.utf8_chars(""))
    assert.are.equal(0, text.char_len(""))
  end)
end)

describe("mermaid.text.starts_with", function()
  it("GIVEN normal and empty prefixes WHEN checking starts_with THEN it follows Lua substring semantics", function()
    assert.is_true(text.starts_with("sequenceDiagram", "sequence"))
    assert.is_false(text.starts_with("sequenceDiagram", "diagram"))
    assert.is_true(text.starts_with("", ""))
    assert.is_true(text.starts_with("mermaid", ""))
  end)
end)

describe("mermaid.text line metrics", function()
  it(
    "GIVEN multiline Unicode text WHEN measuring THEN width uses UTF-8 characters and line count includes blank lines",
    function()
      local value = "宽\nabc🙂\n"

      assert.are.equal(4, text.max_line_width(value))
      assert.are.equal(3, text.line_count(value))
    end
  )

  it("GIVEN an empty string WHEN measuring line metrics THEN it behaves like one empty line", function()
    assert.are.equal(0, text.max_line_width(""))
    assert.are.equal(1, text.line_count(""))
  end)
end)

describe("mermaid.text.normalize_br_tags", function()
  it(
    "GIVEN quoted labels HTML-ish tags escaped newlines and markdown emphasis WHEN normalizing THEN it strips supported tags and rewrites formatting",
    function()
      local value =
        '"Hello<BR/>world\\n<sub>x</sub><SUP>2</SUP><small>tiny</small><Mark>hot</mark> **bold** *italic* ~~gone~~"'

      local actual = text.normalize_br_tags(value)
      local expected = "Hello\nworld\nx2tinyhot <b>bold</b> <i>italic</i> <s>gone</s>"

      assert.are.equal(expected, actual)
    end
  )

  it(
    "GIVEN unmatched quotes and mixed asterisks WHEN normalizing THEN it leaves unbalanced quoting intact while still converting balanced markdown spans",
    function()
      local value = '"*outer* and **inner** and ~~strike~~'

      local actual = text.normalize_br_tags(value)
      local expected = '"<i>outer</i> and <b>inner</b> and <s>strike</s>'

      assert.are.equal(expected, actual)
    end
  )
end)

describe("mermaid.text.slugify", function()
  it(
    "GIVEN spaces punctuation and underscores WHEN slugifying THEN it strips every non-alphanumeric byte after whitespace replacement and returns the final gsub replacement count",
    function()
      local actual, replacement_count = text.slugify("Hello,  mermaid-world!_ 42")

      assert.are.equal("Hellomermaidworld42", actual)
      assert.are.equal(6, replacement_count)
    end
  )

  it("GIVEN punctuation-only input WHEN slugifying THEN it can collapse to an empty slug", function()
    local actual = text.slugify("!!!")

    assert.are.equal("", actual)
  end)
end)
