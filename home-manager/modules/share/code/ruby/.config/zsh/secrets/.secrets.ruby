export GEM_HOST_API_KEY="$(sops -d --extract "['rubygems-key']" ~/.config/dotfiles/secrets/sops/api-keys.yaml)"

# vim: ft=zsh
