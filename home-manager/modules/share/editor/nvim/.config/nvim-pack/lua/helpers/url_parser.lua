---Check if the input is a valid URL
---@param input_url string the URL to check
---@return boolean true if the input is a valid URL, false otherwise
local function is_valid_url(input_url)
  return input_url and input_url:match("^https?://[%w%.%-]+") ~= nil
end

---Parse URL into components
---@param input_url string the URL to parse
---@return table parsed_url a table with protocol, host, port, and path or nil if parsing fails
local function parse_url(input_url)
  local protocol, host, port, path = input_url:match("^(https?)://([^:/]+):?(%d*)(.*)$")

  port = port ~= "" and tonumber(port) or (protocol == "https" and 443 or 80)
  path = path ~= "" and path or "/"

  return {
    protocol = protocol,
    host = host,
    port = port,
    path = path,
  }
end

---@class dotfiles.helpers.UrlParser
---@field input_url string the URL to parse
---@field protocol? string the protocol of the URL (http or https)
---@field host? string the host of the URL
---@field port? number the port of the URL
---@field path? string the path of the URL
local UrlParser = {}

---Create a new UrlParser instance
---@param input_url string the URL to parse
---@return dotfiles.helpers.UrlParser url_parser a new UrlParser instance
function UrlParser.new(input_url)
  local self = setmetatable({}, { __index = UrlParser })
  self.input_url = input_url or ""

  if not is_valid_url(input_url) then
    error("Invalid URL format: " .. tostring(input_url))
  end

  local parsed_url = parse_url(input_url)
  self.protocol = parsed_url.protocol
  self.host = parsed_url.host
  self.port = parsed_url.port
  self.path = parsed_url.path
  return self
end

---Extract the final segment from a URL path (for non-HTML content)
---@return string|nil final_segment the final segment of the URL path or nil if not found
function UrlParser:get_url_final_segment()
  local segments = {}
  for segment in self.path:gmatch("[^/]+") do
    table.insert(segments, segment)
  end

  if #segments == 0 then
    return nil
  end
  return segments[#segments]
end

---Check if the URL is a YouTube video
---@return boolean true if the URL is a YouTube video, false otherwise
function UrlParser:is_youtube_url()
  return self.input_url
    and (
        self.input_url:match("^https?://[%w%.]*youtube%.com/watch%?v=")
        or self.input_url:match("^https?://[%w%.]*youtu%.be/")
        or self.input_url:match("^https?://[%w%.]*youtube%.com/.*[%?&]v=")
      )
      ~= nil
end

---Extract video ID from YouTube URL
---@return string|nil video_id the extracted video ID or nil if not found
function UrlParser:extract_youtube_video_id()
  if not self:is_youtube_url() then
    return nil
  end

  local video_id = self.input_url:match("youtube%.com/watch%?v=([%w%-_]+)")
  if video_id then
    return video_id
  end

  video_id = self.input_url:match("youtu%.be/([%w%-_]+)")
  if video_id then
    return video_id
  end

  video_id = self.input_url:match("youtube%.com/.*[%?&]v=([%w%-_]+)")
  if video_id then
    return video_id
  end

  return nil
end

return UrlParser
