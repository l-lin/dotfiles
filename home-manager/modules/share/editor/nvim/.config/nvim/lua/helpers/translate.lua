---Translate words using `trans` CLI (translate-shell)

---Format trans output as readable markdown
---@param lines string[]
---@return string[], string|nil formatted lines and main translation
local function format_trans_output(lines)
  local result = {}
  local main_translation = nil
  local i = 1

  -- Skip empty lines at start
  while i <= #lines and lines[i]:match("^%s*$") do
    i = i + 1
  end

  -- Line 1: Original word
  if i <= #lines then
    table.insert(result, "# " .. lines[i]:gsub("^%s+", ""))
    table.insert(result, "")
    i = i + 1
  end

  -- Line 2: Pronunciation (if starts with /)
  if i <= #lines and lines[i]:match("^/") then
    table.insert(result, "*" .. lines[i] .. "*")
    table.insert(result, "")
    i = i + 1
  end

  -- Skip empty lines, then get main translation
  while i <= #lines and lines[i]:match("^%s*$") do
    i = i + 1
  end
  if i <= #lines and not lines[i]:match("^Definitions") and not lines[i]:match("^%[") then
    local main_trans = lines[i]:gsub("^%s+", "")
    if main_trans ~= "" then
      main_translation = main_trans
      table.insert(result, main_trans)
      table.insert(result, "")
      i = i + 1
    end
  end

  -- Process remaining lines
  while i <= #lines do
    local line = lines[i]
    local trimmed = line:gsub("^%s+", "")

    if line:match("^Definitions of") or line:match("^%[ .* %]$") then
      -- Skip "Definitions of X" and "[ Lang -> Lang ]" headers
      i = i + 1
    elseif line:match("^Examples") or line:match("^Synonyms") or line:match("^See also") then
      -- Section headers
      table.insert(result, "")
      table.insert(result, "## " .. trimmed)
      table.insert(result, "")
      i = i + 1
    elseif line:match("^%a") and not line:match("^%s") and line:match("^%l") then
      -- Part of speech (noun, verb, adjective, etc.) - starts with lowercase at column 0
      table.insert(result, "")
      table.insert(result, "## " .. trimmed:gsub("^%l", string.upper))
      table.insert(result, "")
      i = i + 1
    elseif line:match("^    %a") and not line:match("^        ") then
      -- Primary definition/translation (4 spaces indent)
      table.insert(result, "" .. trimmed:gsub("!$", ""))
      i = i + 1
    elseif line:match("^        ") then
      -- Secondary items (8 spaces indent) - synonyms or examples
      local content = trimmed:gsub("^%- ", "")
      table.insert(result, "> [!quote] " .. content)
      table.insert(result, "")
      i = i + 1
    elseif line:match("^%s*%- ") then
      -- Example with dash
      table.insert(result, "" .. trimmed:gsub("^%- ", ""))
      i = i + 1
    elseif trimmed ~= "" then
      -- Other non-empty lines
      table.insert(result, trimmed)
      i = i + 1
    else
      i = i + 1
    end
  end

  return result, main_translation
end

---@class TranslateOpts
---@field on_result fun(formatted: string[], main_translation: string|nil)|nil
---@field on_error fun(msg: string)|nil

--- Translate a word using trans CLI
---@param word string the word(s) to translate
---@param target_lang string target language code (e.g., "en", "fr")
---@param opts TranslateOpts|nil callback options
---@return number job_id or 0 if failed
local function translate(word, target_lang, opts)
  opts = opts or {}

  -- Validate target_lang to prevent shell injection (should be 2-3 letter code)
  if not target_lang:match("^%a%a%a?$") then
    if opts.on_error then
      opts.on_error("Invalid language code: " .. target_lang)
    end
    return 0
  end

  local cmd = string.format("trans -no-ansi :%s %s", target_lang, vim.fn.shellescape(word))

  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 and data[1] ~= "" then
        local formatted, main_translation = format_trans_output(data)
        vim.schedule(function()
          if opts.on_result then
            opts.on_result(formatted, main_translation)
          end
        end)
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 and data[1] ~= "" then
        vim.schedule(function()
          if opts.on_error then
            opts.on_error(table.concat(data, "\n"))
          end
        end)
      end
    end,
  })

  if job_id <= 0 and opts.on_error then
    opts.on_error("Failed to run 'trans'. Is translate-shell installed?")
  end

  return job_id
end

local M = {}
M.format_trans_output = format_trans_output
M.translate = translate
return M
