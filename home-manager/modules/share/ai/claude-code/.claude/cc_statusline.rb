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
#   "context_window": {
#     "total_input_tokens": 300,
#     "total_output_tokens": 144,
#     "context_window_size": 200000,
#     "current_usage": {
#       "input_tokens": 10,
#       "output_tokens": 127,
#       "cache_creation_input_tokens": 7177,
#       "cache_read_input_tokens": 17029
#     },
#     "used_percentage": 12,
#     "remaining_percentage": 88
#   },
#   "exceeds_200k_tokens": false,
#   "vim": {
#     "mode": "INSERT"
#   }
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

def format_context_length(context_length, context_percentage)
  formatted = context_length >= 1000 ? (context_length / 1000).to_s + "K" : context_length.to_s

  if context_percentage < 50_000
    "#{GREEN} #{formatted}(#{context_percentage}%)#{RESET}"
  elsif context_length < 100_000
    "#{ORANGE} #{formatted}(#{context_percentage}%)#{RESET}"
  else
    "#{RED} #{formatted}(#{context_percentage}%)#{RESET}"
  end
end

def format_cwd(cwd)
  "#{BLUE} #{cwd.split("/").last}#{RESET}"
end

def format_model(model_id)
  "#{BLUE}󰚩 #{model_id}#{RESET}"
end

def format_cost(total_cost_usd)
  formatted = "$%.4f" % total_cost_usd
  if total_cost_usd < 1
    "#{GREEN} #{formatted}#{RESET}"
  elsif total_cost_usd < 3
    "#{ORANGE} #{formatted}#{RESET}"
  else
    "#{RED} #{formatted}#{RESET}"
  end
end

begin
  input = STDIN.read
  data = JSON.parse(input)

  transcript_path = data["transcript_path"]

  cwd = data["cwd"].split("/").last
  context_length = compute_context_length(transcript_path)
  context_percentage = data.dig('context_window', 'used_percentage') || 0

  model_id = data.dig('model', 'id') || 'unknown'
  total_cost_usd = data.dig('cost', 'total_cost_usd') || 0.0

  puts "#{RESET}#{format_cwd(cwd)} #{format_model(model_id)} #{format_context_length(context_length, context_percentage)} #{format_cost(total_cost_usd)}"
rescue => e
  puts "#{RESET}#{RED}ERROR: #{e.message}#{RESET}"
end
