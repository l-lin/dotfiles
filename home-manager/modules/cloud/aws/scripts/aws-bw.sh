#!/usr/bin/env bash
# Script to source AWS credentials from Bitwarden using bw-cli.
# src: https://github.com/tdharris/aws-bitwarden-profile/tree/main

# Custom Field Names from Bitwarden
DEFAULT_FIELD_AWS_ACCESS_KEY="AWS_ACCESS_KEY_ID"
DEFAULT_FIELD_AWS_SECRET_KEY="AWS_SECRET_ACCESS_KEY"

sflag=false

# Validate both bitwarden (bw) & jq
command -v jq >/dev/null 2>&1 || { echo >&2 "jq could not be found."; exit 1; }
command -v bw >/dev/null 2>&1 || { echo >&2 "bw could not be found."; exit 1; }

# Parse BW_ITEM as bitwarden item name
while getopts "s:" opt; do
	case $opt in
		s ) BW_ITEM=$OPTARG; sflag=true;;
		\? ) echo 'Invalid argument, or argument value!'
             exit 1;;
	esac
done

shift $(($OPTIND - 1))

if ! $sflag; then echo -e "-s <keyword> is missing.\n\nPlease define the search term for the bitwarden item. E.g.\n\n> aws-bw -s <searchName>\n" && exit 1; fi

# Validate Bitwarden is authenticated & unlocked
# Note: AWS CLI is not allowing user prompt to passthrough
# Is Bitwarden Authenticated?
if [ -z "$BW_SESSION" ]; then
    (>&2 echo -e "Missing BW_SESSION from Environment Variables.\n\nPlease set by:\n\n> bw unlock")
    exit 1;
fi

# Check if unlocked
if [ "$(bw status | jq '.status')" != \"unlocked\" ]; then
    (>&2 echo "bitwarden vault is locked, please unlock with: \n\n> bw unlock")
    exit 1
fi

# Fetch Bitwarden Item
BW_ITEM_RESULTS=$(bw get item "$BW_ITEM")
if [ $? -ne 0 ]; then echo "Issue with Bitwarden CLI: bw get item \"$BW_ITEM\"" && exit 1; fi

# Parse AWS Credentials with Custom Field Names
AWS_ACCESS_KEY_ID=$(echo "$BW_ITEM_RESULTS" | jq -r ".fields[] | select(.name == \"$DEFAULT_FIELD_AWS_ACCESS_KEY\").value")
AWS_SECRET_KEY=$(echo "$BW_ITEM_RESULTS" | jq -r ".fields[] | select(.name == \"$DEFAULT_FIELD_AWS_SECRET_KEY\").value")

# Validate exists
[ -z "$AWS_ACCESS_KEY_ID" ] && echo "Failed to parse AWS_ACCESS_KEY_ID: $DEFAULT_FIELD_AWS_ACCESS_KEY" && exit 1;
[ -z "$AWS_SECRET_KEY" ] && echo "Failed to parse AWS_SECRET_KEY: $DEFAULT_FIELD_AWS_SECRET_KEY" && exit 1;

# See AWS docs for Sourcing credentials with an external process
# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sourcing-external.html
echo "{\"Version\": 1, \"AccessKeyId\": \"$AWS_ACCESS_KEY_ID\", \"SecretAccessKey\": \"$AWS_SECRET_KEY\"}"
