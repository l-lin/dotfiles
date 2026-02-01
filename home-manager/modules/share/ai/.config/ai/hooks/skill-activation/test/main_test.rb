# frozen_string_literal: true

require 'json'
require 'minitest/autorun'
require 'open3'
require 'tmpdir'
require 'fileutils'

class SkillActivationMainTest < Minitest::Test
  SCRIPT = File.expand_path('../main.rb', __dir__)

  def test_prints_activation_output_when_rule_matches
    Dir.mktmpdir do |dir|
      rules_dir = File.join(dir, '.ai', 'skills')
      FileUtils.mkdir_p(rules_dir)
      File.write(
        File.join(rules_dir, 'skill-rules.json'),
        JSON.pretty_generate({
                               'skills' => {
                                 'coding-style' => {
                                   'priority' => 'critical',
                                   'promptTriggers' => { 'keywords' => ['tdd'] }
                                 }
                               }
                             })
      )

      stdin = JSON.generate({ 'prompt' => 'Please use TDD for this.' })
      stdout, stderr, status = Open3.capture3('ruby', SCRIPT, chdir: dir, stdin_data: stdin)

      assert_equal 0, status.exitstatus
      assert_equal '', stderr
      assert_includes stdout, 'SKILL ACTIVATION CHECK'
      assert_includes stdout, 'coding-style'
    end
  end

  def test_prints_nothing_when_no_rule_matches
    Dir.mktmpdir do |dir|
      rules_dir = File.join(dir, '.ai', 'skills')
      FileUtils.mkdir_p(rules_dir)
      File.write(
        File.join(rules_dir, 'skill-rules.json'),
        JSON.pretty_generate({
                               'skills' => {
                                 'coding-style' => {
                                   'priority' => 'critical',
                                   'promptTriggers' => { 'keywords' => ['tdd'] }
                                 }
                               }
                             })
      )

      stdin = JSON.generate({ 'prompt' => 'No relevant keyword here.' })
      stdout, stderr, status = Open3.capture3('ruby', SCRIPT, chdir: dir, stdin_data: stdin)

      assert_equal 0, status.exitstatus
      assert_equal '', stderr
      assert_equal '', stdout
    end
  end

  def test_exits_1_on_invalid_json
    _stdout, _stderr, status = Open3.capture3('ruby', SCRIPT, stdin_data: '{')
    assert_equal 1, status.exitstatus
  end
end
