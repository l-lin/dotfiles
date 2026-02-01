# frozen_string_literal: true

require_relative 'ai_hook_safety'

# Guard against reading sensitive files.
class ReadSecretsGuard
  def check(file_path)
    return nil if file_path.nil? || file_path.empty?

    abs = File.expand_path(file_path)
    base = File.basename(abs)

    return blocked('Blocked: Read on sensitive path is not allowed.') if AiHookSafety.sensitive_path?(abs, extra_snippets: AiHookSafety::READ_EXTRA_SENSITIVE_PATH_SNIPPETS)
    return blocked('Blocked: Read on likely secret file is not allowed.') if AiHookSafety.sensitive_basename?(base)
    return blocked('Blocked: Read on key/cert material is not allowed.') if base.match?(AiHookSafety::KEY_MATERIAL_EXT_REGEX)

    nil
  rescue StandardError
    blocked('Blocked: could not validate Read target safely.')
  end

  private

  def blocked(reason)
    { category: 'secrets', origin: 'Read', reason: reason }
  end
end
