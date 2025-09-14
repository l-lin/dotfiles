#
# A dynamic, open source programming language with a focus on simplicity and
# productivity. It has an elegant syntax that is natural to read and easy to
# write.
# src: https://www.ruby-lang.org/en/
#

{
  # home.sessionVariables = {
  #   # auto-detect Gemfile in the current or parent directory, to avoid prefixing
  #   # all ruby/gem commands with "bundle exec" src:
  #   # https://ruby-doc.org/3.3.5/stdlibs/rubygems/Gem.html
  #   RUBYGEMS_GEMDEPS = "-";
  # };

  xdg.configFile."mise/conf.d/ruby.toml".source = ./.config/mise/conf.d/ruby.toml;

  # NOTE: I currently don't need to publish any gems. So no need to set secrets.
  #xdg.configFile."zsh/secrets/.secrets.ruby".source = ./.config/zsh/secrets/.secrets.ruby;
}
