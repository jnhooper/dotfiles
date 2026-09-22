eval "$(/opt/homebrew/bin/brew shellenv)"

# Login shells only. Non-interactive shells (editors, CI, Claude Code) never run
# .zshrc, so they never get the full `mise activate`; the shims keep the managed
# tools reachable there. .zshrc's activation supersedes this in interactive
# shells, which is the combination mise documents.
eval "$($HOME/.local/bin/mise activate zsh --shims)"
