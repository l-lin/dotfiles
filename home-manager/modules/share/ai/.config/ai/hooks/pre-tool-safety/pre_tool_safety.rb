# frozen_string_literal: true

require 'json'

require_relative 'dangerous_operation_checker'
require_relative 'read_secrets_guard'

# Main class for pre-tool safety checks.
class PreToolSafety
  MAX_SCRIPT_BYTES = 512 * 1024

  def initialize(input)
    @data = input
  end

  def run
    return allow unless pre_tool_use?

    return check_read if read_tool?
    return allow unless bash_tool?

    cwd = (@data['cwd'].is_a?(String) && !@data['cwd'].empty?) ? @data['cwd'] : Dir.pwd
    command = @data.dig('tool_input', 'command').to_s

    checker = DangerousOperationChecker.new(base_dir: cwd, max_script_bytes: MAX_SCRIPT_BYTES)
    findings = checker.check(command)
    return allow if findings.empty?

    deny(findings.first)
  end

  private

  def pre_tool_use?
    @data['hook_event_name'] == 'PreToolUse'
  end

  def bash_tool?
    @data['tool_name'] == 'Bash'
  end

  def read_tool?
    @data['tool_name'] == 'Read'
  end

  def check_read
    file_path = @data.dig('tool_input', 'file_path').to_s
    finding = ReadSecretsGuard.new.check(file_path)
    return allow unless finding

    deny(finding)
  end

  def allow
    exit 0
  end

  def deny(finding)
    output = {
      'hookSpecificOutput' => {
        'hookEventName' => 'PreToolUse',
        'permissionDecision' => 'deny',
        'permissionDecisionReason' => finding[:reason]
      }
    }
    puts JSON.generate(output)
    exit 2
  end
end
