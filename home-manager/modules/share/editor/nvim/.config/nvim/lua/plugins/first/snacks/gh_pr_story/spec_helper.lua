if type(describe) == "function" then
  return
end

local helper_path = debug.getinfo(1, "S").source:sub(2)
local lua_root = helper_path:match("^(.*)/plugins/") or helper_path:match("^(.*)/functions/")
local busted_lua_root = "/opt/homebrew/opt/busted/libexec/share/lua/5.5"
local busted_c_root = "/opt/homebrew/opt/busted/libexec/lib/lua/5.5"

package.path = table.concat({
  lua_root .. "/?.lua",
  lua_root .. "/?/init.lua",
  busted_lua_root .. "/?.lua",
  busted_lua_root .. "/?/init.lua",
  package.path,
}, ";")

package.cpath = table.concat({
  busted_c_root .. "/?.so",
  package.cpath,
}, ";")
