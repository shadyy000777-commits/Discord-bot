#!/bin/bash
# Push changes to the correct GitHub repo based on type:
#   bash push_to_github.sh "commit message" bot      → Discord-bot repo
#   bash push_to_github.sh "commit message" website  → INDEX repo
#
# Bot files:     main.py, config.py, requirements.txt, push_to_github.sh, replit.md
# Website files: railway_server.py, Procfile, railway.json, nixpacks.toml,
#                runtime.txt, requirements-web.txt, website/index.html, website/static/
#
# NOTE: root-level tiers_data.json, index.html, static/ and skins/ are live-synced
# by the running bot via the GitHub Contents API — never push those here.

set -e

COMMIT_MSG="${1:-Update from Replit}"
TYPE="${2:-}"

BASE_DIR="$(pwd)"
TOKEN="${GITHUB_TOKEN}"
OWNER="shadyy000777-commits"

BOT_REPO="Discord-bot"
BOT_FILES="main.py config.py requirements.txt push_to_github.sh replit.md"

WEBSITE_REPO="INDEX"
WEBSITE_FILES="railway_server.py Procfile railway.json nixpacks.toml runtime.txt requirements-web.txt website"

# Auto-detect type if not provided
if [ -z "$TYPE" ]; then
    echo "ℹ️  No type specified — attempting to auto-detect from modified files..."
    CHANGED=$(git status --porcelain | awk '{print $2}')
    BOT_CHANGED=false
    WEB_CHANGED=false
    for f in $CHANGED; do
        case "$f" in
            main.py|config.py|requirements.txt|push_to_github.sh|replit.md) BOT_CHANGED=true ;;
            railway_server.py|Procfile|railway.json|nixpacks.toml|runtime.txt|requirements-web.txt|website/*) WEB_CHANGED=true ;;
        esac
    done
    if $BOT_CHANGED && $WEB_CHANGED; then
        echo "⚠️  Both bot and website files changed. Please specify type explicitly:"
        echo "    bash push_to_github.sh \"$COMMIT_MSG\" bot"
        echo "    bash push_to_github.sh \"$COMMIT_MSG\" website"
        exit 1
    elif $BOT_CHANGED; then
        TYPE="bot"
        echo "   Detected: bot changes"
    elif $WEB_CHANGED; then
        TYPE="website"
        echo "   Detected: website changes"
    else
        echo "ℹ️  No tracked file changes detected. Nothing to push."
        exit 0
    fi
fi

push_to_repo() {
    local REPO="$1"
    local FILES="$2"

    echo ""
    echo "▶ Pushing to $OWNER/$REPO ..."

    TMP_DIR=$(mktemp -d)
    trap "rm -rf $TMP_DIR" EXIT

    # Clone the target repo
    git clone --depth=1 "https://x-access-token:${TOKEN}@github.com/${OWNER}/${REPO}.git" "$TMP_DIR" 2>&1

    # Copy relevant files into the clone
    for item in $FILES; do
        if [ -e "$BASE_DIR/$item" ]; then
            # Preserve directory structure
            dest="$TMP_DIR/$item"
            mkdir -p "$(dirname "$dest")"
            if [ -d "$BASE_DIR/$item" ]; then
                cp -r "$BASE_DIR/$item/." "$dest/"
            else
                cp "$BASE_DIR/$item" "$dest"
            fi
        else
            echo "  ⚠️  Skipping missing file: $item"
        fi
    done

    cd "$TMP_DIR"
    git config user.email "aftershock@replit.com"
    git config user.name "Aftershock Bot"

    git add -A
    if ! git diff --cached --quiet; then
        git commit -m "$COMMIT_MSG"
        git push origin main
        echo "✅ Pushed to $OWNER/$REPO"
    else
        echo "ℹ️  Nothing new to commit in $OWNER/$REPO."
    fi

    cd "$BASE_DIR"
    rm -rf "$TMP_DIR"
    trap - EXIT
}

case "$TYPE" in
    bot)
        push_to_repo "$BOT_REPO" "$BOT_FILES"
        ;;
    website)
        push_to_repo "$WEBSITE_REPO" "$WEBSITE_FILES"
        ;;
    *)
        echo "❌ Unknown type: '$TYPE'. Use 'bot' or 'website'."
        exit 1
        ;;
esac
