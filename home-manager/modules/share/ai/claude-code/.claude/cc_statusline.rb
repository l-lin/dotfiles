#!/usr/bin/env ruby
#
# Generate claude-code statusline.
#
# The input's format is:
#
# ```json
# {
#   "hook_event_name": "Status",
#   "session_id": "abc123...",
#   "transcript_path": "/path/to/transcript.json",
#   "cwd": "/current/working/directory",
#   "model": {
#     "id": "claude-opus-4-1",
#     "display_name": "Opus"
#   },
#   "workspace": {
#     "current_dir": "/current/working/directory",
#     "project_dir": "/original/project/directory"
#   },
#   "version": "1.0.80",
#   "output_style": {
#     "name": "default"
#   },
#   "cost": {
#     "total_cost_usd": 0.01234,
#     "total_duration_ms": 45000,
#     "total_api_duration_ms": 2300,
#     "total_lines_added": 156,
#     "total_lines_removed": 23
#   }
# }
# ```
# src: https://code.claude.com/docs/en/statusline#available-data
#

require("json")

RED = "\e[31m"
GREEN = "\e[32m"
ORANGE = "\e[33m"
BLUE = "\e[34m"
GREY = "\e[37m"
RESET = "\e[0m"

def compute_context_length(transcript_path)
  return 0 unless File.exist?(transcript_path)

  last_assistant_entry = File.foreach(transcript_path)
    .map { |line| JSON.parse(line.strip) }
    .reverse
    .find { |entry| entry.dig("message", "role") == "assistant" && entry.dig("message", "usage", "input_tokens").is_a?(Integer) }

  input_tokens = last_assistant_entry&.dig("message", "usage", "input_tokens") || 0
  cache_creation_input_tokens = last_assistant_entry&.dig("message", "usage", "cache_creation_input_tokens") || 0
  cache_read_input_tokens = last_assistant_entry&.dig("message", "usage", "cache_read_input_tokens") || 0

  input_tokens + cache_creation_input_tokens + cache_read_input_tokens
end

def format_context_length(context_length)
  formatted = context_length >= 1000 ? (context_length / 1000).to_s + "K" : context_length.to_s

  if context_length < 50000
    "#{GREEN} #{formatted}#{RESET}"
  elsif context_length < 100000
    "#{ORANGE} #{formatted}#{RESET}"
  else
    "#{RED} #{formatted}#{RESET}"
  end
end

def format_cwd(cwd)
  "#{BLUE} #{cwd.split("/").last}#{RESET}"
end

def format_model(model_id)
  "#{GREY}󰚩 #{model_id}#{RESET}"
end

def format_cost(total_cost_usd)
  formatted = "$%.4f" % total_cost_usd
  "#{RED} #{formatted}#{RESET}"
end

begin
  input = STDIN.read
  data = JSON.parse(input)

  transcript_path = data["transcript_path"]

  cwd = data["cwd"].split("/").last
  context_length = compute_context_length(transcript_path)

  model_id = data.dig('model', 'id') || 'unknown'
  total_cost_usd = data.dig('cost', 'total_cost_usd') || 0.0

  puts "#{RESET}#{format_cwd(cwd)} #{format_context_length(context_length)} #{format_model(model_id)} #{format_cost(total_cost_usd)}"
rescue => e
  puts "#{RESET}#{RED}ERROR: #{e.message}#{RESET}"
end
