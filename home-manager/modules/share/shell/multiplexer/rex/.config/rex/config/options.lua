rex.action({
  name = "enable_developer_mode",
  title = "Enable Developer Mode",
  run = function()
    rex.client.queue("client.setting.developer.mode.enabled", { value = true })
  end,
})
rex.action({
  name = "new_quick_switcher",
  title = "Enable Quick Switcher",
  run = function()
    rex.client.queue("client.setting.developer.experimental.new_quick_switcher", { value = true })
  end,
})
