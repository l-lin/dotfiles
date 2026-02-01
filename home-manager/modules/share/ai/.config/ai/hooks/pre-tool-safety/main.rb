#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

require_relative 'pre_tool_safety'

begin
  input = $stdin.read
  data = JSON.parse(input)
  PreToolSafety.new(data).run
rescue JSON::ParserError
  warn 'pre-tool-safety: invalid JSON input'
  exit 2
rescue StandardError => e
  warn "pre-tool-safety: #{e.class}: #{e.message}"
  exit 2
end
