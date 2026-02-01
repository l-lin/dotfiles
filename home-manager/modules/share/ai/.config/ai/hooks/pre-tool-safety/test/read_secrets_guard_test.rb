# frozen_string_literal: true

require 'minitest/autorun'

require_relative '../read_secrets_guard'

class ReadSecretsGuardTest < Minitest::Test
  def test_blocks_sensitive_path
    actual = ReadSecretsGuard.new.check('/Users/me/.ssh/id_ed25519')
    refute_nil actual
    assert_equal 'secrets', actual[:category]
    assert_equal 'Read', actual[:origin]
  end

  def test_blocks_sensitive_basename
    actual = ReadSecretsGuard.new.check('tmp/.env')
    refute_nil actual
    assert_match(/likely secret/i, actual[:reason])
  end

  def test_blocks_key_material_extension
    actual = ReadSecretsGuard.new.check('certs/server.pem')
    refute_nil actual
    assert_match(/key\/cert/i, actual[:reason])
  end

  def test_allows_normal_file
    assert_nil ReadSecretsGuard.new.check('docs/README.md')
  end
end
