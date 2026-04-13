local markdown = require("functions.lang.markdown")

describe("markdown.bold_current_line", function()
  local original_vim

  local function given_vim_state(line, cursor_column)
    local current_line = line
    local current_cursor = { 1, cursor_column or 0 }

    _G.vim = {
      api = {
        nvim_get_current_line = function()
          return current_line
        end,
        nvim_set_current_line = function(updated_line)
          current_line = updated_line
        end,
        nvim_win_get_cursor = function()
          return { current_cursor[1], current_cursor[2] }
        end,
        nvim_win_set_cursor = function(_, updated_cursor)
          current_cursor = { updated_cursor[1], updated_cursor[2] }
        end,
      },
    }

    return function()
      return current_line, current_cursor
    end
  end

  before_each(function()
    original_vim = _G.vim
  end)

  after_each(function()
    _G.vim = original_vim
  end)

  it("GIVEN plain text WHEN bold_current_line runs THEN it wraps the whole line in bold markers", function()
    local then_state = given_vim_state("Important note", 4)

    markdown.bold_current_line()

    local actual_line, actual_cursor = then_state()
    local expected_line = "**Important note**"
    local expected_cursor = { 1, 6 }

    assert.are.equal(expected_line, actual_line)
    assert.are.same(expected_cursor, actual_cursor)
  end)

  it("GIVEN a blank line WHEN bold_current_line runs THEN it leaves the line unchanged", function()
    local then_state = given_vim_state("", 0)

    markdown.bold_current_line()

    local actual_line, actual_cursor = then_state()
    local expected_line = ""
    local expected_cursor = { 1, 0 }

    assert.are.equal(expected_line, actual_line)
    assert.are.same(expected_cursor, actual_cursor)
  end)

  it("GIVEN an already bold line WHEN bold_current_line runs THEN it does not double wrap the line", function()
    local then_state = given_vim_state("**Important note**", 5)

    markdown.bold_current_line()

    local actual_line, actual_cursor = then_state()
    local expected_line = "**Important note**"
    local expected_cursor = { 1, 5 }

    assert.are.equal(expected_line, actual_line)
    assert.are.same(expected_cursor, actual_cursor)
  end)
end)
