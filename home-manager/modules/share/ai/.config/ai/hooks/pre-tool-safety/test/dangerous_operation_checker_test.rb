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

  def test_allows_mvnw_despite_rm_rf_in_content
    # GIVEN: a project with an mvnw that internally uses rm -rf (standard Maven Wrapper behaviour)
    Dir.mktmpdir do |dir|
      mvnw_path = File.join(dir, 'mvnw')
      File.write(mvnw_path, "#!/usr/bin/env bash\nrm -rf \"$MAVEN_WRAPPER_DIR\"\n")
      File.chmod(0o755, mvnw_path)

      checker = DangerousOperationChecker.new(base_dir: dir, max_script_bytes: 65_536)

      # WHEN: the agent runs a Maven test via the wrapper
      command = "cd #{dir} && ./mvnw surefire:test -Dtest=AccountMasterPatientTest -pl account/domain -Dsurefire.failIfNoSpecifiedTests=false --no-transfer-progress 2>&1 | tail -15"
      findings = checker.check(command)

      # THEN: it is allowed — rm -rf inside mvnw is normal housekeeping, not an attack
      assert_empty findings, "Expected no findings for mvnw but got: #{findings.map { |f| f[:reason] }}"
    end
  end

  def test_allows_gradlew_despite_rm_rf_in_content
    # GIVEN: a project with a gradlew that internally uses rm -rf (standard Gradle Wrapper behaviour)
    Dir.mktmpdir do |dir|
      gradlew_path = File.join(dir, 'gradlew')
      File.write(gradlew_path, "#!/usr/bin/env bash\nrm -rf \"$GRADLE_WRAPPER_DIR\"\n")
      File.chmod(0o755, gradlew_path)

      checker = DangerousOperationChecker.new(base_dir: dir, max_script_bytes: 65_536)

      # WHEN: the agent runs a Gradle task via the wrapper
      command = './gradlew test'
      findings = checker.check(command)

      # THEN: it is allowed — rm -rf inside gradlew is normal housekeeping, not an attack
      assert_empty findings, "Expected no findings for gradlew but got: #{findings.map { |f| f[:reason] }}"
    end
  end
end
