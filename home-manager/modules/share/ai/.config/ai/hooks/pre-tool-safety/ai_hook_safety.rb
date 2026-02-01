# frozen_string_literal: true

# Module for AI hook safety checks.
module AiHookSafety
  BASE_SENSITIVE_PATH_SNIPPETS = [
    '/.ssh/',
    '/.aws/',
    '/.gnupg/',
    '/Library/Keychains',
    '/System/Library',
    '/etc/',
    '/private/etc/',
    '/var/db/',
    '/System/',
    '/usr/bin/',
    '/usr/sbin/',
    '/bin/',
    '/sbin/'
  ].freeze

  READ_EXTRA_SENSITIVE_PATH_SNIPPETS = [
    '/.config/zsh/secrets/',
    '/.config/dotfiles/secrets/',
    '/.claude/'
  ].freeze

  SENSITIVE_BASENAMES = %w[
    id_rsa
    id_ed25519
    id_dsa
    id_ecdsa
    authorized_keys
    known_hosts
    config
    credentials
    .env
    .env.local
    .env.production
    .secrets.ai
  ].freeze

  KEY_MATERIAL_EXT_REGEX = /\.(pem|p12|pfx|key)$/i.freeze

  class << self
    def sensitive_path?(abs_path, extra_snippets: [])
      p = abs_path.to_s
      return true if p.include?('/.git/')

      (BASE_SENSITIVE_PATH_SNIPPETS + Array(extra_snippets)).any? { |s| p.include?(s) }
    end

    def sensitive_basename?(basename)
      SENSITIVE_BASENAMES.include?(basename)
    end
  end
end
