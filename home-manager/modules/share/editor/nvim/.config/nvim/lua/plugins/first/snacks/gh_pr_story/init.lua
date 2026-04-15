local picker = require("plugins.first.snacks.gh_pr_story.picker")
local story = require("plugins.first.snacks.gh_pr_story.story")

local function start_picker(opts)
  if not opts.pr then
    vim.notify("PR id is required", vim.log.levels.ERROR)
    return
  end

  Snacks.picker.gh_pr_story(opts)
end

local function open_from_clipboard(on_target)
  local clipboard = vim.fn.getreg("+"):gsub("%s+$", "")
  local repo, pr = require("functions.git").extract_repo_name_and_pr_id_from_url(clipboard)
  if not repo or not pr then
    vim.notify("Clipboard does not contain a pull request URL", vim.log.levels.ERROR)
    return
  end

  if on_target then
    on_target(repo, pr)
  end

  start_picker({ repo = repo, pr = pr })
end

return {
  STORY_MODEL = story.STORY_MODEL,
  build_pi_command = story.build_pi_command,
  build_story_prompt = story.build_story_prompt,
  close = picker.close,
  confirm = picker.confirm,
  decode_story = story.decode_story,
  finder = picker.finder,
  format = picker.format,
  gh_actions = picker.gh_actions,
  gh_comment = picker.gh_comment,
  normalize_story = story.normalize_story,
  open = picker.open,
  open_from_clipboard = open_from_clipboard,
  preview = picker.preview,
  start_picker = start_picker,
  to_tree_items = picker.to_tree_items,
  toggle = picker.toggle,
}
