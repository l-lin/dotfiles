#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

require_relative 'pre_tool_safety'

begin
  # `input` contains the following JSON structure:
  # For Read tool:
  #   {
  #     "session_id":"4799f662-62cd-45b8-9bca-f3ea3b0d529c",
  #     "transcript_path":"/Users/me/.claude/projects/-Users-me-tmp-foobar/4799f662-62cd-45b8-9bca-f3ea3b0d529c.jsonl",
  #     "cwd":"/Users/me/tmp/foobar",
  #     "permission_mode":"default","
  #     "hook_event_name":"PreToolUse",
  #     "tool_name":"Read",
  #     "tool_input":{ "file_path":"/Users/me/.ssh/ed_25519" },
  #     "tool_use_id":"toolu_0186ckJbp9hdZfmiYugjQBEX"
  #   }
  # For Bash tool:
  #   {
  #     "session_id":"749af212-c761-4f42-8554-7df83cbe7872",
  #     "transcript_path":"/Users/me/.claude/projects/-Users-me-tmp-foobar/749af212-c761-4f42-8554-7df83cbe7872.jsonl",
  #     "cwd":"/Users/me/tmp/foobar",
  #     "permission_mode":"default",
  #     "hook_event_name":"PreToolUse",
  #     "tool_name":"Bash",
  #     "tool_input": {
  #       "command": "cat ~/.ssh/codeberg.pub",
  #       "description": "Read Codeberg public SSH key"
  #     },
  #     "tool_use_id":"toolu_01JhuMmF2efV8UWzMverCD8h"
  #   }
  input = $stdin.read
  File.write('/tmp/pre-tool-safety-input.cmd.json', input)
  data = JSON.parse(input)
  PreToolSafety.new(data).run
rescue JSON::ParserError
  warn 'pre-tool-safety: invalid JSON input'
  exit 2
rescue StandardError => e
  warn "pre-tool-safety: #{e.class}: #{e.message}"
  exit 2
end
