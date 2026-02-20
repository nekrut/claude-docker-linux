# Claude Docker Linux

Run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) in an isolated Docker container on Linux. Only `~/git` is visible to the container. Auth via bind-mounted `~/.claude` (OAuth from `claude login`, no API key needed).

Based on [nekrut/claude-code-docker](https://github.com/nekrut/claude-code-docker), adapted for Linux.

## Prerequisites

- Docker CE + docker-compose-plugin
- `claude login` completed on host (creates `~/.claude/.credentials.json`)
- GitHub CLI authenticated (`gh auth login`)

## Quick start

```bash
# Set Galaxy credentials (optional)
export GALAXY_URL=https://...
export GALAXY_API_KEY=sk-...

# Run
./run.sh
```

This will:
1. Write `.env` from environment variables
2. Clone galaxy-skills if not present
3. Open Sublime Text on `~/git`
4. Launch interactive Claude session in Docker

## One-shot mode

```bash
./run.sh -p "explain this codebase"
```

## What's in the container

- **Base**: node:20-bookworm
- **Tools**: git, python3, gh, jq, curl, wget
- **Python**: uv, Miniconda3
- **AI**: claude-code (latest), galaxy-mcp (via uvx)

## Volumes

| Host | Container | Mode |
|------|-----------|------|
| `~/git` | `/workspace` | rw |
| `~/.claude` | `/home/node/.claude` | rw |
| `~/.gitconfig` | `/home/node/.gitconfig` | ro |
| `~/.config/gh` | `/home/node/.config/gh` | ro |
| `~/.ssh` | `/home/node/.ssh` | ro |

## Galaxy integration

- **galaxy-mcp**: Pre-cached in image, updated on each container start, registered as MCP server
- **galaxy-skills**: Cloned to `~/.claude/skills/galaxy` on host, `git pull` on each start

## Manual build

```bash
docker compose build
docker compose run --rm claude
```
