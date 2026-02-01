# frozen_string_literal: true

require 'minitest/autorun'

require_relative '../ai_hook_safety'

class TestAiHookSafety < Minitest::Test
  def test_sensitive_path_true_for_base_snippets
    assert AiHookSafety.sensitive_path?('/Users/me/.ssh/id_ed25519')
    assert AiHookSafety.sensitive_path?('/etc/hosts')
  end

  def test_sensitive_path_true_for_git_dir
    assert AiHookSafety.sensitive_path?('/Users/me/project/.git/config')
  end

  def test_sensitive_path_false_for_normal_paths
    refute AiHookSafety.sensitive_path?('/Users/me/project/README.md')
  end

  def test_sensitive_path_respects_extra_snippets
    refute AiHookSafety.sensitive_path?('/Users/me/project/secrets.txt')
    assert AiHookSafety.sensitive_path?('/Users/me/project/secrets.txt', extra_snippets: ['/project/'])
  end

  def test_sensitive_basename
    assert AiHookSafety.sensitive_basename?('id_rsa')
    assert AiHookSafety.sensitive_basename?('.env')
    refute AiHookSafety.sensitive_basename?('README.md')
  end
end
