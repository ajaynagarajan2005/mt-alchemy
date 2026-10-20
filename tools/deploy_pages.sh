#!/usr/bin/env bash
# Builds the web app for GitHub Pages and publishes it to the gh-pages branch.
# Usage: bash tools/deploy_pages.sh   (from the repo root, after committing)
set -euo pipefail
export MSYS_NO_PATHCONV=1   # Git Bash must not turn /mt-alchemy/ into a Windows path

REPO="${REPO:-mt-alchemy}"
BASE="/${REPO}/"
REMOTE="$(git remote get-url origin)"

# The assistant service runs on a host you provide; leave RAG_URL unset to publish without it.
flutter build web --release --base-href "$BASE" --dart-define=SITE_BASE="$BASE" --dart-define=RAG_URL="${RAG_URL:-}"

# GitHub Pages has no server-side routing: a copy of index.html as 404.html
# lets deep links such as /mt-alchemy/portal load the app, which then routes.
cp build/web/index.html build/web/404.html
touch build/web/.nojekyll

cd build/web
rm -rf .git
git init -q -b gh-pages
git add -A
git -c user.name="$(git config user.name || echo deploy)" \
    -c user.email="$(git config user.email || echo deploy@example.com)" \
    commit -q -m "Deploy $(date -u +%Y-%m-%dT%H:%M:%SZ)"
git push -f "$REMOTE" gh-pages
rm -rf .git
echo "Published: https://$(echo "$REMOTE" | sed -E 's#.*github.com[:/]([^/]+)/.*#\1#').github.io/${REPO}/"
