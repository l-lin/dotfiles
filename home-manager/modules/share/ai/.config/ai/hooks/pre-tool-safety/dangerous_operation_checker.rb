# frozen_string_literal: true

require_relative 'ai_hook_safety'
require_relative 'script_reference_extractor'

# Checks commands for dangerous operations.
class DangerousOperationChecker
  ALLOWED_SCRIPT_ROOTS = [
    # Project/workdir
    :base_dir,
    # macOS temp roots
    '/tmp',
    '/private/tmp',
    '/var/folders'
  ].freeze

  SCRIPT_EXTRA_SENSITIVE_PATH_SNIPPETS = [
    '/Applications/'
  ].freeze

  PATTERNS = [
    # Destructive filesystem / disk operations
    {
      category: 'destructive_fs',
      reason: 'Blocked: destructive filesystem operation (rm -rf).',
      regex: /(^|[^\w-])rm\s+-[^\n]*\b(rf|fr)\b/i
    },
    {
      category: 'destructive_fs',
      reason: 'Blocked: destructive filesystem operation (git clean -fdx / -fd).',
      regex: /\bgit\s+clean\b[^\n]*\s-([\w-]*f[\w-]*d[\w-]*x?|[\w-]*d[\w-]*f[\w-]*x?)\b/i
    },
    {
      category: 'destructive_disk',
      reason: 'Blocked: destructive disk operation (dd/mkfs/diskutil erase).',
      regex: /(\bdd\b[^\n]*\bof=\/dev\/|\bmkfs(\.|\b)|\bdiskutil\b[^\n]*\berase(disk|volume)?\b)/i
    },
    {
      category: 'destructive_fs',
      reason: 'Blocked: destructive filesystem operation (find -delete).',
      regex: /\bfind\b[^\n]*\s-delete\b/i
    },

    # Privilege escalation / service control
    {
      category: 'privilege',
      reason: 'Blocked: privilege escalation (sudo/su/doas).',
      regex: /(^|[^\w-])(sudo|su|doas)\b/i
    },
    {
      category: 'privilege',
      reason: 'Blocked: service control operation (launchctl/systemctl).',
      regex: /\b(launchctl|systemctl)\b/i
    },

    # Risky git
    {
      category: 'risky_git',
      reason: 'Blocked: risky git operation (push --force / --mirror / --delete).',
      regex: /\bgit\s+push\b[^\n]*\s(--force|-f|--mirror|--delete)\b/i
    },
    {
      category: 'risky_git',
      reason: 'Blocked: risky git operation (reset --hard).',
      regex: /\bgit\s+reset\b[^\n]*\s--hard\b/i
    },
    {
      category: 'risky_git',
      reason: 'Blocked: history-rewriting git operation (filter-repo).',
      regex: /\bgit\s+filter-repo\b/i
    },

    # Secrets handling
    {
      category: 'secrets',
      reason: 'Blocked: potential secrets access (SSH/AWS/GPG/.env/key material).',
      regex: %r{(^|\s)(cat|less|more|head|tail|rg|grep|sed|awk|python|python3|ruby)\b[^\n]*\s(~\/?\.?\w*\/(\.ssh|\.aws|\.gnupg)\b|~\/?\.ssh\b|~\/?\.aws\b|~\/?\.gnupg\b|\b\.env\b|\bid_rsa\b|\bid_ed25519\b|\bcredentials\b|\bkeychain\b|\.pem\b|\.p12\b)}i
    },
    {
      category: 'secrets',
      reason: 'Blocked: keychain/password extraction attempt (security/pass/op).',
      regex: /\b(security\s+find-(generic|internet)-password|pass\b|op\s+read\b)\b/i
    },

    # Network exfil / remote execution
    {
      category: 'network',
      reason: 'Blocked: remote code execution pattern (curl/wget | sh).',
      regex: /\b(curl|wget)\b[^\n]*\|\s*(sh|bash|zsh|python|python3|ruby|node)\b/i
    },
    {
      category: 'network',
      reason: 'Blocked: remote transfer/exfil attempt (scp/rsync/ssh/nc).',
      regex: /\b(scp|rsync|ssh|nc|ncat|socat|telnet)\b/i
    },

    # Obfuscation / eval
    {
      category: 'obfuscation',
      reason: 'Blocked: code execution via eval.',
      regex: /(^|[^\w-])eval\b/i
    },
    {
      category: 'obfuscation',
      reason: 'Blocked: obfuscated execution (base64 decode piped to a shell).',
      regex: /\b(base64)\b[^\n]*\b(-d|--decode)\b[^\n]*\|\s*(sh|bash|zsh)\b/i
    }
  ].freeze

  INLINE_CODE_PATTERNS = [
    { lang: 'bash', regex: /\b(bash|sh|zsh)\s+-c\s+(['"])(.*?)\2/im },
    { lang: 'python', regex: /\b(python|python3)\s+-c\s+(['"])(.*?)\2/im },
    { lang: 'ruby', regex: /\bruby\s+-e\s+(['"])(.*?)\1/im },
    { lang: 'node', regex: /\bnode\s+-e\s+(['"])(.*?)\1/im }
  ].freeze

  def initialize(base_dir:, max_script_bytes:)
    @base_dir = base_dir
    @max_script_bytes = max_script_bytes
  end

  def check(command)
    findings = []

    findings.concat(scan_text(command, origin: 'command'))
    findings.concat(scan_inline_code(command))
    findings.concat(scan_referenced_scripts(command))

    findings
  end

  private

  def scan_text(text, origin:)
    PATTERNS.each_with_object([]) do |p, acc|
      next unless p[:regex].match?(text)

      acc << { category: p[:category], reason: p[:reason], origin: origin }
    end
  end

  def scan_inline_code(command)
    INLINE_CODE_PATTERNS.flat_map do |p|
      command.to_enum(:scan, p[:regex]).flat_map do
        code = Regexp.last_match(3) || Regexp.last_match(2)
        scan_text(code.to_s, origin: "inline_#{p[:lang]}")
      end
    end
  end

  def scan_referenced_scripts(command)
    refs = ScriptReferenceExtractor.new.extract(command)
    refs.flat_map { |ref| inspect_script_ref(ref, command: command) }
  end

  def inspect_script_ref(ref, command:)
    token = ref[:token]
    kind = ref[:kind]

    return [{ category: 'scripts', origin: kind, reason: 'Blocked: dynamic script execution is not allowed.' }] if token.match?(/[\$`*?]/)
    return [] if created_in_same_command?(command, token)

    abs = resolve_path(token)
    return [{ category: 'scripts', origin: kind, reason: 'Blocked: unable to resolve script path.' }] unless abs
    return [{ category: 'scripts', origin: kind, reason: 'Blocked: executing scripts from sensitive paths is not allowed.' }] if sensitive_path?(abs)
    return [{ category: 'scripts', origin: kind, reason: 'Blocked: executing scripts outside the workspace/temp roots is not allowed.' }] unless allowed_script_root?(abs)
    return [{ category: 'scripts', origin: kind, reason: 'Blocked: referenced script does not exist (cannot inspect safely).' }] unless File.file?(abs)
    return [{ category: 'scripts', origin: kind, reason: 'Blocked: referenced script is too large to inspect safely.' }] if File.size(abs) > @max_script_bytes

    content = File.read(abs, mode: 'rb')
    findings = scan_text(content, origin: "script:#{abs}")
    findings.empty? ? [] : findings
  rescue StandardError
    [{ category: 'scripts', origin: kind, reason: 'Blocked: failed to inspect referenced script.' }]
  end

  def resolve_path(token)
    expanded = token
    expanded = expanded[1..-2] if (expanded.start_with?("\"") && expanded.end_with?("\"")) || (expanded.start_with?("'") && expanded.end_with?("'"))
    return nil if expanded.empty?

    if expanded.start_with?('~/') || expanded == '~'
      File.expand_path(expanded)
    elsif expanded.start_with?('/')
      expanded
    else
      File.expand_path(expanded, @base_dir)
    end
  rescue StandardError
    nil
  end

  def sensitive_path?(abs)
    AiHookSafety.sensitive_path?(abs, extra_snippets: SCRIPT_EXTRA_SENSITIVE_PATH_SNIPPETS)
  end

  def allowed_script_root?(abs)
    abs = File.expand_path(abs)

    ALLOWED_SCRIPT_ROOTS.any? do |root|
      root_path = (root == :base_dir) ? @base_dir : root
      root_abs = File.expand_path(root_path)
      abs == root_abs || abs.start_with?(root_abs + File::SEPARATOR)
    end
  rescue StandardError
    false
  end

  def created_in_same_command?(command, token)
    t = Regexp.escape(token)
    # If the command redirects output into the token path, we assume the script
    # body is present in the command string and rely on scanning the full command
    # text instead of reading the file (not yet created).
    command.match?(/(>|>>|\|\s*tee\s)\s*(['"])?#{t}\2(\s|;|&&|\|\||$)/)
  end
end
