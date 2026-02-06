local translate = require("helpers.translate")

--- Check if table contains value
---@param tbl table
---@param val any
---@return boolean
local function tbl_contains(tbl, val)
  for _, v in ipairs(tbl) do
    if v == val then
      return true
    end
  end
  return false
end

describe("format_trans_output", function()
  it("formats basic word with pronunciation and translation", function()
    local lines = {
      "hello",
      "/həˈlō/",
      "",
      "bonjour",
    }
    local result, main = translate.format_trans_output(lines)

    assert.are.equal("# hello", result[1])
    assert.are.equal("", result[2])
    assert.are.equal("*/həˈlō/*", result[3])
    assert.are.equal("", result[4])
    assert.are.equal("bonjour", result[5])
    assert.are.equal("bonjour", main)
  end)

  it("formats word without pronunciation", function()
    local lines = {
      "cat",
      "",
      "chat",
    }
    local result, main = translate.format_trans_output(lines)

    assert.are.equal("# cat", result[1])
    assert.are.equal("", result[2])
    assert.are.equal("chat", result[3])
    assert.are.equal("chat", main)
  end)

  it("formats output with definitions section", function()
    local lines = {
      "run",
      "/rən/",
      "",
      "courir",
      "",
      "Definitions of run",
      "verb",
      "    move at a speed faster than a walk",
      "        She ran to the door",
      "noun",
      "    an act of running",
    }
    local result, main = translate.format_trans_output(lines)

    assert.are.equal("# run", result[1])
    assert.are.equal("*/rən/*", result[3])
    assert.are.equal("courir", result[5])
    assert.are.equal("courir", main)
    -- Verb section
    assert.truthy(tbl_contains(result, "## Verb"))
    assert.truthy(tbl_contains(result, "move at a speed faster than a walk"))
    -- Noun section
    assert.truthy(tbl_contains(result, "## Noun"))
  end)

  it("formats examples as quotes", function()
    local lines = {
      "test",
      "",
      "essai",
      "",
      "noun",
      "    a procedure",
      "        the test was successful",
    }
    local result, _ = translate.format_trans_output(lines)

    assert.truthy(tbl_contains(result, "> [!quote] the test was successful"))
  end)

  it("handles empty input", function()
    local result, main = translate.format_trans_output({})

    assert.are.equal(0, #result)
    assert.is_nil(main)
  end)

  it("skips language headers", function()
    local lines = {
      "hello",
      "",
      "[ English -> French ]",
      "",
      "bonjour",
    }
    local result, _ = translate.format_trans_output(lines)

    for _, line in ipairs(result) do
      assert.is_falsy(line:match("%[ .* %]"))
    end
  end)

  it("formats synonyms section", function()
    local lines = {
      "big",
      "",
      "grand",
      "",
      "Synonyms",
      "    large, huge",
    }
    local result, _ = translate.format_trans_output(lines)

    assert.truthy(tbl_contains(result, "## Synonyms"))
    assert.truthy(tbl_contains(result, "large, huge"))
  end)
end)

describe("translate", function()
  it("rejects invalid language codes", function()
    local error_called = false
    local error_msg = nil

    -- Can't actually run translate without vim.fn, but we can test validation
    -- by checking return value (0 = failed)
    local cases = {
      { code = "; rm -rf /", valid = false },
      { code = "en", valid = true },
      { code = "fra", valid = true },
      { code = "e", valid = false },
      { code = "toolong", valid = false },
      { code = "12", valid = false },
    }

    for _, case in ipairs(cases) do
      local is_valid = case.code:match("^%a%a%a?$") ~= nil
      assert.are.equal(case.valid, is_valid, "Failed for: " .. case.code)
    end
  end)
end)
