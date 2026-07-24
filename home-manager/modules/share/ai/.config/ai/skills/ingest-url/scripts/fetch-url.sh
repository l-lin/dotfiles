#!/usr/bin/env bash
#
# fetch-url.sh - Fetch web content using defuddle, extract assets, output markdown with frontmatter
#
# Usage: ./fetch-url.sh <url> <output-dir> <slug>
#
# Outputs:
#   <output-dir>/<slug>.md        - Markdown with frontmatter
#   raw/assets/<slug>-*           - Downloaded images
#
# Example:
#   ./fetch-url.sh https://example.com/article raw/specs my-article
#

set -euo pipefail

URL="${1:?Usage: fetch-url.sh <url> <output-dir> <slug>}"
OUTPUT_DIR="${2:?Usage: fetch-url.sh <url> <output-dir> <slug>}"
SLUG="${3:?Usage: fetch-url.sh <url> <output-dir> <slug>}"

ASSETS_DIR="raw/assets"
TODAY=$(date +%Y-%m-%d)

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$ASSETS_DIR"

# Fetch JSON metadata
echo "Fetching metadata from $URL..." >&2
METADATA=$(npx defuddle parse "$URL" --json 2>/dev/null)

# Extract fields from JSON
TITLE=$(echo "$METADATA" | jq -r '.title // "Untitled"' | tr -d '\n')
AUTHOR=$(echo "$METADATA" | jq -r '.author // ""')
PUBLISHED=$(echo "$METADATA" | jq -r '.published // ""')
DESCRIPTION=$(echo "$METADATA" | jq -r '.description // ""')
LANGUAGE=$(echo "$METADATA" | jq -r '.language // "en"')
WORD_COUNT=$(echo "$METADATA" | jq -r '.wordCount // 0')
CONTENT_MD=$(echo "$METADATA" | jq -r '.contentMarkdown // ""')

# If contentMarkdown is empty, fall back to --markdown
if [[ -z "$CONTENT_MD" ]]; then
    echo "Falling back to --markdown output..." >&2
    CONTENT_MD=$(npx defuddle parse "$URL" --markdown 2>/dev/null)
fi

# Extract image URLs from markdown using perl for better regex support
# Matches: ![alt](url) patterns
IMAGE_URLS=$(echo "$CONTENT_MD" | perl -nle 'print $1 while /!\[[^\]]*\]\(([^)]+)\)/g' | sort -u || true)

# Download images and track replacements
IMAGE_COUNT=0
PROCESSED_CONTENT="$CONTENT_MD"

if [[ -n "$IMAGE_URLS" ]]; then
    echo "Found images to download..." >&2
    while IFS= read -r img_url; do
        [[ -z "$img_url" ]] && continue

        # Skip data URIs
        [[ "$img_url" == data:* ]] && continue

        # Skip tiny icon images (external.png etc)
        [[ "$img_url" == *"/external.png" ]] && continue

        ORIGINAL_URL="$img_url"

        # Make relative URLs absolute
        if [[ "$img_url" != http* ]]; then
            # Extract base URL
            BASE_URL=$(echo "$URL" | sed -E 's|(https?://[^/]+).*|\1|')
            if [[ "$img_url" == /* ]]; then
                img_url="${BASE_URL}${img_url}"
            else
                # Relative to current path
                DIR_URL=$(echo "$URL" | sed -E 's|/[^/]*$|/|')
                img_url="${DIR_URL}${img_url}"
            fi
        fi

        # Generate local filename from original URL
        BASENAME=$(basename "$img_url" | sed 's/\?.*//')  # Remove query params
        EXT="${BASENAME##*.}"
        NAME="${BASENAME%.*}"
        [[ -z "$EXT" || "$EXT" == "$BASENAME" ]] && EXT="png"

        LOCAL_NAME="${SLUG}-${NAME}.${EXT}"
        LOCAL_PATH="${ASSETS_DIR}/${LOCAL_NAME}"

        # Download image
        echo "  Downloading: $img_url" >&2
        if curl -sL --max-time 10 -o "$LOCAL_PATH" "$img_url" 2>/dev/null; then
            # Verify it's actually a file with content
            if [[ -s "$LOCAL_PATH" ]]; then
                # Replace URL in content
                RELATIVE_PATH="../assets/${LOCAL_NAME}"
                PROCESSED_CONTENT=$(echo "$PROCESSED_CONTENT" | sed "s|($ORIGINAL_URL)|($RELATIVE_PATH)|g")
                ((IMAGE_COUNT++)) || true
                echo "    Saved: $LOCAL_NAME" >&2
            else
                rm -f "$LOCAL_PATH"
                echo "    Skipped (empty)" >&2
            fi
        else
            echo "    Failed to download" >&2
        fi
    done <<< "$IMAGE_URLS"
fi

# Build frontmatter
OUTPUT_FILE="${OUTPUT_DIR}/${SLUG}.md"

cat > "$OUTPUT_FILE" << FRONTMATTER
---
source_url: $URL
fetched: $TODAY
title: "$TITLE"
FRONTMATTER

[[ -n "$AUTHOR" ]] && echo "author: \"$AUTHOR\"" >> "$OUTPUT_FILE"
[[ -n "$PUBLISHED" ]] && echo "published: \"$PUBLISHED\"" >> "$OUTPUT_FILE"
[[ -n "$DESCRIPTION" ]] && echo "description: \"$DESCRIPTION\"" >> "$OUTPUT_FILE"
[[ -n "$LANGUAGE" ]] && echo "language: $LANGUAGE" >> "$OUTPUT_FILE"
[[ "$WORD_COUNT" -gt 0 ]] && echo "word_count: $WORD_COUNT" >> "$OUTPUT_FILE"
[[ "$IMAGE_COUNT" -gt 0 ]] && echo "assets_downloaded: $IMAGE_COUNT" >> "$OUTPUT_FILE"

echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "$PROCESSED_CONTENT" >> "$OUTPUT_FILE"

# Output summary as JSON for the skill to parse
cat << EOF
{
  "output_file": "$OUTPUT_FILE",
  "title": $(echo "$TITLE" | jq -Rs .),
  "assets_downloaded": $IMAGE_COUNT,
  "word_count": $WORD_COUNT,
  "slug": "$SLUG"
}
EOF
