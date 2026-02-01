# frozen_string_literal: true

# Extracts script references from Bash commands.
class ScriptReferenceExtractor
  INTERPRETERS = %w[bash sh zsh fish python python3 ruby node perl].freeze

  def extract(command)
    refs = []
    refs.concat(extract_interpreter_refs(command))
    refs.concat(extract_source_refs(command))
    refs.concat(extract_direct_exec_refs(command))
    refs.uniq
  end

  private

  def extract_interpreter_refs(command)
    refs = []
    interp = INTERPRETERS.join('|')
    # Matches: python path/to/script.py (but not -c / -e)
    regex = /(^|[;&|]\s*)(#{interp})\s+(?!-(c|e)\b)(['"]?)([^\s;|&]+)\4/m

    command.scan(regex) do
      token = Regexp.last_match(5)
      next if token.nil? || token.empty? || token.start_with?('-')

      refs << { kind: 'interpreter', token: token }
    end

    refs
  end

  def extract_source_refs(command)
    refs = []
    regex = /(^|[;&|]\s*)(source|\.)\s+(['"]?)([^\s;|&]+)\3/m

    command.scan(regex) do
      token = Regexp.last_match(4)
      next if token.nil? || token.empty? || token.start_with?('-')

      refs << { kind: 'source', token: token }
    end

    refs
  end

  def extract_direct_exec_refs(command)
    refs = []
    # Matches: ./script.sh (first token after a command boundary)
    regex = /(^|[;&|]\s*)(\.\/[^\s;|&]+)/m

    command.scan(regex) do
      token = Regexp.last_match(2)
      next if token.nil? || token.empty?

      refs << { kind: 'direct', token: token }
    end

    refs
  end
end
