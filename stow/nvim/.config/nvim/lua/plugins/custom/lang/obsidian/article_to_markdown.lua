local VIDEO_TEMPLATE = [=[
---
date: {{current_date}}
tags:
  - article/video
  - to-review
---
# {{title}}

> [!quote] src: [{{title}}]({{url}}) - [[{{date}}]]
> <iframe frameborder="0" allowfullscreen src="https://youtube.com/embed/{{video_id}}?autoplay=0" width="100%" height="403"></iframe>
]=]
local ARTICLE_TEMPLATE = [=[
---
date: {{current_date}}
tags:
  - article
---
# {{title}}

> [!quote] src: [{{title}}]({{url}}) - [[{{date}}]]

{{content}}
]=]

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
    local list_content = content:gsub("<li.->(.-)</li>", "- %1\n")
    -- Remove extra newlines between list items
    list_content = list_content:gsub("\n\n+", "\n")
    return list_content
  end)

  markdown = markdown:gsub("<ol.->(.-)</ol>", function(content)
    local counter = 1
    local list_content = content:gsub("<li.->(.-)</li>", function(item)
      local result = counter .. ". " .. item .. "\n"
      counter = counter + 1
      return result
    end)
    -- Remove extra newlines between list items
    list_content = list_content:gsub("\n\n+", "\n")
    return list_content
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
  -- Remove excessive newlines (more than 2 consecutive newlines)
  markdown = markdown:gsub("\n\n\n+", "\n\n")
  -- Clean up newlines around list items and other elements
  markdown = markdown:gsub("\n%s*\n%s*\n", "\n\n")
  -- Remove leading/trailing whitespace
  markdown = markdown:gsub("^%s+", "")
  markdown = markdown:gsub("%s+$", "")

  return markdown
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

---Normalize various date formats to YYYY-MM-DD
---@param date_str string the date string to normalize
---@return string|nil normalized_date the normalized date or nil if parsing fails
local function normalize_date(date_str)
  if not date_str then
    return nil
  end

  -- Clean the date string
  date_str = date_str:gsub("^%s+", ""):gsub("%s+$", "")

  -- ISO 8601 format (2023-12-25T10:30:00Z or 2023-12-25T10:30:00+00:00)
  local year, month, day = date_str:match("(%d%d%d%d)%-(%d%d)%-(%d%d)T?")
  if year and month and day then
    return string.format("%04d-%02d-%02d", tonumber(year), tonumber(month), tonumber(day))
  end

  -- Format: December 25, 2023 or Dec 25, 2023
  local month_names = {
    january = "01",
    jan = "01",
    february = "02",
    feb = "02",
    march = "03",
    mar = "03",
    april = "04",
    apr = "04",
    may = "05",
    june = "06",
    jun = "06",
    july = "07",
    jul = "07",
    august = "08",
    aug = "08",
    september = "09",
    sep = "09",
    october = "10",
    oct = "10",
    november = "11",
    nov = "11",
    december = "12",
    dec = "12",
  }

  local month_name, day_num, year_num = date_str:lower():match("(%a+)%s+(%d+),%s*(%d%d%d%d)")
  if month_name and day_num and year_num and month_names[month_name] then
    return string.format("%04d-%s-%02d", tonumber(year_num), month_names[month_name], tonumber(day_num))
  end

  -- Format: 25/12/2023 or 12/25/2023 (ambiguous, assume MM/DD/YYYY for US sites)
  local part1, part2, year_part = date_str:match("(%d+)/(%d+)/(%d%d%d%d)")
  if part1 and part2 and year_part then
    -- Assume MM/DD/YYYY if first part > 12, otherwise DD/MM/YYYY
    local month_num, day_number
    if tonumber(part1) > 12 then
      day_number, month_num = part1, part2
    else
      month_num, day_number = part1, part2
    end
    return string.format("%04d-%02d-%02d", tonumber(year_part), tonumber(month_num), tonumber(day_number))
  end

  -- Format: 2023/12/25
  year, month, day = date_str:match("(%d%d%d%d)/(%d+)/(%d+)")
  if year and month and day then
    return string.format("%04d-%02d-%02d", tonumber(year), tonumber(month), tonumber(day))
  end

  return nil
end

---Extract publication date from HTML content
---@param html_content string the HTML content to extract date from
---@param url_parser dotfiles.helpers.UrlParser the URL parser instance
---@return string|nil date the extracted date in YYYY-MM-DD format or nil if not found
local function extract_date(html_content, url_parser)
  if not html_content then
    return nil
  end

  -- List of date patterns to try, in order of preference
  local date_patterns = {
    -- Meta tags
    { pattern = '<meta[^>]*property="article:published_time"[^>]*content="([^"]+)"', priority = 1 },
    { pattern = '<meta[^>]*name="publishdate"[^>]*content="([^"]+)"', priority = 1 },
    { pattern = '<meta[^>]*name="publish-date"[^>]*content="([^"]+)"', priority = 1 },
    { pattern = '<meta[^>]*name="date"[^>]*content="([^"]+)"', priority = 1 },
    { pattern = '<meta[^>]*name="DC%.date"[^>]*content="([^"]+)"', priority = 1 },
    { pattern = '<meta[^>]*name="publication-date"[^>]*content="([^"]+)"', priority = 1 },

    -- JSON-LD structured data
    { pattern = '"datePublished"%s*:%s*"([^"]+)"', priority = 2 },
    { pattern = '"dateCreated"%s*:%s*"([^"]+)"', priority = 2 },
    { pattern = '"uploadDate"%s*:%s*"([^"]+)"', priority = 2 },

    -- Time elements
    { pattern = '<time[^>]*datetime="([^"]+)"', priority = 3 },
    { pattern = '<time[^>]*pubdate[^>]*datetime="([^"]+)"', priority = 2 },

    -- Common class/id patterns
    { pattern = '<[^>]*class="[^"]*date[^"]*"[^>]*>([^<]+)', priority = 4 },
    { pattern = '<[^>]*class="[^"]*published[^"]*"[^>]*>([^<]+)', priority = 4 },
    { pattern = '<[^>]*id="[^"]*date[^"]*"[^>]*>([^<]+)', priority = 4 },
  }

  -- YouTube-specific patterns
  if url_parser:is_youtube_url() then
    table.insert(date_patterns, 1, { pattern = '"publishDate":"([^"]+)"', priority = 1 })
    table.insert(date_patterns, 1, { pattern = '"uploadDate":"([^"]+)"', priority = 1 })
  end

  local found_dates = {}

  -- Extract all potential dates
  for _, pattern_info in ipairs(date_patterns) do
    local date_str = html_content:match(pattern_info.pattern)
    if date_str then
      table.insert(found_dates, { date = date_str, priority = pattern_info.priority })
    end
  end

  -- Sort by priority (lower number = higher priority)
  table.sort(found_dates, function(a, b)
    return a.priority < b.priority
  end)

  -- Try to parse the first valid date
  for _, date_info in ipairs(found_dates) do
    local normalized_date = normalize_date(date_info.date)
    if normalized_date then
      return normalized_date
    end
  end

  return nil
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
    ["&ldquo;"] = '"',
    ["&rdquo;"] = '"',
    ["&lsquo;"] = "'",
    ["&rsquo;"] = "'",
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
---@param url_parser dotfiles.helpers.UrlParser the URL parser instance
---@return table metadata a table containing extracted metadata
local function extract_metadata(html_content, url_parser)
  local metadata = {}
  metadata.title = html_content:match("<title[^>]*>%s*(.-)%s*</title>") or "Untitled"
  metadata.title = clean_text(metadata.title)

  -- Remove "- YouTube" suffix for YouTube videos
  if url_parser:is_youtube_url() then
    metadata.title = metadata.title:gsub("%s*-%s*YouTube%s*$", "")
  end

  -- Extract publication date
  metadata.date = extract_date(html_content, url_parser)

  return metadata
end

---Main parsing function
---@param input_url string the URL to parse
---@return table table containing parsed data or nil if parsing fails
local function parse_url(input_url)
  local success, url_parser = pcall(require("helpers.url_parser").new, input_url)
  if not success then
    error("Invalid URL: " .. tostring(url_parser))
  end

  local response = require("helpers.http_client").new():get(input_url)
  if not response or response.status_code >= 400 then
    error("Failed to fetch HTML content from URL")
  end

  local metadata = extract_metadata(response.content, url_parser)
  local result = {
    url = input_url,
    title = metadata.title,
    date = metadata.date or os.date("%Y-%m-%d"),
    current_date = os.date("%Y-%m-%d"),
  }

  -- Handle YouTube videos differently
  local video_id = url_parser:extract_youtube_video_id()
  if video_id then
    result.is_video = true
    result.video_id = video_id
    result.content = "" -- No content needed for YouTube videos
  else
    local readable_content = extract_readable_content(response.content)
    if not readable_content then
      error("Could not extract readable content")
    end

    local markdown_content = html_to_markdown(readable_content)
    markdown_content = clean_text(markdown_content)

    result.content = markdown_content
    result.is_video = false
  end

  return result
end

---Template rendering function (simplified)
---@param template string|nil the template string with placeholders
---@param data table a table containing data to fill in the template
---@return string the rendered template
local function render_template(template, data)
  if not template then
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
    if parsed_data.is_video then
      template = VIDEO_TEMPLATE
    else
      template = ARTICLE_TEMPLATE
    end
  end
  return render_template(template, parsed_data)
end

---Generate a markdown note from a URL
---@param url string the URL to generate a note from
---@param target_directory string the directory to save the note in
local function generate_note(url, target_directory)
  local success, parsed_data = pcall(parse_url, url)
  if not success then
    print("Error parsing URL: " .. tostring(parsed_data))
    return
  end

  local converted_note = convert_to_markdown_format(parsed_data)
  local note_file = vim.fn.expand(target_directory .. "/" .. parsed_data.title .. ".md")

  local file = io.open(note_file, "w")
  if file then
    file:write(converted_note)
    file:close()
    print("Note saved to " .. note_file)
    vim.cmd("vsplit " .. vim.fn.fnameescape(note_file))
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
