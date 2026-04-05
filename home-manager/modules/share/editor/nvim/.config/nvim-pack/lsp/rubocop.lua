-- INFO: rubocop is using some cache, so you might have to clear cache with the following
-- command if some config file are not found:
--   rm -rf $XDG_CACHE_HOME/501/rubocop_cache/
-- You can check which config files are used by executing the following command:
--   bundle exec rubocop --debug
return {
  cmd = { "rubocop", "--lsp" },
  filetypes = { "ruby" },
  root_markers = { "Gemfile", ".git" },
}
