#!/bin/sh
# Publish a Playwright HTML report (single-file index.html) to a permanent deed.page URL.
# Usage: ./publish-playwright-report.sh playwright-report/index.html my-app-e2e-7k2p
set -eu
FILE=${1:?path to playwright-report/index.html}; SLUG=${2:?slug, e.g. my-app-e2e-7k2p}
DIR=$(dirname "$FILE")
if [ -d "$DIR/data" ] && [ -n "$(ls -A "$DIR/data" 2>/dev/null)" ]; then
  echo "This report has attachments in $DIR/data (screenshots, traces). Upload the whole folder with the manifest flow in https://deed.page/docs instead."; exit 1
fi
printf 'Publish %s to https://%s.deed.page/ ? Anyone with the link can open it. [y/N] ' "$FILE" "$SLUG"
read -r ans; [ "$ans" = "y" ] || { echo "Not published."; exit 0; }
DEEDPAGE_TOKEN=${DEEDPAGE_TOKEN:-$(cat ~/.config/deed-page/token 2>/dev/null || true)}
set --; if [ -n "$DEEDPAGE_TOKEN" ]; then set -- -H "Authorization: Bearer $DEEDPAGE_TOKEN"; fi
RESP=$(curl -sS -T "$FILE" -H "Content-Type: text/html" "https://deed.page/v1/sites?slug=$SLUG" -H "X-Client: playwright-report-script" "$@")
TOKEN=$(printf '%s' "$RESP" | sed -n 's/.*"token": *"\(deed_tok_[^"]*\)".*/\1/p')
if [ -n "$TOKEN" ]; then (umask 077 && mkdir -p ~/.config/deed-page && chmod 700 ~/.config/deed-page && printf '%s' "$TOKEN" > ~/.config/deed-page/token && chmod 600 ~/.config/deed-page/token); fi
printf '%s\n' "$RESP" | sed 's/"token": *"[^"]*"/"token":"<saved>"/'
