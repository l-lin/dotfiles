# Configuration for https://github.com/notwaldorf/tiny-care-terminal

# List of folders to look into for `git` commits, comma separated.
export TTC_REPOS='/home/llin/work,/home/llin/perso'

# The max directory-depth to look for git repositories in
# the directories defined with `TTC_REPOS`. Note that the deeper
# the directory depth, the slower the results will be fetched.
export TTC_REPOS_DEPTH=2

# Location/zip code to check the weather for. Both 90210 and "San Francisco, CA"
# # _should_ be ok (the zip code doesn't always work -- use a location
# # first, if you can). It's using weather.service.msn.com behind the curtains.
export TTC_WEATHER='Paris'

# Set to false if you're an imperial lover <3
export TTC_CELSIUS=true

# Refresh the dashboard every 20 minutes.
export TTC_UPDATE_INTERVAL=20

# Turn off terminal title
export TTC_TERMINAL_TITLE=false

# Default pomodoro is 20 minutes and default break is 5 minutes.
export TTC_POMODORO=25
export TTC_BREAK=5

# Twitter api keys
# List of accounts to read the last tweet from, comma separated
# The first in the list is read by the party parrot.
export TTC_BOTS='tinycarebot,iamdevloper,webAgencyFAIL'

# Unset this if you _don't_ want to use Twitter keys and want to
# use web scraping instead.
export TTC_APIKEYS=false

