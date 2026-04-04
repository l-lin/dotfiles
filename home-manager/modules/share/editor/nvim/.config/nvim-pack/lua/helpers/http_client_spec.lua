local HttpClient = require("helpers.http_client")

describe("HttpClient.new", function()
  local cases = {
    {
      name = "creates HttpClient with no options",
      options = nil,
      expect = { has_options = false, user_agent = nil },
    },
    {
      name = "creates HttpClient with empty options",
      options = {},
      expect = { has_options = true, user_agent = nil },
    },
    {
      name = "creates HttpClient with custom user agent",
      options = { user_agent = "custom-agent/1.0" },
      expect = { has_options = true, user_agent = "custom-agent/1.0" },
    },
  }

  for _, case in ipairs(cases) do
    it(case.name, function()
      local client = HttpClient.new(case.options)
      assert.is_not_nil(client)
      assert.is_not_nil(client.options)
      if case.expect.user_agent then
        assert.are.equal(case.expect.user_agent, client.options.user_agent)
      end
    end)
  end
end)

describe("HttpClient:get", function()
  local function mock_io_popen(response_content, status_code, should_fail)
    local original_io_popen = io.popen
    local mock_handle = {
      read = function(self, mode)
        if should_fail then
          return nil
        end
        if status_code then
          return response_content .. "\nHTTP_STATUS:" .. status_code
        else
          return response_content
        end
      end,
      close = function(self)
        return not should_fail
      end,
    }

    io.popen = function(cmd)
      if should_fail then
        return nil
      end
      return mock_handle
    end

    return function()
      io.popen = original_io_popen
    end
  end

  it("returns nil when io.popen fails", function()
    local restore = mock_io_popen("", nil, true)
    local client = HttpClient.new()
    local result = client:get("http://example.com")
    assert.is_nil(result)
    restore()
  end)

  it("returns nil when handle:close() fails", function()
    local original_io_popen = io.popen
    local mock_handle = {
      read = function()
        return "content"
      end,
      close = function()
        return false
      end,
    }
    io.popen = function()
      return mock_handle
    end

    local client = HttpClient.new()
    local result = client:get("http://example.com")
    assert.is_nil(result)

    io.popen = original_io_popen
  end)

  it("returns response with status code when present", function()
    local restore = mock_io_popen("test content", "200", false)
    local client = HttpClient.new()
    local result = client:get("http://example.com")

    assert.is_not_nil(result)
    assert.are.equal(200, result.status_code)
    assert.are.equal("test content", result.content)
    restore()
  end)

  it("returns response with default 200 status when status not found", function()
    local restore = mock_io_popen("test content", nil, false)
    local client = HttpClient.new()
    local result = client:get("http://example.com")

    assert.is_not_nil(result)
    assert.are.equal(200, result.status_code)
    assert.are.equal("test content", result.content)
    restore()
  end)

  it("handles different status codes correctly", function()
    local test_cases = {
      { status = "404", content = "Not Found" },
      { status = "500", content = "Server Error" },
      { status = "301", content = "Moved" },
    }

    for _, case in ipairs(test_cases) do
      local restore = mock_io_popen(case.content, case.status, false)
      local client = HttpClient.new()
      local result = client:get("http://example.com")

      assert.is_not_nil(result)
      assert.are.equal(tonumber(case.status), result.status_code)
      assert.are.equal(case.content, result.content)
      restore()
    end
  end)

  it("uses custom user agent when provided", function()
    local captured_cmd = nil
    local original_io_popen = io.popen
    io.popen = function(cmd)
      captured_cmd = cmd
      return {
        read = function()
          return "content\nHTTP_STATUS:200"
        end,
        close = function()
          return true
        end,
      }
    end

    local client = HttpClient.new({ user_agent = "test-agent/1.0" })
    client:get("http://example.com")

    assert.truthy(captured_cmd:match('%-A "test%-agent/1%.0"'))
    io.popen = original_io_popen
  end)

  it("uses default user agent when none provided", function()
    local captured_cmd = nil
    local original_io_popen = io.popen
    io.popen = function(cmd)
      captured_cmd = cmd
      return {
        read = function()
          return "content\nHTTP_STATUS:200"
        end,
        close = function()
          return true
        end,
      }
    end

    local client = HttpClient.new()
    client:get("http://example.com")

    assert.truthy(captured_cmd:match("Mozilla/5%.0"))
    io.popen = original_io_popen
  end)

  it("escapes quotes in URL", function()
    local captured_cmd = nil
    local original_io_popen = io.popen
    io.popen = function(cmd)
      captured_cmd = cmd
      return {
        read = function()
          return "content\nHTTP_STATUS:200"
        end,
        close = function()
          return true
        end,
      }
    end

    local client = HttpClient.new()
    client:get('http://example.com/path?q="test"')

    assert.truthy(captured_cmd:match('http://example%.com/path%?q=\\"test\\"'))
    io.popen = original_io_popen
  end)
end)

