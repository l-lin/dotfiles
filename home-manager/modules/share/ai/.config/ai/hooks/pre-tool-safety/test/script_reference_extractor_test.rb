# frozen_string_literal: true

require 'minitest/autorun'

require_relative '../script_reference_extractor'

class ScriptReferenceExtractorTest < Minitest::Test
  def test_extracts_interpreter_script_path
    command = 'python3 scripts/do_thing.py --flag'
    actual = ScriptReferenceExtractor.new.extract(command)

    assert_includes actual, { kind: 'interpreter', token: 'scripts/do_thing.py' }
  end

  def test_does_not_treat_dash_c_as_script_file
    command = 'python3 -c "print(123)"'
    actual = ScriptReferenceExtractor.new.extract(command)

    refute actual.any? { |h| h[:kind] == 'interpreter' }
  end

  def test_extracts_source_refs
    command = 'source ./env.sh && . ./other.sh'
    actual = ScriptReferenceExtractor.new.extract(command)

    assert_includes actual, { kind: 'source', token: './env.sh' }
    assert_includes actual, { kind: 'source', token: './other.sh' }
  end

  def test_extracts_direct_exec_refs
    command = './bin/run-me --x; echo ok'
    actual = ScriptReferenceExtractor.new.extract(command)

    assert_includes actual, { kind: 'direct', token: './bin/run-me' }
  end

  def test_dedupes_refs
    command = 'python3 scripts/a.py && python3 scripts/a.py'
    actual = ScriptReferenceExtractor.new.extract(command)

    assert_equal 1, actual.count { |h| h == { kind: 'interpreter', token: 'scripts/a.py' } }
  end
end
