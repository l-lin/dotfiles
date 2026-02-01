# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require 'open3'

class MainEntrypointTest < Minitest::Test
  SCRIPT = File.expand_path('../main.rb', __dir__)

  def test_invalid_json_exits_2
    _stdout, stderr, status = Open3.capture3('ruby', SCRIPT, stdin_data: '{')

    assert_equal 2, status.exitstatus
    assert_match(/invalid json/i, stderr)
  end

  def test_denies_sensitive_read_with_json_output
    stdin = JSON.generate({
      'hook_event_name' => 'PreToolUse',
      'tool_name' => 'Read',
      'tool_input' => { 'file_path' => '/Users/me/.ssh/id_ed25519' }
    })

    stdout, stderr, status = Open3.capture3('ruby', SCRIPT, stdin_data: stdin)

    assert_equal '', stderr
    assert_equal 2, status.exitstatus

    actual = JSON.parse(stdout)
    hso = actual.fetch('hookSpecificOutput')
    assert_equal 'PreToolUse', hso.fetch('hookEventName')
    assert_equal 'deny', hso.fetch('permissionDecision')
    assert_match(/read/i, hso.fetch('permissionDecisionReason'))
  end

  def test_allows_safe_bash_command
    stdin = JSON.generate({
      'hook_event_name' => 'PreToolUse',
      'tool_name' => 'Bash',
      'cwd' => Dir.pwd,
      'tool_input' => { 'command' => 'echo hello' }
    })

    stdout, stderr, status = Open3.capture3('ruby', SCRIPT, stdin_data: stdin)

    assert_equal '', stderr
    assert_equal 0, status.exitstatus
    assert_equal '', stdout
  end
end
