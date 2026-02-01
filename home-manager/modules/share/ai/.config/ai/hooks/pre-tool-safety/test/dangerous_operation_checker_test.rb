# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'

require_relative '../dangerous_operation_checker'

class DangerousOperationCheckerTest < Minitest::Test
  def test_flags_rm_rf
    checker = DangerousOperationChecker.new(base_dir: Dir.pwd, max_script_bytes: 1024)
    findings = checker.check('rm -rf /tmp/foo')

    refute_empty findings
    assert_match(/rm -rf/i, findings.first[:reason])
  end

  def test_flags_inline_python_c_code
    checker = DangerousOperationChecker.new(base_dir: Dir.pwd, max_script_bytes: 1024)
    findings = checker.check('python3 -c "import os; os.system(\"rm -rf /tmp/foo\")"')

    refute_empty findings
  end

  def test_blocks_dynamic_script_tokens
    checker = DangerousOperationChecker.new(base_dir: Dir.pwd, max_script_bytes: 1024)
    findings = checker.check('bash $SOME_SCRIPT')

    refute_empty findings
    assert_equal 'scripts', findings.first[:category]
  end

  def test_flags_danger_inside_referenced_script
    Dir.mktmpdir do |dir|
      script_path = File.join(dir, 'run.sh')
      File.write(script_path, "#!/usr/bin/env bash\nrm -rf /tmp/foo\n")

      checker = DangerousOperationChecker.new(base_dir: dir, max_script_bytes: 1024)
      findings = checker.check('./run.sh')

      refute_empty findings
      assert findings.any? { |f| f[:origin].to_s.include?('script:') }
    end
  end

  def test_allows_safe_command
    checker = DangerousOperationChecker.new(base_dir: Dir.pwd, max_script_bytes: 1024)
    assert_empty checker.check('echo hello')
  end
end
