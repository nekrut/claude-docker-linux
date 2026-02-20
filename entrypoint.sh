#!/bin/bash
set -e

# Fix SSH key permissions (bind-mounted as ro, may have wrong perms)
if [ -d "$HOME/.ssh" ]; then
    mkdir -p /tmp/.ssh
    cp "$HOME/.ssh/"* /tmp/.ssh/ 2>/dev/null || true
    chmod 700 /tmp/.ssh
    chmod 600 /tmp/.ssh/* 2>/dev/null || true
    chmod 644 /tmp/.ssh/*.pub 2>/dev/null || true
    export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no -i /tmp/.ssh/id_ed25519 -i /tmp/.ssh/id_rsa 2>/dev/null"
fi

# Update galaxy-mcp (pull latest)
echo "Updating galaxy-mcp..."
uvx --from galaxy-mcp galaxy-mcp --help >/dev/null 2>&1 || true

# Update galaxy-skills
SKILLS_DIR="$HOME/.claude/skills/galaxy"
if [ -d "$SKILLS_DIR/.git" ]; then
    echo "Updating galaxy-skills..."
    git -C "$SKILLS_DIR" pull --ff-only 2>/dev/null || true
fi

# Register Galaxy MCP server if not already configured
if ! claude mcp list 2>/dev/null | grep -q "galaxy"; then
    echo "Registering Galaxy MCP server..."
    claude mcp add galaxy -- uvx galaxy-mcp 2>/dev/null || true
fi

exec claude --dangerously-skip-permissions "$@"
