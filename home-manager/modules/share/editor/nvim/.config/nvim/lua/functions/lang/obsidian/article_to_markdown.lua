local VIDEO_TEMPLATE = [=[
---
date: {{current_date}}
tags: [article/video, to-review]
---
# {{title}}

> [!quote] src: [{{title}}]({{url}}) - [[{{date}}]]
> <iframe frameborder="0" allowfullscreen src="https://youtube.com/embed/{{video_id}}?autoplay=0" width="100%" height="403"></iframe>
]=]
local ARTICLE_TEMPLATE = [=[
---
date: {{current_date}}
tags: [article]
---
# {{title}}

> [!quote] src: [{{title}}]({{url}}) - [[{{date}}]]

{{content}}
]=]

local function trim(text)
  if text == nil then
    return ""
  end

  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

---Clean and normalize the title for use as a filename and in the note
---@param title string the original title to clean
---@return string the cleaned and normalized title
local function clean_title(title)
  local normalized_title = trim(title):gsub("[%s\r\n]+", " ")

  if normalized_title == "" then
    return "untitled"
  end

  return normalized_title:lower()
end

---Normalize various date formats to YYYY-MM-DD
---@param date_str string the date string to normalize
---@return string|nil normalized_date the normalized date or nil if parsing fails
local function normalize_date(date_str)
  if not date_str or date_str == "" then
    return nil
  end

  date_str = trim(date_str)

  local year, month, day = date_str:match("(%d%d%d%d)%-(%d%d)%-(%d%d)T?")
  if year and month and day then
    return string.format("%04d-%02d-%02d", tonumber(year), tonumber(month), tonumber(day))
  end

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

  local part1, part2, year_part = date_str:match("(%d+)/(%d+)/(%d%d%d%d)")
  if part1 and part2 and year_part then
    local month_num, day_number
    if tonumber(part1) > 12 then
      day_number, month_num = part1, part2
    else
      month_num, day_number = part1, part2
    end

    return string.format("%04d-%02d-%02d", tonumber(year_part), tonumber(month_num), tonumber(day_number))
  end

  year, month, day = date_str:match("(%d%d%d%d)/(%d+)/(%d+)")
  if year and month and day then
    return string.format("%04d-%02d-%02d", tonumber(year), tonumber(month), tonumber(day))
  end

  return nil
end

local function is_executable(binary)
  return vim.fn.executable(binary) == 1
end

---Resolve the command to run Defuddle, the awesome CLI https://github.com/kepano/defuddle to get the main content of any pages.
---@param url string the URL to parse
---@param output_flag string the output format flag to pass to Defuddle (e.g., "--json" or "--markdown")
---@return table command the command to run as a list of arguments
---@return table system_options options to pass to vim.system (e.g., { text = true })
---@throws error if neither `defuddle` nor `npx` is available in the system
local function resolve_defuddle_command(url, output_flag)
  if is_executable("defuddle") then
    return { "defuddle", "parse", url, output_flag }, { text = true }
  end

  if is_executable("npx") then
    return { "npx", "--yes", "defuddle", "parse", url, output_flag }, { text = true }
  end

  error("Defuddle CLI not found. Install `defuddle`")
end

---Run the Defuddle command and handle errors
---@param url string the URL to parse
---@param output_flag string the output format flag to pass to Defuddle (e.g., "--json" or "--markdown")
---@return string the standard output from the Defuddle command
---@throws error if the Defuddle command fails or returns an error message
local function run_defuddle_command(url, output_flag)
  local command, system_options = resolve_defuddle_command(url, output_flag)
  local system_result = vim.system(command, system_options):wait()

  if system_result.code ~= 0 then
    local error_message = trim(system_result.stderr ~= "" and system_result.stderr or system_result.stdout or "")
    if error_message == "" then
      error_message = "unknown error"
    end

    error("Defuddle failed: " .. error_message)
  end

  return system_result.stdout
end

---Run the Defuddle command and return JSON output.
---@param url string the URL to parse
---@return table the decoded JSON output from Defuddle
---@throws error if the Defuddle command fails or returns invalid JSON
local function run_defuddle_json(url)
  local stdout = run_defuddle_command(url, "--json")
  if trim(stdout) == "" then
    error("Defuddle returned no JSON output")
  end

  local success, decoded = pcall(vim.json.decode, stdout)
  if not success then
    error("Failed to decode Defuddle JSON: " .. tostring(decoded))
  end

  return decoded
end

---Run the Defuddle command and return Markdown output.
---@param url string the URL to parse
---@return string the Markdown content extracted by Defuddle
---@throws error if the Defuddle command fails or returns no Markdown output
local function run_defuddle_markdown(url)
  local stdout = run_defuddle_command(url, "--markdown")
  local markdown = trim(stdout)

  if markdown == "" then
    error("Defuddle returned no Markdown output")
  end

  return markdown
end

---Main parsing function
---@param input_url string the URL to parse
---@return table table containing parsed data or nil if parsing fails
local function parse_url(input_url)
  local success, url_parser = pcall(require("functions.url_parser").new, input_url)
  if not success then
    error("Invalid URL: " .. tostring(url_parser))
  end

  local metadata = run_defuddle_json(input_url)
  local result = {
    url = input_url,
    title = clean_title(metadata.title or input_url),
    date = normalize_date(metadata.published) or os.date("%Y-%m-%d"),
    current_date = os.date("%Y-%m-%d"),
  }

  local video_id = url_parser:extract_youtube_video_id()
  if video_id then
    result.is_video = true
    result.video_id = video_id
    result.content = ""
    return result
  end

  result.is_video = false
  result.content = run_defuddle_markdown(input_url)
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
      return "{{" .. var .. "}}"
    end
  end)

  result = result:gsub("%%([%w_]+)%%", function(var)
    local value = data[var]
    if value ~= nil then
      return tostring(value)
    else
      return "%" .. var .. "%"
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
