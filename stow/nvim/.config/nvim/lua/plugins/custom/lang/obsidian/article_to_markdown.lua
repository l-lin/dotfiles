local USER_AGENT =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

---Check if the input is a valid URL
---@param input_url string the URL to check
---@return boolean true if the input is a valid URL, false otherwise
local function is_valid_url(input_url)
  return input_url and input_url:match("^https?://[%w%.%-]+") ~= nil
end

---Check if the URL is a YouTube video
---@param url string the URL to check
---@return boolean true if the URL is a YouTube video, false otherwise
local function is_youtube_url(url)
  return url
    and (
        url:match("^https?://[%w%.]*youtube%.com/watch%?v=")
        or url:match("^https?://[%w%.]*youtu%.be/")
        or url:match("^https?://[%w%.]*youtube%.com/.*[%?&]v=")
      )
      ~= nil
end

---Extract video ID from YouTube URL
---@param url string the YouTube URL
---@return string|nil video_id the extracted video ID or nil if not found
local function extract_youtube_video_id(url)
  if not url then
    return nil
  end

  -- Handle youtube.com/watch?v=VIDEO_ID
  local video_id = url:match("youtube%.com/watch%?v=([%w%-_]+)")
  if video_id then
    return video_id
  end

  -- Handle youtu.be/VIDEO_ID
  video_id = url:match("youtu%.be/([%w%-_]+)")
  if video_id then
    return video_id
  end

  -- Handle other youtube.com formats with v= parameter
  video_id = url:match("youtube%.com/.*[%?&]v=([%w%-_]+)")
  if video_id then
    return video_id
  end

  return nil
end

---HTML to Markdown conversion rules
---@param html_content string the HTML content to convert
---@return string the converted Markdown content
local function html_to_markdown(html_content)
  local markdown = html_content

  -- Convert headers
  markdown = markdown:gsub("<h([1-6]).->(.-)</h[1-6]>", function(level, text)
    return string.rep("#", tonumber(level) or 1) .. " " .. text .. "\n\n"
  end)

  -- Convert div elements that likely represent paragraphs or sections
  markdown = markdown:gsub("<div[^>]*>(.-)</div>", "%1\n\n")

  -- Convert paragraphs - ensure proper spacing
  markdown = markdown:gsub("<p[^>]*>(.-)</p>", "%1\n\n")

  -- Convert emphasis
  markdown = markdown:gsub("<em.->(.-)</em>", "*%1*")
  markdown = markdown:gsub("<i.->(.-)</i>", "*%1*")
  markdown = markdown:gsub("<strong.->(.-)</strong>", "**%1**")
  markdown = markdown:gsub("<b.->(.-)</b>", "**%1**")

  -- Convert links
  markdown = markdown:gsub('<a%s+href="(.-)".->(.-)</a>', "[%2](%1)")

  -- Convert images
  markdown = markdown:gsub('<img%s+src="(.-)".-alt="(.-)".-/?>', "![%2](%1)")
  markdown = markdown:gsub('<img%s+src="(.-)".-/?>', "![Image](%1)")

  -- Convert code blocks
  markdown = markdown:gsub("<pre><code.->(.-)</code></pre>", "```\n%1\n```\n")
  markdown = markdown:gsub("<code.->(.-)</code>", "`%1`")

  -- Convert lists
  markdown = markdown:gsub("<ul.->(.-)</ul>", function(content)
    return content:gsub("<li.->(.-)</li>", "- %1\n")
  end)

  markdown = markdown:gsub("<ol.->(.-)</ol>", function(content)
    local counter = 1
    return content:gsub("<li.->(.-)</li>", function(item)
      local result = counter .. ". " .. item .. "\n"
      counter = counter + 1
      return result
    end)
  end)

  -- Convert blockquotes
  markdown = markdown:gsub("<blockquote.->(.-)</blockquote>", function(content)
    return content:gsub("([^\n]+)", "> %1") .. "\n\n"
  end)

  -- Convert line breaks - add proper spacing
  markdown = markdown:gsub("<br[^>]*/?>\n?", "\n")
  markdown = markdown:gsub("<br[^>]*/?>[%s]*", "\n")

  -- Remove remaining HTML tags
  markdown = markdown:gsub("<[^>]+>", "")

  -- Clean up whitespace but preserve paragraph structure
  -- Replace multiple spaces with single space
  markdown = markdown:gsub("[ \t]+", " ")
  -- Limit to max 2 consecutive newlines (preserve paragraph breaks)
  markdown = markdown:gsub("\n\n\n+", "\n\n")
  -- Remove leading/trailing whitespace
  markdown = markdown:gsub("^%s+", "")
  markdown = markdown:gsub("%s+$", "")

  return markdown
end

---Native HTTP fetch using curl command (most systems have curl)
---@param url string the URL to fetch
---@return string|nil, string|nil, string|nil html_content the content of the HTML
local function fetch_html(url)
  -- Use curl command for HTTP requests
  local curl_cmd = string.format(
    'curl -s -L -A "%s" -w "\\nHTTP_STATUS:%%{http_code}" "%s"',
    USER_AGENT,
    url:gsub('"', '\\"') -- escape quotes
  )

  local handle = io.popen(curl_cmd)
  if not handle then
    return nil, "Failed to execute HTTP request"
  end

  local response = handle:read("*a")
  local success = handle:close()

  if not success or not response then
    return nil, "Failed to fetch URL"
  end

  -- Parse response - be more flexible with parsing
  local content, status_code

  -- Try to extract status and content type from response
  local status_match = response:match("\nHTTP_STATUS:(%d+)")

  if status_match then
    status_code = status_match
    content = response:gsub("\nHTTP_STATUS:%d+", "")
  else
    content = response
    status_code = "200"
  end

  if status_code ~= "200" then
    return nil, "HTTP error: " .. status_code
  end

  return content, nil
end

---Native HTML parser - extract content between balanced tags
---@param html string the HTML content to parse
---@param tag_name string the name of the tag to extract content from
---@param attributes table|nil optional attributes to match (e.g., { class = "content" })
---@return string|nil content the extracted content or nil if not found
local function extract_tag_content(html, tag_name, attributes)
  local patterns = {}

  if attributes then
    for attr, value in pairs(attributes) do
      table.insert(
        patterns,
        string.format("<%s[^>]*%s=[\"']?[^\"']*%s[^\"']*[\"']?[^>]*>(.-)</%s>", tag_name, attr, value, tag_name)
      )
    end
  else
    table.insert(patterns, string.format("<%s[^>]*>(.-)</%s>", tag_name, tag_name))
  end

  for _, pattern in ipairs(patterns) do
    local content = html:match(pattern)
    if content then
      return content
    end
  end

  return nil
end

---Extract content from multiple possible containers
---@param html_content string the HTML content to extract from
---@return string|nil content the extracted readable content or nil if not found
local function extract_readable_content(html_content)
  -- Try different content containers in order of preference
  local content_strategies = {
    { tag = "article" },
    { tag = "main" },
    { tag = "div", attrs = { class = "content" } },
    { tag = "div", attrs = { class = "post" } },
    { tag = "div", attrs = { class = "entry" } },
    { tag = "div", attrs = { class = "article" } },
    { tag = "div", attrs = { id = "content" } },
    { tag = "div", attrs = { id = "main" } },
    { tag = "div", attrs = { id = "post" } },
    { tag = "div", attrs = { id = "article" } },
    { tag = "section" },
    { tag = "body" },
  }

  for _, strategy in ipairs(content_strategies) do
    local content = extract_tag_content(html_content, strategy.tag, strategy.attrs)
    if content and content:len() > 100 then -- Ensure meaningful content
      return content
    end
  end

  -- Ultimate fallback - return everything between body tags or entire content
  return html_content:match("<body[^>]*>(.-)</body>") or html_content
end

-- Clean and normalize text content
local function clean_text(text)
  if not text then
    return ""
  end

  -- Replace multiple spaces and tabs with single space (but preserve newlines)
  text = text:gsub("[ \t]+", " ")
  -- Remove leading/trailing whitespace from each line
  text = text:gsub("^%s+", "")
  text = text:gsub("%s+$", "")

  -- Decode common HTML entities
  local entities = {
    ["&amp;"] = "&",
    ["&lt;"] = "<",
    ["&gt;"] = ">",
    ["&quot;"] = '"',
    ["&#39;"] = "'",
    ["&nbsp;"] = " ",
  }

  for entity, replacement in pairs(entities) do
    text = text:gsub(entity, replacement)
  end

  return text
end

---Extract metadata from HTML using native pattern matching
---@param html_content string the HTML content to extract metadata from
---@return table metadata a table containing extracted metadata
local function extract_metadata(html_content)
  local metadata = {}
  metadata.title = html_content:match("<title[^>]*>%s*(.-)%s*</title>") or "Untitled"
  metadata.title = clean_text(metadata.title)
  return metadata
end

---Main parsing function
---@param url string the URL to parse
---@return table|nil, string|nil table containing parsed data or nil if parsing fails
local function parse_url(url)
  if not is_valid_url(url) then
    return nil, "Invalid URL format"
  end

  local html_content, error_msg = fetch_html(url)
  if not html_content then
    return nil, error_msg
  end

  local metadata = extract_metadata(html_content)
  local result = {
    url = url,
    title = metadata.title,
    current_date = os.date("%Y-%m-%d"),
  }

  -- Handle YouTube videos differently
  if is_youtube_url(url) then
    local video_id = extract_youtube_video_id(url)
    if not video_id then
      return nil, "Could not extract YouTube video ID"
    end

    result.is_youtube = true
    result.video_id = video_id
    result.content = "" -- No content needed for YouTube videos
  else
    local readable_content = extract_readable_content(html_content)
    if not readable_content then
      return nil, "Could not extract readable content"
    end

    local markdown_content = html_to_markdown(readable_content)
    markdown_content = clean_text(markdown_content)

    result.content = markdown_content
    result.is_youtube = false
  end

  return result
end

---Template rendering function (simplified)
---@param template string the template string with placeholders
---@param data table a table containing data to fill in the template
---@return string the rendered template
local function render_template(template, data)
  if not template or not data then
    return template or ""
  end

  local result = template

  result = result:gsub("{{%s*([%w_]+)%s*}}", function(var)
    local value = data[var]
    if value ~= nil then
      return tostring(value)
    else
      return "{{" .. var .. "}}" -- Keep original if not found
    end
  end)

  result = result:gsub("%%([%w_]+)%%", function(var)
    local value = data[var]
    if value ~= nil then
      return tostring(value)
    else
      return "%" .. var .. "%" -- Keep original if not found
    end
  end)

  return result
end

---Generate markdown note from parsed data
---@param parsed_data table the parsed data containing metadata and content
---@param template string|nil optional template string to use for rendering
---@return string the generated markdown note
local function convert_to_markdown_format(parsed_data, template)
  if not template then
    if parsed_data.is_youtube then
      template = [=[
---
date: {{current_date}}
tags:
  - article/video
  - to-review
---
# {{title}}

> [!quote] src: [{{title}}]({{url}}) - [[{{current_date}}]]
> <iframe frameborder="0" allowfullscreen src="https://youtube.com/embed/{{video_id}}?autoplay=0" width="100%" height="403"></iframe>
]=]
    else
      template = [=[
---
date: {{current_date}}
tags:
  - article
---
# {{title}}

> [!quote] src: [{{title}}]({{url}}) - [[{{current_date}}]]

{{content}}
]=]
    end
  end
  return render_template(template, parsed_data)
end

---Generate a markdown note from a URL
---@param url string the URL to generate a note from
---@param target_directory string the directory to save the note in
local function generate_note(url, target_directory)
  local parsed_data, error_msg = parse_url(url)
  if not parsed_data then
    print("Error parsing URL: " .. error_msg)
    return
  end

  local converted_note = convert_to_markdown_format(parsed_data)
  local note_file = vim.fn.expand(target_directory .. "/" .. parsed_data.title .. ".md")

  local file = io.open(note_file, "w")
  if file then
    file:write(converted_note)
    file:close()
    print("Note saved to " .. note_file)
  else
    error("Error saving note to file")
  end
end

---Paste URL as markdown link at the current cursor position
local function paste_url()
  local input = vim.fn.getreg("+")
  generate_note(input, vim.g.notes_dir .. "/6-triage")
end

local M = {}
M.paste_url = paste_url
return M
