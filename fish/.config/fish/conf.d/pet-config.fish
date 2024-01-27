# Command line snippet manager: https://github.com/knqyf263/pet
function configure_pet
  bind -s -M insert \cs '_pet_select'
end

function _pet_select
  set -l query (commandline)
  pet search --query "$query" $argv | read cmd
  commandline $cmd
end

