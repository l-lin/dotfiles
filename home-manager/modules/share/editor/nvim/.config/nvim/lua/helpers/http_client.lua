local DEFAULT_USER_AGENT =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

---@class dotfiles.helpers.HttpClientOptions
---@field user_agent? string optional User-Agent header to use for the request

---@class dotfiles.helpers.HttpResponse
---@field content string the response body content
---@field status_code string the HTTP status code of the response

---@class dotfiles.helpers.HttpClient
---@field options dotfiles.helpers.HttpClientOptions|nil optional configuration for the HTTP client
local HttpClient = {}

---Create a new HttpClient instance
---@param options dotfiles.helpers.HttpClientOptions|nil optional configuration for the HTTP client
function HttpClient.new(options)
  local self = setmetatable({}, { __index = HttpClient })
  self.options = options or {}
  return self
end

---Simple HTTP GET request using curl command
---@param url string the URL to fetch
---@return dotfiles.helpers.HttpResponse|nil response the response body or nil if an error occurred
function HttpClient:get(url)
  local user_agent = self.options.user_agent or DEFAULT_USER_AGENT

  local curl_cmd = string.format(
    'curl -s -L -A "%s" -w "\\nHTTP_STATUS:%%{http_code}" "%s"',
    user_agent,
    url:gsub('"', '\\"') -- escape quotes
  )

  local handle = io.popen(curl_cmd)
  if not handle then
    return nil
  end

  local response = handle:read("*a")
  local success = handle:close()

  if not success then
    return nil
  end

  local status_match = response:match("\nHTTP_STATUS:(%d+)")
  if status_match then
    return {
      status_code = tonumber(status_match),
      content = response:gsub("\nHTTP_STATUS:%d+", ""),
    }
  end

  return { status_code = 200, content = response }
end

return HttpClient

