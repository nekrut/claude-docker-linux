#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Write .env file from environment
cat > "$SCRIPT_DIR/.env" <<EOF
GALAXY_URL=${GALAXY_URL:-}
GALAXY_API_KEY=${GALAXY_API_KEY:-}
EOF

# Ensure galaxy-skills cloned on host (persists via bind mount)
SKILLS_DIR="$HOME/.claude/skills/galaxy"
if [ ! -d "$SKILLS_DIR" ]; then
    echo "Cloning galaxy-skills..."
    mkdir -p "$HOME/.claude/skills"
    git clone https://github.com/anthropics/galaxy-skills.git "$SKILLS_DIR" 2>/dev/null || echo "Warning: could not clone galaxy-skills"
fi

# Open editor
subl --add ~/git 2>/dev/null || true

# Run claude container
cd "$SCRIPT_DIR"
docker compose run --rm claude "$@"
