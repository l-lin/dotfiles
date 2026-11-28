--
-- Open GitHub pull requests in lazygh from the clipboard.
--

local LAZYGH = "lazygh"
local CLIPBOARD_COMMANDS = {
  { argv = { "pbpaste" }, env = { LC_CTYPE = "UTF-8" } },
  { argv = { "wl-paste", "--type", "text" } },
  { argv = { "xclip", "-selection", "clipboard", "-out" } },
  { argv = { "xsel", "--clipboard", "--output" } },
}

-- mise can add tools to PATH only after the first prompt.
local LAZYGH_LAUNCHER = [[
if command -v "$1" >/dev/null 2>&1; then
  exec "$@"
fi
if command -v mise >/dev/null 2>&1; then
  exec mise exec -- "$@"
fi
printf 'Cannot find %s on PATH.\n' "$1" >&2
exit 127
]]

local function read_clipboard()
  for _, command in ipairs(CLIPBOARD_COMMANDS) do
    local result = rex.exec(command.argv, { env = command.env, timeout = 2 })
    if result and result.ok then
      return result.stdout
    end
  end
  error("Cannot read the clipboard.", 0)
end

local function open_lazygh(ctx)
  local url = read_clipboard():match("^%s*(.-)%s*$")
  local host, suffix = url:match("^https?://([^/]+)/[^/]+/[^/]+/pulls?/[1-9]%d*(.*)$")
  host = host and host:lower()
  if
    (host ~= "github.com" and host ~= "www.github.com")
    or url:find("[%s%c]")
    or (suffix ~= "" and not suffix:match("^[/#?]"))
  then
    error("The clipboard does not contain a GitHub pull request URL.", 0)
  end

  local result, err = rex.session.new_window({
    session_id = ctx.session_id,
    window_label = "lazygh",
    focus = true,
    layout = rex.layout.block({
      flavor = "com.superlogical.terminal.shell",
      options = {
        interactive = true,
        command = { "sh", "-c", LAZYGH_LAUNCHER, "rex-lazygh", LAZYGH, "view", url },
      },
    }),
  })
  if not result then
    error(err, 0)
  end
  rex.client.queue("session.select", { session_id = ctx.session_id, window_id = result.window_id })
  return result
end

rex.action({ name = "open_lazygh", title = "Open Clipboard Pull Request in lazygh", run = open_lazygh })
rex.bind("ctrl+q>shift+o", "open_lazygh")
