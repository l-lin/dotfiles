if type(describe) ~= "function" then
  local spec_path = debug.getinfo(1, "S").source:sub(2)
  local lua_root = spec_path:match("^(.*)/functions/")
  local busted_lua_root = "/opt/homebrew/opt/busted/libexec/share/lua/5.5"
  local busted_c_root = "/opt/homebrew/opt/busted/libexec/lib/lua/5.5"

  package.path = table.concat({
    lua_root .. "/?.lua",
    lua_root .. "/?/init.lua",
    busted_lua_root .. "/?.lua",
    busted_lua_root .. "/?/init.lua",
    package.path,
  }, ";")
  package.cpath = busted_c_root .. "/?.so;" .. package.cpath
  require("busted.runner")()
end

local link_to_markdown = require("functions.lang.obsidian.link_to_markdown")

describe("paste URL as Markdown", function()
  local url = "https://example.com/articles/sample"
  local original_vim
  local original_getreg
  local original_http_client
  local original_insert_text
  local actual

  before_each(function()
    original_vim = _G.vim
    _G.vim = _G.vim or { fn = { nr2char = utf8.char } }
    original_getreg = vim.fn.getreg
    original_http_client = package.loaded["functions.http_client"]
    original_insert_text = package.loaded["functions.insert_text"]
    actual = nil
    vim.fn.getreg = function()
      return url
    end
    package.loaded["functions.insert_text"] = {
      at_current_cursor = function(text)
        actual = text
      end,
    }
  end)

  after_each(function()
    vim.fn.getreg = original_getreg
    package.loaded["functions.http_client"] = original_http_client
    package.loaded["functions.insert_text"] = original_insert_text
    _G.vim = original_vim
  end)

  local function given_title(title)
    package.loaded["functions.http_client"] = {
      new = function()
        return {
          get = function()
            return { status_code = 200, content = "<title>" .. title .. "</title>" }
          end,
        }
      end,
    }
  end

  local cases = {
    {
      name = "decimal en dash in a page title",
      title = "Sample Article &#8211; Example Site",
      expected = "Sample Article – Example Site",
    },
    {
      name = "numeric typographic punctuation",
      title = "&#8220;Sample&#8221; &#x2013; Article&#8230;",
      expected = "“Sample” – Article…",
    },
    {
      name = "hexadecimal apostrophe in a page title",
      title = "It&#x27;s a sample article | Example",
      expected = "It's a sample article | Example",
    },
    { name = "decimal apostrophe", title = "It&#39;s done", expected = "It's done" },
    { name = "uppercase hexadecimal prefix", title = "It&#X27;s done", expected = "It's done" },
    { name = "Unicode numeric entities", title = "&#233; &#x1F600;", expected = "é 😀" },
    {
      name = "common named entities",
      title = "&quot;Tom&apos;s&quot; &amp; Jerry&nbsp;&lt;3&gt;",
      expected = '"Tom\'s" & Jerry \\<3\\>',
    },
    { name = "single-pass decoding", title = "&amp;#x27; &amp;quot;", expected = "&#x27; &quot;" },
    { name = "Markdown escaping after decoding", title = "&#91;A&#93; &#42;B&#42;", expected = "\\[A\\] \\*B\\*" },
    {
      name = "unknown and invalid entities remain unchanged",
      title = "&unknown; &#xZZ; &#0; &#xD800; &#x110000;",
      expected = "&unknown; &#xZZ; &#0; &#xD800; &#x110000;",
    },
    { name = "existing title whitespace cleanup", title = " \n Plain title\r\n ", expected = "Plain title" },
  }

  for _, case in ipairs(cases) do
    it("GIVEN " .. case.name .. " WHEN pasted THEN inserts the decoded Markdown link", function()
      given_title(case.title)
      link_to_markdown.paste_url()
      local expected = string.format("[%s](%s)", case.expected, url)
      assert.are.equal(expected, actual)
    end)
  end
end)
