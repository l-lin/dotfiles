local text = require("functions.lang.mermaid.text")

local ERASE_CHAR = "\0"

local STRUCTURAL_CHARS = {
  ["─"] = true,
  ["│"] = true,
  ["┌"] = true,
  ["┐"] = true,
  ["└"] = true,
  ["┘"] = true,
  ["├"] = true,
  ["┤"] = true,
  ["┬"] = true,
  ["┴"] = true,
  ["┼"] = true,
  ["╭"] = true,
  ["╮"] = true,
  ["╰"] = true,
  ["╯"] = true,
  ["╔"] = true,
  ["╗"] = true,
  ["╚"] = true,
  ["╝"] = true,
  ["═"] = true,
  ["║"] = true,
  ["●"] = true,
  ["◎"] = true,
  ["◇"] = true,
  ["⌜"] = true,
  ["⌝"] = true,
  ["⌞"] = true,
  ["⌟"] = true,
  ["▷"] = true,
  ["◯"] = true,
  ["◉"] = true,
  ["◄"] = true,
  ["►"] = true,
  ["▲"] = true,
  ["▼"] = true,
  ["◢"] = true,
  ["◣"] = true,
  ["◤"] = true,
  ["◥"] = true,
  ["▶"] = true,
  ["◀"] = true,
  ["◁"] = true,
  ["┄"] = true,
  ["┆"] = true,
  ["━"] = true,
  ["┃"] = true,
  ["╌"] = true,
}

local JUNCTION_MAP = {
  ["─"] = { ["│"] = "┼", ["┌"] = "┬", ["┐"] = "┬", ["└"] = "┴", ["┘"] = "┴", ["├"] = "┼", ["┤"] = "┼", ["┬"] = "┬", ["┴"] = "┴" },
  ["│"] = { ["─"] = "┼", ["┌"] = "├", ["┐"] = "┤", ["└"] = "├", ["┘"] = "┤", ["├"] = "├", ["┤"] = "┤", ["┬"] = "┼", ["┴"] = "┼" },
  ["┌"] = { ["─"] = "┬", ["│"] = "├", ["┐"] = "┬", ["└"] = "├", ["┘"] = "┼", ["├"] = "├", ["┤"] = "┼", ["┬"] = "┬", ["┴"] = "┼" },
  ["┐"] = { ["─"] = "┬", ["│"] = "┤", ["┌"] = "┬", ["└"] = "┼", ["┘"] = "┤", ["├"] = "┼", ["┤"] = "┤", ["┬"] = "┬", ["┴"] = "┼" },
  ["└"] = { ["─"] = "┴", ["│"] = "├", ["┌"] = "├", ["┐"] = "┼", ["┘"] = "┴", ["├"] = "├", ["┤"] = "┼", ["┬"] = "┼", ["┴"] = "┴" },
  ["┘"] = { ["─"] = "┴", ["│"] = "┤", ["┌"] = "┼", ["┐"] = "┤", ["└"] = "┴", ["├"] = "┼", ["┤"] = "┤", ["┬"] = "┼", ["┴"] = "┴" },
  ["├"] = { ["─"] = "┼", ["│"] = "├", ["┌"] = "├", ["┐"] = "┼", ["└"] = "├", ["┘"] = "┼", ["┤"] = "┼", ["┬"] = "┼", ["┴"] = "┼" },
  ["┤"] = { ["─"] = "┼", ["│"] = "┤", ["┌"] = "┼", ["┐"] = "┤", ["└"] = "┼", ["┘"] = "┤", ["├"] = "┼", ["┬"] = "┼", ["┴"] = "┼" },
  ["┬"] = { ["─"] = "┬", ["│"] = "┼", ["┌"] = "┬", ["┐"] = "┬", ["└"] = "┼", ["┘"] = "┼", ["├"] = "┼", ["┤"] = "┼", ["┴"] = "┼" },
  ["┴"] = { ["─"] = "┴", ["│"] = "┼", ["┌"] = "┼", ["┐"] = "┼", ["└"] = "┴", ["┘"] = "┴", ["├"] = "┼", ["┤"] = "┼", ["┬"] = "┼" },
}

local VERTICAL_FLIP_MAP = {
  ["▲"] = "▼",
  ["▼"] = "▲",
  ["◤"] = "◣",
  ["◣"] = "◤",
  ["◥"] = "◢",
  ["◢"] = "◥",
  ["┌"] = "└",
  ["└"] = "┌",
  ["┐"] = "┘",
  ["┘"] = "┐",
  ["┬"] = "┴",
  ["┴"] = "┬",
}

local function mk_canvas(max_x, max_y)
  local canvas = {}
  for x = 0, max_x do
    local column = {}
    for y = 0, max_y do
      column[y] = " "
    end
    canvas[x] = column
  end
  return canvas
end

local function get_canvas_size(canvas)
  local max_x = -1
  for x in pairs(canvas) do
    if x > max_x then
      max_x = x
    end
  end
  local max_y = -1
  if max_x >= 0 then
    for y in pairs(canvas[0]) do
      if y > max_y then
        max_y = y
      end
    end
  end
  return max_x, max_y
end

local function ensure_column(canvas, x, max_y)
  if not canvas[x] then
    canvas[x] = {}
    for y = 0, max_y do
      canvas[x][y] = " "
    end
  end
end

local function increase_size(canvas, new_x, new_y)
  local current_x, current_y = get_canvas_size(canvas)
  local target_x = math.max(new_x, current_x)
  local target_y = math.max(new_y, current_y)

  for x = 0, target_x do
    ensure_column(canvas, x, target_y)
    for y = 0, target_y do
      if canvas[x][y] == nil then
        canvas[x][y] = " "
      end
    end
  end

  return canvas
end

local function copy_canvas(source)
  local max_x, max_y = get_canvas_size(source)
  local copied = mk_canvas(max_x, max_y)

  for x = 0, max_x do
    for y = 0, max_y do
      copied[x][y] = source[x][y]
    end
  end

  return copied
end

local function is_structural_char(char)
  return STRUCTURAL_CHARS[char] == true
end

local function is_text_char(char)
  return char ~= " " and char ~= ERASE_CHAR and not is_structural_char(char)
end

local function is_junction_char(char)
  return JUNCTION_MAP[char] ~= nil or char == "┼"
end

local function merge_junctions(current, overlay)
  local merged = JUNCTION_MAP[current]
  if merged and merged[overlay] then
    return merged[overlay]
  end
  return current
end

local function draw_text(canvas, start, value, force_overwrite)
  local chars = text.utf8_chars(value)
  increase_size(canvas, start.x + #chars, start.y)

  for index, char in ipairs(chars) do
    local x = start.x + index - 1
    local current = canvas[x][start.y]
    if force_overwrite or current == " " then
      if force_overwrite and char == " " then
        canvas[x][start.y] = ERASE_CHAR
      else
        canvas[x][start.y] = char
      end
    end
  end
end

local function merge_canvases(base, offset, overlays)
  local max_x, max_y = get_canvas_size(base)
  for _, overlay in ipairs(overlays) do
    local overlay_x, overlay_y = get_canvas_size(overlay)
    max_x = math.max(max_x, overlay_x + offset.x)
    max_y = math.max(max_y, overlay_y + offset.y)
  end

  local merged = mk_canvas(max_x, max_y)
  for x = 0, max_x do
    for y = 0, max_y do
      if base[x] and base[x][y] then
        merged[x][y] = base[x][y]
      else
        merged[x][y] = " "
      end
    end
  end

  for _, overlay in ipairs(overlays) do
    local overlay_x, overlay_y = get_canvas_size(overlay)
    for x = 0, overlay_x do
      for y = 0, overlay_y do
        local char = overlay[x][y]
        if char ~= " " then
          local target_x = x + offset.x
          local target_y = y + offset.y
          local current = merged[target_x][target_y]

          if char == ERASE_CHAR then
            merged[target_x][target_y] = " "
          elseif is_junction_char(current) and is_junction_char(char) then
            merged[target_x][target_y] = merge_junctions(current, char)
          elseif is_text_char(current) and is_text_char(char) then
            -- Preserve the earliest label text on collisions, mirroring the upstream renderer.
          else
            merged[target_x][target_y] = char
          end
        end
      end
    end
  end

  return merged
end

local function canvas_to_lines(canvas)
  local max_x, max_y = get_canvas_size(canvas)
  local lines = {}

  for y = 0, max_y do
    local row = {}
    for x = 0, max_x do
      row[#row + 1] = canvas[x][y] == ERASE_CHAR and " " or canvas[x][y]
    end
    lines[#lines + 1] = table.concat(row):gsub("%s+$", "")
  end

  return lines
end

local function set_canvas_size_to_grid(canvas, column_width, row_height)
  local max_x = 0
  local max_y = 0

  for _, width in pairs(column_width) do
    max_x = max_x + width
  end
  for _, height in pairs(row_height) do
    max_y = max_y + height
  end

  increase_size(canvas, math.max(max_x - 1, 0), math.max(max_y - 1, 0))
end

local function flip_canvas_vertically(canvas)
  local max_x, max_y = get_canvas_size(canvas)

  for x = 0, max_x do
    local column = canvas[x]
    for y = 0, math.floor(max_y / 2) do
      column[y], column[max_y - y] = column[max_y - y], column[y]
    end
  end

  for x = 0, max_x do
    for y = 0, max_y do
      local flipped = VERTICAL_FLIP_MAP[canvas[x][y]]
      if flipped then
        canvas[x][y] = flipped
      end
    end
  end

  return canvas
end

local M = {}
M.mk_canvas = mk_canvas
M.copy_canvas = copy_canvas
M.get_canvas_size = get_canvas_size
M.increase_size = increase_size
M.draw_text = draw_text
M.merge_canvases = merge_canvases
M.canvas_to_lines = canvas_to_lines
M.set_canvas_size_to_grid = set_canvas_size_to_grid
M.flip_canvas_vertically = flip_canvas_vertically
return M
