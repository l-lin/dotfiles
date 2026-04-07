local UrlParser = require("helpers.url_parser")

describe("UrlParser.new", function()
  local cases = {
    {
      name = "parses a valid http URL",
      url = "http://example.com:8080/foo/bar",
      expect = { protocol = "http", host = "example.com", port = 8080, path = "/foo/bar", err = nil }
    },
    {
      name = "parses a valid https URL with default port",
      url = "https://example.com/foo",
      expect = { protocol = "https", host = "example.com", port = 443, path = "/foo", err = nil }
    },
    {
      name = "parses a valid http URL with no port",
      url = "http://example.com/bar",
      expect = { protocol = "http", host = "example.com", port = 80, path = "/bar", err = nil }
    },
    {
      name = "throws error for invalid URL",
      url = "not_a_url",
      expect = { err = "Invalid URL format" }
    },
    {
      name = "throws error for empty string",
      url = "",
      expect = { err = "Invalid URL format" }
    },
  }

  for _, case in ipairs(cases) do
    it(case.name, function()
      if case.expect.err then
        local success, result = pcall(UrlParser.new, case.url)
        assert.is_false(success)
        assert.truthy(result:match("Invalid URL format"))
      else
        local success, parser = pcall(UrlParser.new, case.url)
        assert.is_true(success)
        assert.are.equal(case.expect.protocol, parser.protocol)
        assert.are.equal(case.expect.host, parser.host)
        assert.are.equal(case.expect.port, parser.port)
        assert.are.equal(case.expect.path, parser.path)
      end
    end)
  end
end)

describe("UrlParser:get_url_final_segment", function()
  local cases = {
    {
      name = "returns last segment for normal path",
      url = "http://host/a/b/c",
      expect = { seg = "c" }
    },
    {
      name = "returns last segment for path with trailing slash",
      url = "http://host/a/b/c/",
      expect = { seg = "c" }
    },
    {
      name = "returns nil for root path",
      url = "http://host/",
      expect = { seg = nil }
    },
    {
      name = "returns nil for empty path",
      url = "http://host",
      expect = { seg = nil }
    },
  }

  for _, case in ipairs(cases) do
    it(case.name, function()
      local parser = UrlParser.new(case.url)
      local seg = parser:get_url_final_segment()
      assert.are.equal(case.expect.seg, seg)
    end)
  end
end)

describe("UrlParser:is_youtube_url", function()
  local cases = {
    { name = "detects youtube.com/watch?v=", url = "https://youtube.com/watch?v=abc123", expect = true },
    { name = "detects youtu.be/", url = "https://youtu.be/abc123", expect = true },
    { name = "detects youtube.com with ?v= in path", url = "https://youtube.com/other/path?v=abc123", expect = true },
    { name = "returns false for non-youtube URL", url = "https://example.com/video?v=abc123", expect = false },
  }

  for _, case in ipairs(cases) do
    it(case.name, function()
      local parser = UrlParser.new(case.url)
      assert.are.equal(case.expect, parser:is_youtube_url())
    end)
  end
end)

describe("UrlParser:extract_youtube_video_id", function()
  local cases = {
    {
      name = "extracts video id from youtube.com/watch?v=",
      url = "https://youtube.com/watch?v=abc123",
      expect = { id = "abc123" }
    },
    {
      name = "extracts video id from youtu.be/",
      url = "https://youtu.be/xyz456",
      expect = { id = "xyz456" }
    },
    {
      name = "extracts video id from youtube.com with ?v= in path",
      url = "https://youtube.com/other/path?v=def789",
      expect = { id = "def789" }
    },
    {
      name = "returns nil for non-youtube URL",
      url = "https://example.com/video?v=abc123",
      expect = { id = nil }
    },
    {
      name = "returns nil for youtube URL with no video id",
      url = "https://youtube.com/watch?v=",
      expect = { id = nil }
    },
  }

  for _, case in ipairs(cases) do
    it(case.name, function()
      local parser = UrlParser.new(case.url)
      local id = parser:extract_youtube_video_id()
      assert.are.equal(case.expect.id, id)
    end)
  end
end)
