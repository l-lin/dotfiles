local mermaid = require("functions.lang.mermaid")

describe("mermaid.preview_lines_at_row", function()
  it("GIVEN the cursor inside a Mermaid block WHEN building a navigation preview THEN it returns the rendered lines for that block", function()
    local markdown_lines = {
      "# Mermaid preview smoke",
      "",
      "```mermaid",
      "graph LR",
      "A --> B",
      "```",
      "",
      "after flowchart",
    }

    local actual = assert(mermaid.preview_lines_at_row(markdown_lines, 3))
    local expected = {
      "┌───┐     ┌───┐",
      "│   │     │   │",
      "│ A ├────│ B │",
      "│   │     │   │",
      "└───┘     └───┘",
    }

    assert.are.same(expected, actual)
  end)

  it("GIVEN the cursor outside a Mermaid block WHEN building a navigation preview THEN it reports that there is nothing to preview", function()
    local markdown_lines = {
      "# Mermaid preview smoke",
      "",
      "```mermaid",
      "graph LR",
      "A --> B",
      "```",
      "",
      "after flowchart",
    }

    local actual, reason = mermaid.preview_lines_at_row(markdown_lines, 0)
    local expected = "cursor is not inside a Mermaid block"

    assert.are.equal(nil, actual)
    assert.are.equal(expected, reason)
  end)
end)

describe("mermaid.build_popup_request_at_row", function()
  it("GIVEN the cursor inside a Mermaid block WHEN building a popup request THEN it includes the rendered text and block metadata", function()
    local markdown_lines = {
      "# Mermaid preview smoke",
      "",
      "```mermaid",
      "graph LR",
      "A --> B",
      "```",
      "",
      "after flowchart",
    }

    local actual = assert(mermaid.build_popup_request_at_row(markdown_lines, 3, 17, 23))
    local expected_lines = {
      "┌───┐     ┌───┐",
      "│   │     │   │",
      "│ A ├────│ B │",
      "│   │     │   │",
      "└───┘     └───┘",
    }
    local expected = {
      source_bufnr = 17,
      source_winid = 23,
      source_row = 3,
      block_start_row = 2,
      block_end_row = 5,
      preview_lines = expected_lines,
      preview_text = table.concat(expected_lines, "\n"),
    }

    assert.are.same(expected, actual)
  end)

  it("GIVEN the cursor on a Mermaid fence WHEN building a popup request THEN it still renders that fenced block", function()
    local markdown_lines = {
      "# Mermaid preview smoke",
      "",
      "```mermaid",
      "graph LR",
      "A --> B",
      "```",
      "",
      "after flowchart",
    }

    local actual = assert(mermaid.build_popup_request_at_row(markdown_lines, 5, 17, 23))
    local expected_lines = {
      "┌───┐     ┌───┐",
      "│   │     │   │",
      "│ A ├────│ B │",
      "│   │     │   │",
      "└───┘     └───┘",
    }

    assert.are.same(expected_lines, actual.preview_lines)
    assert.are.equal(5, actual.source_row)
    assert.are.equal(2, actual.block_start_row)
    assert.are.equal(5, actual.block_end_row)
  end)
end)

describe("mermaid.determine_popup_action", function()
  it("GIVEN no popup WHEN requesting a Mermaid preview THEN it opens a popup", function()
    local request = {
      source_bufnr = 17,
      block_start_row = 2,
      block_end_row = 5,
      preview_text = "diagram",
    }

    local actual = mermaid.determine_popup_action(nil, request)
    local expected = "open"

    assert.are.equal(expected, actual)
  end)

  it("GIVEN the same block is already open WHEN requesting the Mermaid preview again THEN it focuses the popup", function()
    local active_popup = {
      source_bufnr = 17,
      block_start_row = 2,
      block_end_row = 5,
      preview_text = "diagram",
    }
    local request = {
      source_bufnr = 17,
      block_start_row = 2,
      block_end_row = 5,
      preview_text = "diagram",
    }

    local actual = mermaid.determine_popup_action(active_popup, request)
    local expected = "focus"

    assert.are.equal(expected, actual)
  end)

  it("GIVEN a different Mermaid block is already open WHEN requesting another preview THEN it replaces the popup", function()
    local active_popup = {
      source_bufnr = 17,
      block_start_row = 2,
      block_end_row = 5,
      preview_text = "diagram",
    }
    local request = {
      source_bufnr = 17,
      block_start_row = 9,
      block_end_row = 14,
      preview_text = "other diagram",
    }

    local actual = mermaid.determine_popup_action(active_popup, request)
    local expected = "replace"

    assert.are.equal(expected, actual)
  end)

  it("GIVEN the same Mermaid block changed WHEN requesting the preview again THEN it replaces the stale popup", function()
    local active_popup = {
      source_bufnr = 17,
      block_start_row = 2,
      block_end_row = 5,
      preview_text = "diagram",
    }
    local request = {
      source_bufnr = 17,
      block_start_row = 2,
      block_end_row = 5,
      preview_text = "updated diagram",
    }

    local actual = mermaid.determine_popup_action(active_popup, request)
    local expected = "replace"

    assert.are.equal(expected, actual)
  end)
end)

describe("mermaid.determine_markdown_k_action", function()
  it("GIVEN the cursor is outside a Mermaid block WHEN Markdown K is pressed THEN it falls back to normal K behavior", function()
    local actual = mermaid.determine_markdown_k_action(nil, nil, "cursor is not inside a Mermaid block")
    local expected = "fallback"

    assert.are.equal(expected, actual)
  end)

  it("GIVEN the cursor is inside an unsupported Mermaid fence WHEN Markdown K is pressed THEN it keeps Mermaid ownership and warns", function()
    local actual = mermaid.determine_markdown_k_action(nil, nil, "unsupported diagram kind: class")
    local expected = "warn"

    assert.are.equal(expected, actual)
  end)

  it("GIVEN the same Mermaid block is already open WHEN Markdown K is pressed again THEN it focuses the popup", function()
    local active_popup = {
      source_bufnr = 17,
      block_start_row = 2,
      block_end_row = 5,
      preview_text = "diagram",
    }
    local request = {
      source_bufnr = 17,
      block_start_row = 2,
      block_end_row = 5,
      preview_text = "diagram",
    }

    local actual = mermaid.determine_markdown_k_action(active_popup, request)
    local expected = "focus"

    assert.are.equal(expected, actual)
  end)
end)

describe("mermaid.resolve_source_key", function()
  it("GIVEN a mapped key callback WHEN Neovim provides the original typed key THEN it uses the typed key", function()
    local actual = mermaid.resolve_source_key("��g", "K")
    local expected = "K"

    assert.are.equal(expected, actual)
  end)

  it("GIVEN a direct key callback WHEN there is no separate typed key THEN it uses the raw key", function()
    local actual = mermaid.resolve_source_key("j", nil)
    local expected = "j"

    assert.are.equal(expected, actual)
  end)
end)

describe("mermaid.should_close_popup_for_source_key", function()
  it("GIVEN source-window K WHEN deciding whether to keep the popup open THEN it stays open", function()
    local actual = mermaid.should_close_popup_for_source_key("K")
    local expected = false

    assert.are.equal(expected, actual)
  end)

  it("GIVEN any other source-window key WHEN deciding whether to keep the popup open THEN it closes", function()
    local actual = mermaid.should_close_popup_for_source_key("q")
    local expected = true

    assert.are.equal(expected, actual)
  end)
end)

describe("mermaid.should_close_popup_for_source_context", function()
  local given_popup = {
    winid = 99,
    source_bufnr = 17,
    source_winid = 23,
    source_row = 3,
  }

  it("GIVEN the popup itself has focus WHEN checking source context THEN it stays open", function()
    local actual = mermaid.should_close_popup_for_source_context(given_popup, {
      current_winid = 99,
      current_bufnr = 41,
    })
    local expected = false

    assert.are.equal(expected, actual)
  end)

  it("GIVEN the source cursor moves to another line WHEN checking source context THEN it closes", function()
    local actual = mermaid.should_close_popup_for_source_context(given_popup, {
      current_winid = 23,
      current_bufnr = 17,
      current_mode = "n",
      cursor_row = 4,
    })
    local expected = true

    assert.are.equal(expected, actual)
  end)

  it("GIVEN the source enters a non-normal mode WHEN checking source context THEN it closes", function()
    local actual = mermaid.should_close_popup_for_source_context(given_popup, {
      current_winid = 23,
      current_bufnr = 17,
      current_mode = "v",
      cursor_row = 3,
    })
    local expected = true

    assert.are.equal(expected, actual)
  end)

  it("GIVEN the source changes window or buffer WHEN checking source context THEN it closes", function()
    local actual = mermaid.should_close_popup_for_source_context(given_popup, {
      current_winid = 77,
      current_bufnr = 18,
    })
    local expected = true

    assert.are.equal(expected, actual)
  end)
end)

describe("mermaid.source_to_popup_focus_checks", function()
  it("GIVEN both BufLeave and WinLeave fire for an explicit popup focus WHEN tracking the transition THEN both checks are consumed before the popup can close", function()
    local given_popup = {
      winid = 99,
      allow_source_to_popup_focus = true,
      pending_source_to_popup_checks = 0,
    }

    local actual_after_first_note = mermaid.note_source_to_popup_focus_check(given_popup)
    local actual_after_second_note = mermaid.note_source_to_popup_focus_check(given_popup)
    local actual_close_before_first_consume = mermaid.should_close_popup_for_source_window_change(given_popup, 99)
    local actual_after_first_consume = mermaid.consume_source_to_popup_focus_check(given_popup)
    local actual_close_before_second_consume = mermaid.should_close_popup_for_source_window_change(given_popup, 99)
    local actual_after_second_consume = mermaid.consume_source_to_popup_focus_check(given_popup)
    local actual_close_after_second_consume = mermaid.should_close_popup_for_source_window_change(given_popup, 99)

    assert.are.equal(1, actual_after_first_note)
    assert.are.equal(2, actual_after_second_note)
    assert.are.equal(false, actual_close_before_first_consume)
    assert.are.equal(1, actual_after_first_consume)
    assert.are.equal(false, actual_close_before_second_consume)
    assert.are.equal(0, actual_after_second_consume)
    assert.are.equal(true, actual_close_after_second_consume)
    assert.are.equal(false, given_popup.allow_source_to_popup_focus)
  end)
end)

describe("mermaid.should_close_popup_for_source_window_change", function()
  it("GIVEN the source leaves for the popup without a pending focus transition WHEN checking the window change THEN it closes", function()
    local actual = mermaid.should_close_popup_for_source_window_change({
      winid = 99,
      allow_source_to_popup_focus = false,
      pending_source_to_popup_checks = 0,
    }, 99)
    local expected = true

    assert.are.equal(expected, actual)
  end)

  it("GIVEN the source leaves for the popup with a pending focus transition WHEN checking the window change THEN it stays open", function()
    local actual = mermaid.should_close_popup_for_source_window_change({
      winid = 99,
      allow_source_to_popup_focus = true,
      pending_source_to_popup_checks = 2,
    }, 99)
    local expected = false

    assert.are.equal(expected, actual)
  end)
end)

describe("mermaid.render", function()
  it("GIVEN an unsupported diagram family WHEN rendering THEN it falls back to raw source", function()
    local source = table.concat({
      "classDiagram",
      "  Animal <|-- Duck",
    }, "\n")

    local actual, reason = mermaid.render(source)

    assert.are.equal(nil, actual)
    assert.is_truthy(reason:match("unsupported"))
  end)
end)
