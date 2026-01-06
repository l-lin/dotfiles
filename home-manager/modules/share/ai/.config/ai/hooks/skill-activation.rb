#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

# Matches configured skill triggers against the incoming prompt and prints
# an activation hint when relevant.
class SkillActivationPrompt
  def initialize(input_data)
    @data = input_data
    @prompt = @data['prompt'].downcase
  end

  def run
    rules = load_skill_rules
    matched_skills = find_matched_skills(rules)

    print_output(matched_skills) if matched_skills.any?
  end

  private

  def load_skill_rules
    rules_path = File.join(ENV['HOME'], '.config', 'ai', 'skills', 'skill-rules.json')
    JSON.parse(File.read(rules_path))
  end

  def find_matched_skills(rules)
    rules.fetch('skills', {}).each_with_object([]) do |(skill_name, config), matched|
      triggers = config['promptTriggers']
      next unless triggers

      match = match_for_triggers(triggers)
      next unless match

      matched << { name: skill_name, match_type: match[:type], config: config }
    end
  end

  def match_for_triggers(triggers)
    return { type: 'keyword' } if keyword_match?(triggers)
    return { type: 'intent' } if intent_match?(triggers)

    nil
  end

  def keyword_match?(triggers)
    triggers['keywords']&.any? { |kw| @prompt.include?(kw.downcase) }
  end

  def intent_match?(triggers)
    triggers['intentPatterns']&.any? do |pattern|
      Regexp.new(pattern, Regexp::IGNORECASE).match?(@prompt)
    end
  end

  def print_output(matched_skills)
    grouped = group_by_priority(matched_skills)

    output = header_output
    output += priority_section_output(grouped, 'critical', '⚠️ CRITICAL SKILLS (REQUIRED):')
    output += priority_section_output(grouped, 'high', '📚 RECOMMENDED SKILLS:')
    output += priority_section_output(grouped, 'medium', '💡 SUGGESTED SKILLS:')
    output += priority_section_output(grouped, 'low', '📌 OPTIONAL SKILLS:')
    output += footer_output

    puts output
  end

  def header_output
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" \
      "🎯 SKILL ACTIVATION CHECK\n" \
      "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
  end

  def footer_output
    "ACTION: Use Skill tool BEFORE responding\n" \
      "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
  end

  def group_by_priority(matched_skills)
    matched_skills.group_by { |s| s[:config]['priority'] }
  end

  def priority_section_output(grouped_skills, priority, title)
    skills = grouped_skills.fetch(priority, [])
    return '' if skills.empty?

    output = "#{title}\n"
    skills.each { |s| output += "  → #{s[:name]}\n" }
    "#{output}\n"
  end
end

begin
  input = $stdin.read
  data = JSON.parse(input)
  SkillActivationPrompt.new(data).run
  exit 0
rescue StandardError => e
  warn "Error in skill-activation-prompt hook: #{e.message}"
  exit 1
end
