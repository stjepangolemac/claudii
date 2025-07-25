# Claudii

Docker-based development environments for Claude Code CLI. Creates isolated containers with automatic GitHub auth and repository setup.

## Quick Start

```bash
./install.sh                                    # Install claudii
cd /path/to/project && claudii env-add python   # Create environment  
claudii build python                            # Build image
claudii start python owner/repo feature-branch  # Start coding
```

## Architecture

**Host → Docker → Container**
- `claudii`: CLI extracts macOS keychain creds, manages Docker
- `entrypoint.sh`: Sets up container auth, clones repo, starts Claude
- `.claudii/`: Project-local environments (Dockerfiles, AI-generated docs)

```
project/.claudii/
├── Dockerfiles/<env>.Dockerfile  # Environment definition
└── environments/<env>.CLAUDE.md  # AI-generated environment docs
```

**CLAUDE.md Generation**: During `claudii build`, Claude AI analyzes the Dockerfile to generate comprehensive documentation:
- Pipes Dockerfile content to Claude: `cat Dockerfile | claude -p "instructions"`
- Claude extracts: tools/versions, environment variables, paths, configurations
- Generated markdown saved to `.claudii/environments/<env>.CLAUDE.md`
- Mounted read-only in container at `/home/developer/.claude/CLAUDE.md`
- Provides Claude with full context about the development environment

**Build Process**: Docker builds use global config directory as context (where entrypoint.sh lives), avoiding the need to copy files to each project. The Dockerfile is referenced by full path.

## Commands

- `claudii env-add <name>` - Create new environment
- `claudii build <env>` - Build Docker image  
- `claudii start <env> [repo] [branch]` - Start container
- `claudii list` - Show environments
- `claudii clean` - Remove containers
- `claudii uninstall` - Remove claudii

## Key Features

**Credential Flow**: macOS Keychain → Env Vars → Container → Config Files
- Claude: `security find-generic-password -s "Claude Code-credentials"`
- GitHub: `security find-generic-password -s "gh:github.com"`

**Container Setup**:
1. Ubuntu 24.04 + Node.js + GitHub CLI + Claude Code
2. `gh auth setup-git` configures git authentication
3. Background clone while Claude starts
4. Auto branch creation

## Customize Environments

Edit `.claudii/Dockerfiles/<name>.Dockerfile`:

```dockerfile
# ===== USER CUSTOMIZATION SECTION =====
RUN sudo apt-get update && sudo apt-get install -y python3 python3-pip
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
```

## Development

**Key Functions**:
- `init_claudii()`: Create `.claudii` directories in current dir
- `get_github_token()`: Extract from keychain, decode base64
- `build_image()`: Docker build + AI-generate CLAUDE.md via Claude
- `start_container()`: Run with credentials

**Entrypoint Flow**:
1. Write credentials to config files
2. `gh auth setup-git` 
3. Clone repo to temp dir, move to workspace
4. `exec claude --dangerously-skip-permissions`

**Debug Container**:
```bash
docker run -it --rm \
  -e "GH_HOSTS_CONTENT=$GH_HOSTS_CONTENT" \
  --entrypoint /bin/bash \
  claudii-env:latest
```

## Troubleshooting

**Git auth fails**: Check `gh auth status` on host
**Node.js errors**: Ensure NodeSource install (not Ubuntu repos)
**Path errors**: Use `/home/developer/workspace/repo`